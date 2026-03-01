AGENTS — Agent instructions for building, linting, testing and style

Purpose
- This file documents the commands and code-style expectations agents (automated tools and humans) should
  follow when operating on this monorepo. The repository is a Dart/Flutter workspace managed with
  Melos and uses a shared lint configuration in `packages/puer_lints/lib/puer_lints.yaml`.

Required tools
- Dart SDK >= 3.6.0 (see `pubspec.yaml` environment)
- Flutter SDK (this repo uses the Flutter version pinned in `.fvmrc`: 3.35.6)
- melos (used to run workspace-wide scripts)
- Recommended: fvm (to pin and use the Flutter/Dart versions defined in `.fvmrc`). Commands in this
  document prefer fvm-prefixed invocations for SDK-bound tooling to ensure consistency with CI.

Bootstrapping (install dependencies)
- From the repository root (preferred):

```bash
# fetch root dependencies and bootstrap the workspace using the pinned SDKs
fvm dart pub get
# install and link workspace packages, run pub get in each package
fvm dart pub run melos bootstrap

# alternatively, if melos is installed globally and you deliberately use the global install:
# melos bootstrap
```

Formatting & lint checks
- CI runs these steps (mirror locally before creating PRs):

```bash
# format all packages (CI: fails if there are changes)
fvm dart pub run melos format --set-exit-if-changed .

# full format (modifies files)
fvm dart pub run melos format .

# run analyzer (Flutter-aware analysis used in CI)
fvm flutter analyze .
```

Notes:
- Prefer using `melos format` for workspace-level formatting so configuration is applied uniformly. When
  running locally via the pinned SDKs, use `fvm dart pub run melos format`.
- If you use FVM, run SDK-bound commands with `fvm dart` and `fvm flutter` (examples above). If you
  intentionally rely on a globally installed `melos`, it's acceptable to run `melos ...` directly — but
  prefer the `fvm dart pub run melos ...` form to ensure the correct Dart runtime.

Running tests
- Run all package tests (CI command):

```bash
# runs the `test` script defined in the root pubspec via melos
fvm dart pub run melos run test
```

- Run tests only for packages that have tests (melos exec alternative used in repo):

```bash
fvm dart pub run melos exec --dir-exists=test -- "fvm flutter test"
```

- Run tests for a single package (examples):

```bash
# pure Dart package
cd packages/puer
fvm dart test

# Flutter package
cd packages/puer_flutter
fvm flutter test
```

- Run a single test file (from the package root):

```bash
# Dart
cd packages/puer
fvm dart test test/feature/feature_test.dart

# Flutter
cd packages/puer_flutter
fvm flutter test test/feature/feature_provider_test.dart
```

- Run a single test by name (filter):

```bash
# pattern matches test names
fvm dart test --name "should emit state"            # from Dart package
fvm flutter test --name "should emit state"         # from Flutter package
```

- Run a single test using melos (scoped):

```bash
fvm dart pub run melos exec --scope=puer -- "fvm dart test test/feature/feature_test.dart"
# or for Flutter package scope
fvm dart pub run melos exec --scope=puer_flutter -- "fvm flutter test test/feature/.."
```

CI (what the pipeline runs)
- See `.github/workflows/validate_repository.yml` for the exact sequence: extract Flutter version from
  `.fvmrc`, install Flutter, run `fvm dart pub run melos format --set-exit-if-changed .`, `fvm flutter analyze .`, and
  `fvm dart pub run melos run test`.

Coding style overview (high-level)
- This monorepo enforces a shared lint set. Each package includes `include: package:puer_lints/puer_lints.yaml`
  (see `packages/puer_lints/lib/puer_lints.yaml`) which is the authoritative source for rules.
- Agents should follow these conventions (summary of the most impactful rules):

- Types & declarations
  - Always declare return types on public functions and methods (`always_declare_return_types: true`).
  - Type-annotate public APIs (`type_annotate_public_apis: true`). Prefer explicit types rather than `dynamic`.
  - Prefer `final` (and `const` where applicable) for local variables and fields (`prefer_final_locals`,
    `prefer_final_fields`, `prefer_const_literals_to_create_immutables`).

