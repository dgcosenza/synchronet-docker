# Security Policy

Maintained by **Daniel G. Cosenza from FNX Labs**.

## Supported Versions

Only the latest daily build of `dgcosenza/synchronet` on Debian 13 (`debian:13.8-slim`, pinned by digest and auto-bumped to the newest official point release) is actively maintained and receives automated security rebuilds.

## Automated Vulnerability Scanning

Every build in GitHub Actions is scanned with both **Trivy** and **Grype** and generates an **SPDX SBOM** artifact:

- **Hard gate:** Builds fail and refuse publication if either Trivy (`--ignore-unfixed`) or Grype (`--only-fixed`) detects any **fixable `CRITICAL` or `HIGH`** vulnerability in OS packages or bundled libraries.
- **Daily rebuilds:** Scheduled daily builds run with `--no-cache` and execute `apt-get update && apt-get -y upgrade` to pick up Debian Security updates, Synchronet upstream commits, and Deno releases promptly.
- **Unfixed advisories:** Advisories without an upstream vendor fix are logged in CI artifacts (`trivy-report`) and cleared automatically once Debian Security or upstream releases a patch.

## Reporting a Vulnerability

- **Container packaging or CI issues:** Open a private security advisory via GitHub Security Advisories on [`dgcosenza/synchronet-docker`](https://github.com/dgcosenza/synchronet-docker/security/advisories/new).
- **Upstream Synchronet BBS issues:** Report directly to the upstream Synchronet project at [gitlab.synchro.net/main/sbbs](https://gitlab.synchro.net/main/sbbs).
