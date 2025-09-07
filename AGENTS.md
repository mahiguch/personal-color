# Repository Guidelines

## Project Structure & Module Organization
- `server/`: FastAPI backend. Code in `server/src/` (e.g., `src/api/main.py`), tests in `server/tests/` (unit, integration, security, performance).
- `web/`: Next.js site. App code in `web/src/`, static assets in `web/public/`.
- `client/personal_color_app/`: Flutter app. Source in `lib/`, tests in `test/`, assets in `assets/`.
- `docs/`, `specifications/`: Documentation and product specs. `scripts/`: utility scripts.

## Build, Test, and Development Commands
- Server (Python):
  - Setup: `cd server && python -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt`
  - Run API: `uvicorn src.api.main:app --reload`
  - Test: `pytest` (use markers like `-m unit`, `-m integration`)
  - Lint/Type: `black . && flake8 && mypy`
- Web (Next.js):
  - Setup: `cd web && npm install`
  - Dev/Build: `npm run dev` | `npm run build && npm run start`
  - Lint: `npm run lint`
- Flutter (Mobile):
  - Setup: `cd client/personal_color_app && flutter pub get`
  - Test: `flutter test`
  - Format/Analyze: `dart format . && dart analyze`
  - Make targets: `make` helpers (e.g., `make ios-release`, `make android-release`, `make ios-debug-device`)

## Coding Style & Naming Conventions
- Python: 4-space indent, `snake_case` for modules/functions, `PascalCase` for classes. Tools: Black, Flake8, MyPy.
- TypeScript/React: 2-space indent, `camelCase` for vars/functions, `PascalCase` for components. ESLint enabled.
- Dart/Flutter: follow Effective Dart; `UpperCamelCase` types, `lowerCamelCase` members. Respect `analysis_options.yaml`.
- File naming: tests `test_*.py` (pytest), React components `ComponentName.tsx`.

## Testing Guidelines
- Python: place tests under `server/tests/`. Prefer fast unit tests; add integration tests for API routes. Use markers (`unit`, `integration`, `security`, `performance`). Aim for high coverage and deterministic tests.
- Flutter: put widget/unit tests in `client/personal_color_app/test`. Keep test assets in `test_assets/`.
- Web: add component tests if applicable; snapshot UI changes when feasible.

## Commit & Pull Request Guidelines
- Commits: prefer Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`). Keep commits focused.
- PRs: clear description, link issues, list changes and test steps. Include screenshots/recordings for UI changes and sample API responses/logs for server changes. Ensure CI passes and linters are clean.

## Security & Configuration Tips
- Never commit secrets. Use `server/.env.example` as a template; keep real env in `.env`.
- Validate inputs at API boundaries and avoid logging PII; images must be deleted after processing per spec.