- Imports
  - Follow `directives_ordering`: group imports in this order: `dart:` first, then `package:`, then relative
    imports. Keep a blank line between groups.
  - Prefer relative imports for files inside the same package (`prefer_relative_imports: true`).

- Formatting
  - Use the repo formatter via the pinned SDK: `fvm dart format` or the melos wrapper `fvm dart pub run melos format`.
  - Prefer single quotes for strings (`prefer_single_quotes: true`) unless the string contains single quotes.
  - Trailing commas are required on multi-line constructors/collections to produce stable formatting
    (`require_trailing_commas: true` and `formatter.trailing_commas: preserve`).

- Naming
  - File names: snake_case (enforced by `file_names: true`).
  - Types (classes, enums, typedefs): PascalCase / UpperCamelCase (`camel_case_types: true`).
  - Variables, functions, parameters: lowerCamelCase.
  - Private members: prefix with `_`.

- Error handling and exceptions
  - Avoid catching broad exceptions. Use `on` clauses and prefer catching specific exception types
    (`avoid_catches_without_on_clauses: true`, `empty_catches: true`).
  - Do not swallow errors silently; if rethrowing, prefer `rethrow` or `use_rethrow_when_possible: true`.
  - Avoid `print` for logging (`avoid_print: true`) — use a logging package or surface errors via types.
  - Close stream controllers and sinks (`close_sinks: true`).

- Null-safety and casting
  - Prefer non-nullable types. Avoid `!` where possible. Use `required` for named params and prefer
    `always_put_required_named_parameters_first`.
  - Avoid `as` casts and `dynamic` where possible (`avoid_dynamic_calls: true`, `avoid_as: true`). Use
    proper generics and type checks instead.

- Flutter-specific
  - Use `key` in widget constructors (`use_key_in_widget_constructors: true`).
  - Prefer `const` widgets where possible (`prefer_const_constructors_in_immutables: true`).
  - Respect `sized_box_for_whitespace` and `sort_child_properties_last` where they improve readability.

Tests and test style
- Use the `test` package patterns: `group`, `setUp`, `tearDown`, and `test` with clear names.
- Keep unit tests fast and isolated; prefer `mocktail` (already present in some packages) for mocking.
- Name test files with `_test.dart` suffix and place them under a `test/` directory.

Where to find the authoritative rules
- Full lint config: `packages/puer_lints/lib/puer_lints.yaml` (this file lists all enforced lints and
  formatter settings). Agents should consult it before making stylistic changes.

Cursor / Copilot rules
- I searched the repository for Cursor rules (`.cursor/rules/`, `.cursorrules`) and GitHub Copilot
  instruction files (`.github/copilot-instructions.md`) and found none. If you add these, update this
  AGENTS.md and reference them here.

Agent responsibilities / best practices
- Always run format + analyze + unit tests locally before an automated change is proposed.
  1) `fvm dart pub run melos format .`
  2) `fvm flutter analyze .`
  3) `fvm dart pub run melos run test`
- When modifying existing lint rules or `packages/puer_lints/lib/puer_lints.yaml`, prefer small,
  well-justified changes and run the full CI locally to ensure there are no surprises.
- Do not commit secrets, credentials, or environment-specific files. If a change requires credentials,
  ask for a secure mechanism or instructions.

Quick command reference (cheat sheet)
- Bootstrap: `fvm dart pub run melos bootstrap`  (or `melos bootstrap` if you knowingly use a global install)
- Format check (CI): `fvm dart pub run melos format --set-exit-if-changed .`
- Analyze: `fvm flutter analyze .`  (or `fvm dart analyze packages/<pkg>` where appropriate)
- Run all tests (workspace): `fvm dart pub run melos run test`
- Run single package tests: `cd packages/<pkg> && fvm dart test` or `cd packages/<pkg> && fvm flutter test`
- Run single test file: `fvm dart test test/path/to/file_test.dart` or `fvm flutter test test/path/to/file_test.dart`

If you are blocked
- Ask exactly one targeted question describing the problem, the commands you already ran, and include
  the path of the file or failing test output. If requested, provide the failing test output and the
  command you ran.

Last note
- Keep changes small and well-tested. This repository is configured to enforce consistent style via
  `puer_lints`; treat that configuration as the source of truth.
