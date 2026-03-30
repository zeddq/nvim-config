# Run Tests

Run the Neovim configuration test suite:

1. Execute `./tests/run_all_tests.sh` from the repository root (unit tests with mocks)
2. Parse the output for pass/fail counts
3. If any tests fail, read the failing test file and diagnose the issue
4. Report a summary: total tests, passed, failed, and any error details

To also run integration tests (require real plugins loaded by lazy.nvim):

```
./tests/run_all_tests.sh --integration
```
