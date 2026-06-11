#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT_DIR}"

COMPOSE_CMD=(docker compose)

env_value() {
    local key="$1"
    local from_shell="${!key:-}"

    if [[ -n "${from_shell}" ]]; then
        printf '%s' "${from_shell}"
        return 0
    fi

    if [[ -f .env ]]; then
        awk -F= -v search_key="${key}" '
            $0 !~ /^[[:space:]]*#/ && $1 == search_key {
                value = substr($0, index($0, "=") + 1)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
                gsub(/^'\''|'\''$/, "", value)
                gsub(/^"|"$/, "", value)
                print value
                exit
            }
        ' .env
    fi
}

ensure_env() {
    if [[ ! -f .env ]]; then
        cp .env.example .env
        echo "Created .env from .env.example. Review and update values before proceeding."
    fi
}

ensure_app_key() {
    local current_key
    current_key="$(env_value APP_KEY)"

    if [[ -z "${current_key}" ]]; then
        local new_key="base64:$(openssl rand -base64 32)"
        sed -i "s|^APP_KEY=.*|APP_KEY=${new_key}|" .env
        echo "Generated APP_KEY."
    fi
}

warn_proxy_env() {
    local domain_name
    local letsencrypt_email

    domain_name="$(env_value DOMAIN_NAME)"
    letsencrypt_email="$(env_value LETSENCRYPT_EMAIL)"

    if [[ -z "${domain_name}" || -z "${letsencrypt_email}" ]]; then
        echo "Warning: DOMAIN_NAME or LETSENCRYPT_EMAIL is not set in the shell or .env."
        echo "nginx-proxy / letsencrypt companion integration may be incomplete until these values are provided."
    fi
}

compose() {
    "${COMPOSE_CMD[@]}" "$@"
}

usage() {
    cat <<'EOF'
Usage: ./manage.sh <command> [args...]

Commands:
  build           Build the app image
  up              Start all services in detached mode
  down            Stop and remove containers
  restart         Restart all services
  logs [service]  Tail compose logs
  ps              Show service status
  shell           Open a shell inside the app container
  artisan ...     Run an artisan command inside the app container
  install         First-time setup: prepare .env, generate APP_KEY, run migrations and create admin
  test            Run php artisan test inside the app container
EOF
}

command="${1:-}"

case "${command}" in
    build)
        ensure_env
        compose build --pull
        ;;
    up)
        ensure_env
        warn_proxy_env
        compose up -d
        ;;
    down)
        compose down
        ;;
    restart)
        ensure_env
        warn_proxy_env
        compose restart
        ;;
    logs)
        shift || true
        compose logs -f "$@"
        ;;
    ps)
        compose ps
        ;;
    shell)
        ensure_env
        compose exec app bash
        ;;
    artisan)
        shift
        ensure_env
        compose exec app php artisan "$@"
        ;;
    install)
        ensure_env
        ensure_app_key
        warn_proxy_env
        compose up -d
        compose exec app php artisan krayin-crm:install --skip-env-check
        ;;
    test)
        ensure_env
        compose exec app php artisan test
        ;;
    ""|-h|--help|help)
        usage
        ;;
    *)
        echo "Unknown command: ${command}" >&2
        usage
        exit 1
        ;;
esac
