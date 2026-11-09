# Contributing

Issues and pull requests are welcome, particularly for portability problems on other TeX
distributions and platforms.

Two constraints:

- No change may make it easier to publish personal data by accident.
- The scripts stay portable in their use of `sed` and friends, so they keep working with
  BSD userland on macOS and under Git Bash on Windows. No `sed -i` without an argument,
  no GNU-only `\U`.

Run `./tests/workflow.sh` before opening a pull request. It clones the committed state, so
commit first. CI runs the same suite on Linux, macOS and Windows, lints the scripts with
shellcheck, and builds the sample documents.
