# api-skeleton

Template for the serverless PHP APIs of this workspace: **Laravel 13 + Octane on AWS Lambda**
(Bref 3), DynamoDB single table, API Gateway HTTP v2 and Terraform. It ships one working example
endpoint, `hello-world`, and every API project of the workspace (`user-api`,
`zinguoinguoin-club-api`) starts as a clone of this repository.

| Layer | Choice |
|---|---|
| Language | PHP 8.5 |
| Framework | Laravel 13 + Octane, `bref/laravel-bridge` |
| Runtime | AWS Lambda (`provided.al2023`, arm64, Bref layer `arm-php-85`) |
| API | API Gateway HTTP v2 + custom domain (Route 53, ACM) |
| Data | DynamoDB, single table `PK`/`SK`, five LSIs, TTL `expireAt` |
| Infrastructure | Terraform, backend S3, region `eu-west-3` |
| Local dev | Docker Compose (nginx + php85 images from ECR) |
| Quality | PHPUnit (100 % coverage), PHPStan/Larastan level max, Pint |

---

## Requirements

| Tool | Why |
|---|---|
| Docker + Docker Compose | nginx, PHP and every quality tool run **inside containers only** |
| GNU make | every entry point |
| AWS CLI, `dev` profile, region `eu-west-3` | pulls the ECR images (`php85`, `nginx`, `terraform`) |

---

## Quick start

```bash
git clone https://github.com/persval96/api-skeleton.git && cd api-skeleton

make docker-login       # once — the php85 / nginx images live in a private ECR registry
make start              # creates the api-skeleton network, starts nginx + php
make composer-install   # installs the dependencies of every endpoint

curl http://localhost/hello-world
# "Hello World!"            (JSON string, Content-Type: application/json)

curl http://localhost/hello-world/debug
# {"worker_id":123,"memory":2097152}
# worker_id stays stable across requests: Octane keeps the worker alive

make test-coverage      # PHPUnit with the 100 % coverage gate
```

> `make docker-login` is required once before `make start` when the ECR images are not pulled yet.
> **Nothing runs on the host**: `make` targets wrap
> `docker compose -f config/local/docker-compose.yaml run --rm php`, and Terraform runs in the
> `terraform` ECR image.

---

## Commands

`make help` is the source of truth. `env` (`dev` | `sbx` | `prod`) and `profile` (AWS profile used by
Terraform) are Make variables, both defaulting to `dev`.

### Containers

| Command | Description |
|---|---|
| `make start` | Remove the containers, then start them again |
| `make up` | Create the `api-skeleton` network and start the containers |
| `make logs` | Follow the `php` container logs |
| `make clear-containers` | Stop and remove the containers |
| `make update-images` | Re-pull the ECR images |
| `make docker-login` | Authenticate Docker against the ECR registry |

### Setup

| Command | Description |
|---|---|
| `make composer-install` | `composer install` in every `endpoints/*` |
| `make composer-update` | `composer update` in every `endpoints/*` |
| `make composer-install-prod` | `--no-dev --optimize-autoloader`, the shape deployed to Lambda |
| `make php-console` | Shell in a throw-away `php` container |

### Quality

| Command | Description |
|---|---|
| `make test-coverage` | PHPUnit with `--coverage-text` (must stay at 100 %) |
| `make analyze` | PHPStan (Larastan) level max on `app` and `tests` |
| `make pint-check` | Pint in test mode |
| `make pint-fix` | Pint in fix mode |

### Deployment

```bash
make tf-init                  # terraform init -reconfigure
make tf-plan    env=dev       # preview
make tf-apply   env=dev       # deploy
make tf-destroy env=dev       # tear down
make tf-fix                   # terraform fmt -recursive
```

Terraform runs in the `terraform` ECR image with `AWS_PROFILE=$(profile)` and mounts
`~/.aws/config` and `~/.aws/credentials` read-only.

---

## Request pipeline

```
Local                              AWS (eu-west-3)
─────                              ───────────────
nginx  :80                         Route 53 ──► API Gateway HTTP v2 (custom domain, ACM, TLS 1.2)
  │ /hello-world                          │  GET|POST|PUT|DELETE|OPTIONS /hello-world
  ▼                                      │  GET /hello-world/{id}
php85 :9000  (php-fpm)                   ▼
  endpoints/hello-world/           Lambda <api-name>-hello-world-<env>
  public/index.php                   handler Bref\LaravelBridge\Http\OctaneHandler
    routes/api.php                   memory 1024, arm64, Bref layer, /tmp storage, stderr logs
      HelloWorldController                │
                                          ▼
                                     DynamoDB <api-name>-api (PK/SK + LSI1..5, TTL expireAt)
```

