# CONVENTIONS.md — permanent rules for this codebase

These rules apply to every batch. They were agreed with the product owner on
2026-07-08 and are not optional.

## Architecture
- Stack is Flutter + BLoC. Every feature's state lives in a real, fully
  implemented Bloc/Cubit — no empty stubs, no `on<Event>((e, emit) {})`
  placeholders, no state held in globals, statics, or widget fields when it
  belongs to a Bloc.
- Full rewrite is allowed (and preferred) where a module is fundamentally
  wrong (auth, global error handling, empty Blocs). Working code gets minimal,
  explainable diffs instead.
- Layering: `data_source (Dio) → repository → bloc → screen`. Keep the
  repository layer where it exists; new features follow it.
- Dependency injection via get_it in `lib/locator.dart` only.

## API contract
- Backend `urls.py` files + view classes are the only source of truth.
  `ALL_ENDPOINTS.txt` / markdown docs in the backend repo are approximate.
- Auth header is `Authorization: Token <key>` (DRF TokenAuthentication).
  There is no JWT, no refresh endpoint, no server-side logout.
- Response envelope: success `{success, code, data, message}`, failure
  `{success, code, error: {code, detail}}`.
- Never invent endpoints. If the backend lacks something the UI needs:
  document it in ARCHITECTURE_MAP.md §7, add an explicitly-marked temporary
  mock, keep going.

## Code style
- Dart idioms; single-responsibility functions; guard clauses for error paths.
- Comments only for non-obvious "why", never "what".
- No hardcoded secrets, API keys, or business values (prices, costs, limits).
- Every batch ships with tests for its critical logic (auth, payment,
  user-data state at minimum).
- Structured logging via `AppLogger` (`lib/core/logging/`) — never `print`,
  `debugPrint`, or bare `dart:developer` `log` in feature code.

## Process
- One commit per batch, clear message.
- After each batch: update ARCHITECTURE_MAP.md status + NOTES.md, verify
  against the real backend contract with a separate sub-agent.
- Temporary scripts/files are deleted before commit.
