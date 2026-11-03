# CONTEXT — api-skeleton

Detailed map of the skeleton: how a request travels locally and on AWS, which file holds what, which
rules the template enforces, and how the tests are wired. Working rules live in `AGENTS.md`; the human
entry point is `README.md`.

---

## 1. Position in the workspace

| Item | Value |
|---|---|
| Git repository | `persval96/api-skeleton` (independent repository, nested in `main-workspace`) |
| Role | Template for every API project — `user-api` and `zinguoinguoin-club-api` are clones of it |
| AWS account | `646424554834`, region `eu-west-3` |
| Consumption | Cloned, then renamed (`api_name`, domains, state key, ECR repository) |

A change here is a template change: it is meant to be copied into the projects built from it.

---

## 2. Local request pipeline

```
config/local/docker-compose.yaml
  nginx  646424554834.dkr.ecr.eu-west-3.amazonaws.com/nginx:latest   :80
    volumes: ./nginx.conf → /etc/nginx/conf.d/default.conf, ../.. → /var/www/html
    links:   php
  php    646424554834.dkr.ecr.eu-west-3.amazonaws.com/php85:latest
    container_name: php, /var/www/html mounted, ~/.composer, local .gitconfig
```

`config/local/nginx.conf` routes each endpoint explicitly — there is **no catch-all rewrite**, a new
endpoint means a new `location` block:

```nginx
location /hello-world {
    try_files $uri $uri/ /endpoints/hello-world/public/index.php?$query_string;
}
location ^~ /endpoints/hello-world/public/index.php {
    fastcgi_pass php:9000;   # fastcgi_params + SCRIPT_FILENAME
}
```

The Laravel application itself boots from
`endpoints/hello-world/bootstrap/app.php`:

- `withRouting(api: routes/api.php, apiPrefix: '')` — **no global prefix**, so the path written in
  `routes/api.php` is the full public path;
- `withSingletons([ExceptionHandler::class => Handler::class])`;
- `shouldRenderJsonWhen(fn () => true)` — every error is rendered as JSON, even outside an API request.

---

## 3. AWS request pipeline

```
Route 53 (zone *.dev.appkweb.com) ──A──► API Gateway HTTP v2 custom domain (ACM, TLS 1.2)
    └── route keys of the endpoint module ──► Lambda <api-name>-<endpoint>-<env>
                                                 handler public/index.php
                                                 Bref\LaravelBridge\Http\OctaneHandler
                                                 runtime provided.al2023, arm64, memory 1024
                                                    └──► DynamoDB <api-name>-api
```

| Concern | Where | Detail |
|---|---|---|
| Domains | `config/web/locals.tf` | `full_domain = <prefix_domain[env]>.<base_domain[env]>` → `api-skeleton.dev.appkweb.com`, `api-skeleton.sandbox.appkweb.com`, `api.client-domain.com` |
| API name | `config/web/locals.tf` | `api_name = "api-skeleton"` |
| Lambda sizing | `config/web/locals.tf` | `layer_arn …:layer:arm-php-85:12`, `architecture arm64`, `handler Bref\LaravelBridge\Http\OctaneHandler`, `bref_loop_max 250`, `memory_size 1024` |
| State | `config/web/main.tf` | backend S3 `persval96-dev-terraform-tfstate-eu-west-3`, key `api-skeleton.tfstate`, encrypted |
| Domain + DNS | `config/web/apigateway.tf`, `route53.tf`, `data.tf` | ACM wildcard lookup, A-record alias |
| Table | `config/web/dynamodb.tf` | `<api-name>-api`, PROVISIONED 5/5, `PK`/`SK`, 5 LSIs (`LSI{N}PK`, projection ALL), TTL `expireAt` |
| Per-endpoint wiring | `config/web/endpoints/<endpoint>/` | Lambda, routes, IAM, zip, variables |
| Registration | `config/web/module.tf` | one `module` block per endpoint, fed with `local.lambda_config`, `local.api_name`, `var.env`, table name, domain name |

### The per-endpoint module

| File | Responsibility |
|---|---|
| `locals.tf` | `endpoint_name = "hello-world"` — used for the route keys, the function name, the zip name and the log group |
| `data.tf` | `archive_file` zipping `../../endpoints/<endpoint>` (excludes `phpunit.xml`, `phpstan.neon`, `.env`, `.env.example`, `README.md`, `tests`, `*.zip`, `.idea`, `storage`, `node_modules`, `.git`), caller identity, region, IAM policy document |
| `iam.tf` | Lambda role and the policy built from `data.aws_iam_policy_document.api` |
| `lambda.tf` | `aws_lambda_function` (timeout 30, `provided.al2023`, Bref layer, `/tmp` storage), CloudWatch log group (7 days), `aws_lambda_permission` for API Gateway |
| `apigateway.tf` | Integration on the endpoint Lambda + route keys |
| `variable.tf` | `api_name`, `env`, `lambda_config`, `dynamodb_table_name`, `domain_name` |

Route keys created for every endpoint:

| Route key |
|---|
| `GET /<endpoint>` |
| `POST /<endpoint>` |
| `PUT /<endpoint>` |
| `DELETE /<endpoint>` |
| `GET /<endpoint>/{id}` |
| `OPTIONS /<endpoint>` (preflight) |

IAM granted to the endpoint: `dynamodb:GetItem|Query|PutItem|DeleteItem` on the table and
`logs:CreateLogGroup|CreateLogStream|PutLogEvents|DescribeLogStreams|DescribeLogGroups` on its log group.

---

## 4. The example endpoint, file by file

