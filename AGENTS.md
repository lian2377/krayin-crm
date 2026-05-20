# Repository Guidelines

## Project Structure & Module Organization
This repository is a Laravel 12 CRM application with a package-based modular layout. Core app bootstrapping lives in `app/`, shared configuration in `config/`, HTTP and console entry routes in `routes/`, and migrations/seeders/factories in `database/`. Business modules are primarily implemented under `packages/Webkul/*/src`, for example `packages/Webkul/Admin/src` and `packages/Webkul/Lead/src`. Tests live in `tests/Unit` and `tests/Feature`. Frontend source is bundled with Vite and compiled assets are emitted into `public/build`, `public/admin/build`, `public/installer/build`, and `public/webform/build`.

## Build, Test, and Development Commands
- `composer install`: install PHP dependencies.
- `npm install`: install root frontend dependencies.
- `php artisan serve`: run the local Laravel server for development.
- `npm run dev`: start the Vite dev server.
- `npm run build`: create production frontend bundles.
- `php artisan test`: run the full test suite.
- `./vendor/bin/pest tests/Feature/AuthenticationTest.php`: run a focused Pest test file.

## Coding Style & Naming Conventions
Follow `.editorconfig`: UTF-8, LF line endings, spaces for indentation, and `indent_size = 4` except YAML files, which use 2 spaces. Format PHP with `./vendor/bin/pint`. Use PSR-4 namespaces that match the directory structure, such as `App\\...` or `Webkul\\Lead\\...`. Keep test files suffixed with `Test.php`; use descriptive class and method names tied to behavior.

## Testing Guidelines
This project uses Pest on top of PHPUnit. Put low-level logic checks in `tests/Unit` and request, auth, or integration coverage in `tests/Feature`. Prefer adding or updating tests with each behavior change. Run `php artisan test` before opening a PR; for targeted work, run only the affected test file first and then the full suite.

## Commit & Pull Request Guidelines
Recent commits use short, direct summaries such as `pint resolved`, `GUI installation fixed`, and `version and changelog updated`. Keep commit messages concise and behavior-focused. Pull requests should include a clear summary, linked issue or task when available, test notes, and screenshots for UI changes. Mention affected packages, routes, or migrations explicitly when relevant.

## Security & Configuration Tips
Do not commit secrets from `.env`. Review changes to `config/*.php`, mail settings, queue settings, and generated assets carefully. Prefer editing source files under `resources/` or `packages/Webkul/*/src` instead of manually changing compiled files in `public/*/build`.
