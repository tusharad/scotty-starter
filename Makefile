.PHONY: help build run test repl check clean format lint watch

# Default target
.DEFAULT_GOAL := help

help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build library, executable, and test suite
	cabal build all

run: ## Run the web server executable
	cabal run scotty-starter

test: ## Run test suite with direct output
	cabal test --test-show-details=direct

repl: ## Open interactive Cabal REPL
	cabal repl

check: ## Verify Cabal package specification
	cabal check

clean: ## Clean build artifacts
	cabal clean

format: ## Format all Haskell sources with Fourmolu
	@which fourmolu >/dev/null 2>&1 && fourmolu --mode inplace $$(find src app test -name "*.hs") || echo "fourmolu not installed; skipping format"

lint: ## Lint all Haskell sources with HLint
	@which hlint >/dev/null 2>&1 && hlint src app test || echo "hlint not installed; skipping lint"

watch: ## Live test watcher using ghcid
	@which ghcid >/dev/null 2>&1 && ghcid --command="cabal repl scotty-starter-test" --test=":main" || echo "ghcid not installed; please install via ghcup or nix"

docker-build: ## Build production Docker container image
	docker build -t scotty-starter:latest .

docker-run: ## Run container locally via docker-compose
	docker compose up --build

preview-pages: ## Preview static GitHub Pages export locally on http://localhost:8080
	python3 -m http.server 8080 --directory docs

