# AGENTS — api-skeleton

Working rules for this repository. Read them **before** touching the code; the detailed map (local and
AWS pipelines, file-by-file responsibilities, routes, env vars, tests) lives in `CONTEXT.md`, the human
entry point in `README.md`.

---

## 1. What this repository is

Template of the serverless APIs of the workspace: **Laravel 13 + Octane on AWS Lambda** (Bref 3), one
Lambda + one API Gateway route set per endpoint, DynamoDB single table, Terraform. `user-api` and
`zinguoinguoin-club-api` are clones of it: a change here is a template change, and it must stay
copyable (`README.md` § *Starting a new API from this template*).

---

## 2. Docker only

- `php`, `composer`, `phpunit`, `pint`, `phpstan` and `terraform` **never run on the host**.
- Always through `make` (targets wrap
  `docker compose -f config/local/docker-compose.yaml run --rm php`, Terraform runs in the `terraform`
  ECR image).
- First run: `make docker-login`, then `make start`, then `make composer-install`.
- Never commit a `.env`, a `vendor/`, or a Terraform state.

---

## 3. Quality gates (mandatory before a merge request)

```bash
make pint-check     # Pint, test mode
make analyze        # PHPStan + Larastan, level max
make test-coverage  # PHPUnit, 100 % coverage required
```

- There is **no `full-check` target and no Rector** in this repository: those three commands are the gate.
- No Makefile target as `full-check` — don't invent one.
- 100 % coverage on `app/`: a new branch needs its test.
- PHPStan runs with `ignoreErrors: []`; fix the code instead of muting the rule.

---

## 4. Invariants of the template

- **One endpoint = one standalone Laravel application** in `endpoints/<name>/` with its own
  `composer.json`, `public/index.php` and namespace `<Name>\App\`. Endpoints never share code through the
  root project.
- `withRouting(..., apiPrefix: '')` — the API has **no global prefix**: the path declared in
  `routes/api.php` is the public path.
- Every error is rendered as JSON (`shouldRenderJsonWhen(fn () => true)`).
- Adding an endpoint requires **all five** of: the directory, the Terraform module in
  `config/web/endpoints/<name>/`, its declaration in `config/web/module.tf`, the local `location` block
  in `config/local/nginx.conf`, and the root `composer.json` autoload.
- Lambda naming: `<api_name>-<endpoint>-<env>`, log group `/aws/lambda/<same>`.
- DynamoDB stays a single table (`PK`/`SK`, `LSI1PK`…`LSI5PK`, indexes `LSI1`…`LSI5`, TTL `expireAt`) so
  the defaults of `persval96/database` keep working.
- The Lambda zip excludes `tests`, `.env*`, `phpunit.xml`, `phpstan.neon`, `README.md`, `storage`,
  `node_modules` (see `endpoints/<name>/data.tf`) — a new dev-only file belongs to that exclusion list.

---

## 5. Code conventions

- PHP 8.5, PSR-4, PSR-12 through Laravel Pint, strict types where the endpoint already declares them.
- Controllers return typed responses (`JsonResponse`); routes live in `routes/api.php` of the endpoint.
- A new dependency is added to the **endpoint** `composer.json`, never to the root one.
- Terraform: one resource per concern, variables passed through the module, everything parameterised by
  `var.env`.
- Comments and documentation in English.

---

## 6. Tests

- PHPUnit in every endpoint (`phpunit.xml`: suite `./tests`, coverage source `./app`).
- A route test asserts status, `Content-Type` and the exact JSON body.
- Laravel-aware tests only — no mocked framework internals; AWS access is never exercised in a test.
- 100 % coverage is a gate, not a goal.

---

## 7. Git & Jira

- Branch from `main`, named after the ticket: `dev/INT-xx`, `bug/INT-xx`, `feature/INT-xx`,
  `refactor/INT-xx`.
- Commit message: `INT-xx <ticket title>` (e.g. `INT-12 Add account register endpoint`).
- **One commit per branch** (except `main`): amend instead of stacking fix commits.
- `git status` and `git diff` before every commit; `vendor/` is never committed.
- Open the merge request when the implementation is done.
- Jira: transition the ticket to **“En cours”** when starting, never to **“Terminé”**.

---

## 8. Definition of done

- [ ] `make pint-check`, `make analyze`, `make test-coverage` pass (100 % coverage)
- [ ] New endpoint wired in all five places (directory, Terraform module, `module.tf`, nginx, autoload)
- [ ] `README.md` / `CONTEXT.md` updated when a route, a config key or a file changes
- [ ] Branch holds a single commit with the `INT-xx <title>` message
- [ ] No `vendor/`, no `.env`, no Terraform state committed
- [ ] Jira ticket in **“En cours”**
