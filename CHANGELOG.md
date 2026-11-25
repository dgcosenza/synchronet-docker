# Changelog

All notable changes to the `dgcosenza/synchronet` Debian 13 container packaging and CI workflows are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Maintained by **Daniel G. Cosenza from FNX Labs**.

---
<!-- changelog:auto -->

## [3.22a-c20f737] — 2026-11-25

### Automated Daily Build
- Verified components: Synchronet BBS `3.22a (c20f737)`, Deno `2.9.8`, Base OS `Debian 13.8 (trixie-slim)`.
- Upstream status: no new upstream release since previous build; refreshed base OS and dependencies.
- Vulnerability gate: **0 fixable Critical/High** in Trivy and Grype (33 upstream-unfixed).
- Published digest: `dgcosenza/synchronet@sha256:7afdeb69d4787a98b31b43b424c360ec3abe094d60eb4db980cfa42da9033f89`.

---

## [3.22a] — 2026-11-24

### Added
- Automated container smoke test (`tests/smoke.sh`) running in CI to verify fresh `/sbbs-data` initialization, non-root `sbbs` (UID/GID `1000`) execution, `cap_net_bind_service` capability, HTTP webv4 readiness, and a negative closed-port probe.
- Full seven-step automated daily pipeline in `.github/workflows/daily.yml`: `pull_request` trigger, `workflow_dispatch` version overrides, `no-cache` on schedule, upstream diff tracking (`versions.json` + `upstream-changes.md`), Trivy + Grype blocking gates with CVE diffing and 90-day report artifacts, SARIF upload, Syft SPDX SBOM + provenance, date-stamped immutable tags (`<version>-<YYYYMMDD>`, `<version>-<commit>-<YYYYMMDD>`, `sha-<short>`), automated `README.md`/`CHANGELOG.md` bot sync + Docker Hub description sync, and `ci-failure` GitHub issue alerting with auto-close on recovery.
- Repository governance and documentation files: `CHANGELOG.md`, `LICENSE`, `SECURITY.md`, `docker-compose.example.yml`, `.github/dependabot.yml`, and automated public-content verification (`.github/workflows/public-check.yml`).

### Changed
- Authenticated GitHub API lookup (`Authorization: Bearer $GH_TOKEN`) when resolving the latest Deno release in CI.
- Refreshed Dockerfile default source pin to Synchronet `3.22a` commit `c20f7377662025b629978cfeade8563a6a7ac97e` on Debian 13 (`trixie-slim`, currently 13.8) with Deno `2.9.8`.
- Standardized OCI image labels (`org.opencontainers.image.*` and `io.github.dgcosenza.synchronet.*`) and maintainer attribution (`Daniel G. Cosenza from FNX Labs`).

---

## [3.22a-933e849] — 2026-11-20

### Changed
- Updated default source pin to Synchronet `3.22a` commit `933e8499ac81251da7929f16cdcff3ca71239cdb` following upstream signed-character fixes.
- Enabled main-branch builds and automated Docker Hub overview synchronization.

---

## [3.22a-6bd53d6] — 2026-11-20

### Added
- Initial multi-stage Debian 13 (`trixie-slim`) source build of Synchronet `3.22a` (commit `6bd53d6b60c4edaddead52a36be2c5479f1aeafb`) with checksum-verified Deno `2.9.8`, UID/GID `1000` runtime, webv4 HTTP healthcheck, and daily Trivy-gated builds.
