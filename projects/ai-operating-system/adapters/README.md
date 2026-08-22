# Adapter Layer

Adapters implement connector-specific behavior for `workspace-operator`. Version 1.0.0 ships contracts and acceptance requirements, not credentials or an assumed third-party MCP implementation.

Every adapter must implement:

1. `capabilities()` — operations and scopes actually available.
2. `resolve_target()` — exact record lookup and ambiguity scoring.
3. `search_duplicates()` — service-specific plus semantic duplicate search.
4. `execute()` — minimum permitted action.
5. `verify()` — read-after-write confirmation.
6. `rollback()` — reversal or documented manual reversal.
7. `sanitize_audit()` — non-secret audit record.

Missing adapter behavior is an exception, not permission to use browser cookies or claim success.
