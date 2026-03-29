<div align="center">

# ⚡ API Skeleton

**Production-ready serverless APIs — Laravel Octane on AWS Lambda.**

Clone it. Add your routes. Ship.

[![PHP](https://img.shields.io/badge/PHP-8.5-777BB4?style=flat-square&logo=php&logoColor=white)](https://php.net)
[![Laravel](https://img.shields.io/badge/Laravel-13-FF2D20?style=flat-square&logo=laravel&logoColor=white)](https://laravel.com)
[![Bref](https://img.shields.io/badge/Bref-3.1-F28D1A?style=flat-square&logo=amazonaws&logoColor=white)](https://bref.sh)
[![AWS Lambda](https://img.shields.io/badge/AWS_Lambda-FF9900?style=flat-square&logo=awslambda&logoColor=white)](https://aws.amazon.com/lambda)
[![Coverage](https://img.shields.io/badge/coverage-100%25-22c55e?style=flat-square)](#)
[![License](https://img.shields.io/badge/license-MIT-6366f1?style=flat-square)](#)

</div>

---

## 🚀 Quick Start

```bash
# 1. Clone
git clone https://github.com/your-org/api-skeleton.git && cd api-skeleton

# 2. Start local environment
make start

# 3. Test the example endpoint
curl http://localhost/hello-world
# → ["Hello World!"]

curl http://localhost/hello-world/debug
# → { "worker_id": 77, "memory": 1048576 }
# worker_id stays stable across requests — Octane persistence confirmed ✓

# 4. Run the test suite
make test-coverage
```

---

## 🏗️ Architecture

```
┌──────────────┐    ┌──────────────┐    ┌─────────────────────────────────────┐
│  Local Dev   │    │   CI/CD      │    │            AWS Cloud                │
│              │    │              │    │                                     │
│  Docker      │    │  GitHub      │    │  API Gateway ──► Lambda (Octane)    │
│  └─ Octane   │    │  Actions     │    │                      │              │
│  └─ Hot reload│   │  └─ PHPStan  │    │         ┌────────────┼──────────┐   │
└──────────────┘    │  └─ Pint     │    │         ▼            ▼          ▼   │
                    │  └─ PHPUnit  │    │      DynamoDB    External       S3  │
                    └──────────────┘    │       (data)       APIs    (storage)│
                                        └─────────────────────────────────────┘
```

> Deployment is triggered manually via `make tf-apply env=dev`

---

## 🛠️ Tech Stack

| Category | Technology |
|---|---|
| Language | PHP 8.5 |
| Framework | Laravel 12 + Octane |
| Serverless | Bref 3.0 |
| Cloud | AWS Lambda, API Gateway, DynamoDB, S3 |
| Infrastructure | Terraform |
| Local Dev | Docker |
| CI/CD | GitHub Actions |
| Quality | PHPUnit · PHPStan · Pint |

---

## 📁 Project Structure

```
api-skeleton/
├── endpoints/                  # One directory per API endpoint
│   └── hello-world/            # Example endpoint
│       ├── app/                # Laravel application
│       ├── routes/             # API routes
│       ├── tests/              # PHPUnit tests
│       └── config/             # Laravel config
├── config/
│   ├── local/                  # Docker configuration
│   └── web/                    # Terraform infrastructure
├── .github/workflows/          # GitHub Actions CI/CD
├── Makefile
└── composer.json
```

---

## 🖥️ Commands

**Development**

| Command | Description |
|---|---|
| `make up` | Start Docker containers |
| `make start` | Restart containers |
| `make composer-install` | Install PHP dependencies |
| `make logs` | Tail PHP logs |
| `make php-console` | Open a PHP shell |

**Code Quality**

| Command | Description |
|---|---|
| `make test-coverage` | Run tests with 100% coverage gate |
| `make pint-check` | Check code style |
| `make pint-fix` | Auto-fix code style |
| `make analyze` | Run PHPStan static analysis |

**Deployment**

```bash
make tf-plan    env=dev   # Preview infrastructure changes
make tf-apply   env=dev   # Deploy to AWS
make tf-destroy env=dev   # Tear down infrastructure
```

---

## 🔄 CI/CD

Every pull request runs the full quality pipeline:

```
push ──► Install deps ──► PHPStan ──► Pint ──► PHPUnit (100% cov.) ──► ✅
```

---

## ➕ Adding a New Endpoint

1. Copy the example: `cp -r endpoints/hello-world endpoints/your-api`
2. Update the namespace in `composer.json`
3. Define routes in `routes/api.php`
4. Add Terraform config in `config/web/endpoints/your-api/`
5. Register the endpoint in `config/web/module.tf`

---

## 📄 License

MIT