Each endpoint is an **independent Laravel application** (own `composer.json`, own
`public/index.php`) deployed as **its own Lambda with its own API Gateway routes**; the Terraform
module `config/web/endpoints/<endpoint>/` is what wires them together.

---

## Repository map

```
api-skeleton/
├── endpoints/
│   └── hello-world/            # one Laravel application per endpoint
│       ├── app/                # HelloWorld\App\ (controller, AppServiceProvider)
│       ├── bootstrap/app.php   # routing without prefix, JSON errors, api middleware group
│       ├── public/index.php    # Lambda / php-fpm front controller
│       ├── routes/api.php      # /hello-world and /hello-world/debug
│       ├── tests/              # PHPUnit, 100 % coverage
│       ├── phpstan.neon        # Larastan, level max
│       └── phpunit.xml
├── config/
│   ├── local/                  # docker-compose.yaml, nginx.conf, .gitconfig
│   └── web/                    # Terraform: API, DNS, DynamoDB + one module per endpoint
│       ├── endpoints/hello-world/   # lambda.tf, apigateway.tf, iam.tf, data.tf, locals.tf
│       ├── environments/            # dev.tfvars, sbx.tfvars, prod.tfvars
│       ├── apigateway.tf            # custom domain
│       ├── dynamodb.tf              # single table + 5 LSIs + TTL
│       ├── route53.tf               # A record alias to the custom domain
│       └── module.tf                # module "hello-world"
├── .github/workflows/ci.yml
├── Makefile
├── composer.json               # root manifest (autoload of the example endpoint)
├── AGENTS.md                   # working rules
└── CONTEXT.md                  # detailed map: pipeline, routes, files, env vars, tests
```

---

## Adding an endpoint

1. `cp -r endpoints/hello-world endpoints/<name>` and rename the namespaces
   (`HelloWorld\App\` → `<Name>\App\`, `HelloWorld\Tests\` → `<Name>\Tests\`) in `composer.json`,
   `bootstrap/providers.php`, `routes/api.php` and the tests.
2. Declare the routes in `endpoints/<name>/routes/api.php` — the API prefix is empty, the endpoint name
   is part of the path.
3. Add the Terraform module: `cp -r config/web/endpoints/hello-world config/web/endpoints/<name>`, set
   `locals.endpoint_name = "<name>"` in its `locals.tf`, then declare the module in
   `config/web/module.tf`.
4. Add the local nginx location in `config/local/nginx.conf`
   (`try_files $uri $uri/ /endpoints/<name>/public/index.php?$query_string`).
5. Register the namespace in the root `composer.json` (`autoload.psr-4`), then `make composer-install`
   and `make test-coverage`.

The routes of an endpoint module are fixed: `GET|POST|PUT|DELETE|OPTIONS /<endpoint>` and
`GET /<endpoint>/{id}`; another shape means editing `endpoints/<name>/apigateway.tf`.

---

## Starting a new API from this template

| File | What to change |
|---|---|
| `composer.json` (root) | package name, `autoload.psr-4` |
| `config/web/locals.tf` | `api_name`, `prefix_domain`, `base_domain`, `lambda_config` (memory, layer ARN) |
| `config/web/main.tf` | backend S3 `key` (state file name) |
| `config/web/endpoints/*/locals.tf` | `endpoint_name` |
| `config/web/module.tf` | one `module` block per endpoint |
| `config/local/docker-compose.yaml`, `config/local/nginx.conf` | locations |
| `Makefile` | `NETWORK_NAME` |
| `.github/workflows/ci.yml` | `ECR_REPOSITORY` |

---

## CI

`.github/workflows/ci.yml` runs on every pull request: AWS credentials through GitHub OIDC
(`arn:aws:iam::646424554834:role/github-ci`), ECR login, then `make composer-install`, `make analyze`,
`make pint-check` and `make test-coverage`. A red pipeline blocks the merge.

---

## Documentation

- `AGENTS.md` — working rules (gates, Docker, git/Jira, invariants, definition of done)
- `CONTEXT.md` — detailed map (pipeline, routes, file responsibilities, env vars, tests)
- `ai_memory_bank/` at the workspace root — steering shared by every project of the workspace

---

## License

Private — internal template of the workspace.

