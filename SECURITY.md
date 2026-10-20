# Security Policy

## Supported Versions

Only the latest release receives security fixes.

## Reporting a Vulnerability

If you discover a security vulnerability, please **do not** open a public issue.

Prefer GitHub's [private vulnerability reporting](https://github.com/C92D58/TokenVault/security/advisories/new), or email **x@wahsun.org**.

Please include:

- A description of the vulnerability and its impact
- Reproduction steps (a minimal example if possible)
- Your suggested fix (optional)

We will acknowledge receipt within 48 hours and credit you in the release notes after a fix ships (unless you prefer to stay anonymous).

## Security Design

TokenVault's threat model and design principles:

- **Local encryption**: every token value is encrypted with AES-256-GCM before being written to disk
- **Key isolation**: the master encryption key lives in the macOS Keychain (Secure Enclave) and never leaves the device
- **No servers**: no remote server of any kind; iCloud / GitHub sync carries ciphertext only
- **Least privilege**: the app is sandboxed and requests only the permissions it needs
- **Clipboard protection**: copied tokens are cleared automatically

## Out of Scope

- Attacks requiring physical access to an unlocked device
- Environments with jailbroken / disabled system security
- Third-party dependency issues (this project has zero dependencies)
