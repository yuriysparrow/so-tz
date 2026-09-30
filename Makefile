.DEFAULT_GOAL := help
SHELL := /bin/bash

COMPOSE    ?= docker compose
APP        ?= app
EXEC_FLAGS ?=

export HOST_UID ?= $(shell id -u)
export HOST_GID ?= $(shell id -g)

env_get = $(shell grep -E '^$(1)=' .env 2>/dev/null | tail -1 | cut -d= -f2- | sed -e 's/[[:space:]]*\#.*$$//' -e 's/^"//' -e 's/"$$//' | tr -d '\r')

DB      = $(or $(call env_get,COMPOSE_PROFILES),mysql)
DB_NAME = $(or $(call env_get,DOCKER_DB_NAME),app)
DB_USER = $(or $(call env_get,DOCKER_DB_USER),app)
DB_PASS = $(or $(call env_get,DOCKER_DB_PASSWORD),secret)

ARTISAN = $(COMPOSE) exec $(EXEC_FLAGS) $(APP) php artisan

.PHONY: help init env dirs build rebuild install key up down restart ps logs shell \
		migrate migrate-status rollback migrate-fresh use-mysql use-pgsql db-shell \
		import import-dry artisan composer test perms clean

##@ Ініціалізація
init: env dirs build install up key migrate ## Повна ініціалізація проєкту з нуля
	@echo ""
	@echo "Готово. Сторінка імпорту: http://localhost:8080/import"

env: ## Створити .env з .env.example, якщо його ще немає
	@if [ -f .env ]; then echo ".env вже є"; else cp .env.example .env && echo ".env створено з .env.example"; fi

dirs: ## Створити каталоги Laravel (storage, cache) від імені поточного користувача
	@mkdir -p storage/app/private/imports storage/framework/cache/data storage/framework/sessions \
			  storage/framework/views storage/logs bootstrap/cache

install: ## composer install всередині контейнера
	$(COMPOSE) run --rm -T $(APP) composer install --no-interaction

key: ## Згенерувати APP_KEY, якщо він порожній
	@if grep -qE '^APP_KEY=.+' .env; then echo "APP_KEY вже задано"; else $(COMPOSE) run --rm -T $(APP) php artisan key:generate; fi

##@ Docker
build: ## Зібрати образи
	$(COMPOSE) build

rebuild: ## Перезібрати образи без кешу
	$(COMPOSE) build --no-cache

up: ## Запустити контейнери й дочекатися готовності БД
	$(COMPOSE) up -d --wait

down: ## Зупинити та видалити контейнери (дані БД зберігаються)
	$(COMPOSE) --profile '*' down --remove-orphans

restart: down up ## Перезапустити контейнери

ps: ## Стан контейнерів
	$(COMPOSE) ps

logs: ## Логи всіх контейнерів (Ctrl+C для виходу)
	$(COMPOSE) logs -f --tail=100

shell: ## Консоль усередині контейнера застосунку
	$(COMPOSE) exec $(APP) sh

clean: ## НЕБЕЗПЕЧНО: видалити контейнери ТА томи з даними БД
	@read -r -p "Буде видалено контейнери та ВСІ дані БД. Продовжити? [y/N] " a; [ "$$a" = "y" ] || { echo "Скасовано"; exit 1; }
	$(COMPOSE) --profile '*' down -v --remove-orphans

perms: ## Виправити права на storage і bootstrap/cache
	$(COMPOSE) run --rm -T -u root $(APP) sh -c "chown -R $(HOST_UID):$(HOST_GID) storage bootstrap/cache && chmod -R ug+rwX storage bootstrap/cache"

##@ База даних і міграції
migrate: ## Накотити міграції
	$(ARTISAN) migrate

migrate-status: ## Статус міграцій
	$(ARTISAN) migrate:status

rollback: ## Відкотити останній батч міграцій
	$(ARTISAN) migrate:rollback

migrate-fresh: ## НЕБЕЗПЕЧНО: видалити всі таблиці й накотити міграції заново
	@read -r -p "Будуть видалені ВСІ таблиці. Продовжити? [y/N] " a; [ "$$a" = "y" ] || { echo "Скасовано"; exit 1; }
	$(ARTISAN) migrate:fresh

use-mysql: ## Перемкнути .env на MySQL (потім: make restart migrate)
	@sed -i.bak -e 's/^COMPOSE_PROFILES=.*/COMPOSE_PROFILES=mysql/' -e 's/^DB_CONNECTION=.*/DB_CONNECTION=mysql/' \
		-e 's/^DB_HOST=.*/DB_HOST=mysql/' -e 's/^DB_PORT=.*/DB_PORT=3306/' .env && rm -f .env.bak
	@echo ".env перемкнено на MySQL. Виконайте: make restart migrate"

use-pgsql: ## Перемкнути .env на PostgreSQL (потім: make restart migrate)
	@sed -i.bak -e 's/^COMPOSE_PROFILES=.*/COMPOSE_PROFILES=pgsql/' -e 's/^DB_CONNECTION=.*/DB_CONNECTION=pgsql/' \
		-e 's/^DB_HOST=.*/DB_HOST=pgsql/' -e 's/^DB_PORT=.*/DB_PORT=5432/' .env && rm -f .env.bak
	@echo ".env перемкнено на PostgreSQL. Виконайте: make restart migrate"

db-shell: ## Консоль БД (psql або mysql, за COMPOSE_PROFILES)
	@if [ "$(DB)" = "pgsql" ]; then \
		$(COMPOSE) exec -e PGPASSWORD=$(DB_PASS) pgsql psql -U $(DB_USER) -d $(DB_NAME); \
	else \
		$(COMPOSE) exec -e MYSQL_PWD=$(DB_PASS) mysql mysql -u$(DB_USER) $(DB_NAME); \
	fi

##@ Інше
artisan: ## make artisan c="route:list"
	$(ARTISAN) $(c)

composer: ## make composer c="require vendor/package"
	$(COMPOSE) exec $(EXEC_FLAGS) $(APP) composer $(c)

test: ## Запустити тести
	$(ARTISAN) test

help: ## Список команд
	@awk 'BEGIN {FS = ":.*?## "; printf "\nВикористання: make \033[36m<ціль>\033[0m\n"} \
		/^##@/ {printf "\n\033[1m%s\033[0m\n", substr($$0, 5)} \
		/^[a-zA-Z0-9_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
