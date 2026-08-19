# Contributing to Beinn

First off, thank you for considering contributing to Beinn! We welcome contributions from everyone.

## Getting Started

1. Fork the repository and clone it to your local machine.
2. Follow the setup instructions in the [README.md](README.md) to get the Flutter frontend and NestJS backend running locally.
3. Create a new branch for your feature or bugfix: `git checkout -b feature/your-feature-name`.

## Code Style & Standards

### Flutter (Dart)
- Follow the official Dart style guide.
- Always run `dart format .` before committing.
- Ensure `flutter analyze` returns no warnings or errors.
- Write widget tests for any complex UI components.

### NestJS (TypeScript)
- Use strong typing. Avoid `any`.
- Keep controllers thin and move business logic to providers/services.
- Run `npm run lint` and `npm run format` prior to committing.
- Ensure all endpoints are documented using Swagger/OpenAPI decorators.

## Pull Request Process

1. **Commit Messages:** Use conventional commits (e.g., `feat: add driver proximity alert`, `fix: resolve socket memory leak`).
2. **Documentation:** Update the `README.md`, `API.md`, or other relevant markdown files if your changes affect the system architecture or public APIs.
3. **Tests:** Ensure all existing and new tests pass in the GitHub Actions CI pipeline.
4. **Review:** Request a review from one of the core maintainers. Be prepared to address feedback and make adjustments.

## CI/CD 
Our GitHub Actions pipeline will automatically run linting, formatting checks, and unit tests on your PR. Your PR cannot be merged until all checks pass.