`endpoints/hello-world/` is a **standalone Laravel 13 application** with its own dependency set
(`bref/bref`, `bref/laravel-bridge`, `laravel/framework`, `laravel/octane`, plus `larastan/larastan`,
`laravel/pint`, `phpunit/phpunit` in dev). It is not a Laravel package inside the root project: it owns
its `composer.json`, its `composer.lock` and its `vendor/`.

| File | Responsibility |
|---|---|
| `composer.json` | Namespace `HelloWorld\App\` → `app/`, `HelloWorld\Tests\` → `tests/`, `post-autoload-dump` runs `artisan package:discover` |
| `bootstrap/app.php` | Application wiring (routing without prefix, JSON errors, `api` middleware group, exception handler singleton) |
| `bootstrap/providers.php` | `HelloWorld\App\Providers\AppServiceProvider` |
| `public/index.php` | Front controller — the Lambda handler (`handler = "public/index.php"`) |
| `routes/api.php` | `GET /hello-world` → `HelloWorldController::handle`, `GET /hello-world/debug` → closure returning `worker_id` + `memory` |
| `app/Http/Controllers/HelloWorldController.php` | `handle(): JsonResponse` returning `new JsonResponse('Hello World!')` — the body is the JSON string `"Hello World!"` |
| `app/Providers/AppServiceProvider.php` | Plain Laravel provider (no binding) |
| `config/app.php` | Application config of the endpoint |
| `.env.example` | Local defaults (`APP_NAME`, `APP_ENV=local`, `APP_KEY`, `APP_DEBUG`, `APP_URL`, `LOG_CHANNEL`, `LOG_LEVEL`) |
| `phpstan.neon` | Includes `vendor/larastan/larastan/extension.neon`, level max on `app` and `tests` |
| `phpunit.xml` | Suite `./tests`, coverage source `./app` |
| `tests/HelloWorldTest.php` | `GET /hello-world` → 200, `Content-Type: application/json`, `assertExactJson(['Hello World!'])` |

`GET /hello-world/debug` is a **liveness probe for Octane**: `getmypid()` stays identical across
requests as long as the worker survives, `memory_get_usage(true)` shows the worker footprint.

---

## 5. Root files

| Path | Responsibility |
|---|---|
| `Makefile` | Every entry point; `projects = ls -d endpoints/*/` drives all loops; `TF_CMD` wraps `docker run … terraform:latest terraform -chdir=config/web` |
| `composer.json` (root) | Manifest autoloading the example endpoint (`App\` → `endpoints/hello-world/app`) — kept for the root tooling, each endpoint remains its own Composer project |
| `config/local/docker-compose.yaml` | `nginx` + `php` services (ECR images) |
| `config/local/nginx.conf` | One `location` block per endpoint |
| `config/local/.gitconfig` | Identity mounted into the containers |
| `config/web/environments/{dev,sbx,prod}.tfvars` | `env = "dev" \| "sbx" \| "prod"` |
| `.github/workflows/ci.yml` | PR pipeline: OIDC → ECR login → `composer-install`, `analyze`, `pint-check`, `test-coverage` |

---

## 6. Environment variables

On Lambda (`config/web/endpoints/<endpoint>/lambda.tf`):

| Variable | Value |
|---|---|
| `APP_ENV` | `var.env` |
| `APP_DEBUG` | `false` in `prod`, `true` otherwise |
| `APP_STORAGE` | `/tmp` (Lambda only writable directory) |
| `LOG_CHANNEL` | `stderr` |
| `LOG_LEVEL` | `warning` in `prod`, `debug` otherwise |
| `BREF_LOOP_MAX` | `local.lambda_config.bref_loop_max` (250) |
| `BREF_HANDLER` | `local.lambda_config.handler` (`Bref\LaravelBridge\Http\OctaneHandler`) |
| `BREF_RUNTIME` | `fpm` |

Locally, `endpoints/hello-world/.env.example` provides `APP_NAME`, `APP_ENV=local`, `APP_KEY`,
`APP_DEBUG`, `APP_URL`, `LOG_CHANNEL`, `LOG_LEVEL`. AWS credentials are needed by the tooling, not by the
example endpoint: `AWS_PROFILE` (default `dev`) is passed to the Terraform container, and the CI uses an
OIDC role.

---

## 7. Tests & quality

| Command | What it really runs |
|---|---|
| `make test-coverage` | `php vendor/bin/phpunit --coverage-text` in every `endpoints/*`; `phpunit.xml` declares `./tests` as suite and `./app` as coverage source, so **100 % on `app`** |
| `make analyze` | `php vendor/bin/phpstan analyse app tests` with Larastan, level max |
| `make pint-check` / `make pint-fix` | `php vendor/bin/pint --test` / `--parallel` |
| `make composer-install-prod` | `--no-dev --optimize-autoloader`, the dependency shape of the Lambda zip |

There is **no Rector** in this repository: the API gate is `pint-check` + `analyze` + `test-coverage`.

Tests use `Illuminate\Foundation\Testing\TestCase` and the real application boot; a new route needs a
test asserting the status, the content type and the exact JSON body.

---

## 8. Common tasks

| Task | Steps |
|---|---|
| Add an endpoint | see `README.md` § *Adding an endpoint* (copy `endpoints/hello-world`, namespace, routes, Terraform module, nginx location, root `composer.json`) |
| Change the Lambda sizing | `config/web/locals.tf` → `lambda_config` |
| Add a table, a queue, a bucket | `config/web/*.tf` + pass it to the module in `config/web/module.tf` |
| Deploy | `make tf-plan env=dev`, `make tf-apply env=dev` (same with `env=sbx` / `env=prod`) |
| Reset a local environment | `make start` (or `make update-images` to re-pull the ECR images) |

