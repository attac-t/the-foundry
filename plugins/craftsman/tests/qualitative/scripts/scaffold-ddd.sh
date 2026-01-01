#!/bin/bash
#
# scaffold-ddd.sh - Create Laravel DDD directory structure
#
# Usage: ./scaffold-ddd.sh [target_dir]
#

set -e

TARGET_DIR="${1:-$(pwd)}"

echo "==> Scaffolding DDD structure in $TARGET_DIR"

cd "$TARGET_DIR"

# App layer (thin)
mkdir -p app/Http/Controllers
mkdir -p app/Http/Requests
mkdir -p app/Providers

# Domain layer (business logic)
mkdir -p domain/Orders/Actions
mkdir -p domain/Orders/Models
mkdir -p domain/Orders/DTOs
mkdir -p domain/Orders/QueryBuilders

mkdir -p domain/Users/Actions
mkdir -p domain/Users/Models
mkdir -p domain/Users/DTOs

mkdir -p domain/Products/Models
mkdir -p domain/Products/DTOs

# Support layer (shared utilities)
mkdir -p support/Contracts

# Routes and config
mkdir -p routes
mkdir -p config
mkdir -p database/migrations

echo "    Created $(find . -type d | wc -l | tr -d ' ') directories"
