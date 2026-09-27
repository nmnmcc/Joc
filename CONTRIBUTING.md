# Contributing to Joc

Thanks for helping improve Joc. Small, focused pull requests are easiest to
review.

## Development setup

1. Install macOS, Xcode, Nix, Devenv, and Direnv.
2. Clone the repository and run `direnv allow`.
3. Generate the Xcode project with `generate`.
4. Run `format`, `lint`, and `build` before opening a pull request.

The project uses CloudKit and Apple code signing. Use your own development
team and CloudKit container when working on a fork. Do not commit signing
certificates, provisioning profiles, private keys, or CloudKit secrets.

## Pull requests

- Explain the user-facing behavior and the reason for the change.
- Include verification steps and any device or OS limitations.
- Keep generated Xcode changes in sync with `project.yml`.
- Update the README when setup or CloudKit schema requirements change.
