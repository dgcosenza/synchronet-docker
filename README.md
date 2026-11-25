# Synchronet BBS for Debian 13 (trixie)

[![Daily Synchronet image](https://github.com/dgcosenza/synchronet-docker/actions/workflows/daily.yml/badge.svg)](https://github.com/dgcosenza/synchronet-docker/actions/workflows/daily.yml)
[![Packaging License: MIT](https://img.shields.io/badge/packaging-MIT-blue.svg)](https://github.com/dgcosenza/synchronet-docker/blob/main/LICENSE)
[![Upstream License: GPL-2.0-or-later](https://img.shields.io/badge/upstream-GPL--2.0--or--later-green.svg)](https://www.synchro.net/copyright.html)
[![Signed with Cosign](https://img.shields.io/badge/signed-cosign%20OIDC-blueviolet.svg)](#supply-chain-verification)
[![SLSA Level 3](https://img.shields.io/badge/SLSA-Level%203-brightgreen.svg)](#supply-chain-verification)
[![Architectures](https://img.shields.io/badge/arch-amd64-informational.svg)](#supported-architectures)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/dgcosenza/synchronet-docker/badge)](https://scorecard.dev/viewer/?uri=github.com/dgcosenza/synchronet-docker)
[![Docker Pulls](https://img.shields.io/docker/pulls/dgcosenza/synchronet)](https://hub.docker.com/r/dgcosenza/synchronet)
[![Docker Image Size](https://img.shields.io/docker/image-size/dgcosenza/synchronet/latest)](https://hub.docker.com/r/dgcosenza/synchronet)
[![Latest Release](https://img.shields.io/github/v/release/dgcosenza/synchronet-docker?label=version)](https://github.com/dgcosenza/synchronet-docker/releases)

A source-built, actively maintained container image for **Synchronet BBS** on **Debian 13 (trixie)**, maintained by **Daniel G. Cosenza from FNX Labs**.

- **Docker Hub:** [`dgcosenza/synchronet`](https://hub.docker.com/r/dgcosenza/synchronet)
- **GitHub Container Registry (GHCR):** [`ghcr.io/dgcosenza/synchronet`](https://github.com/dgcosenza/synchronet-docker/pkgs/container/synchronet) (identical signed multi-arch digest)
- **Source Repository:** [`dgcosenza/synchronet-docker`](https://github.com/dgcosenza/synchronet-docker)
- **Upstream Application:** [`SynchronetBBS/sbbs`](https://github.com/SynchronetBBS/sbbs) (mirror of [`gitlab.synchro.net/main/sbbs`](https://gitlab.synchro.net/main/sbbs))
- **License:** Packaging MIT; Synchronet GPL/LGPL (see [`THIRD-PARTY-NOTICES.md`](https://github.com/dgcosenza/synchronet-docker/blob/main/THIRD-PARTY-NOTICES.md))

---

## Overview

This repository builds and maintains a source-built **Synchronet BBS** container on **Debian 13 (trixie)** (`debian:trixie-slim`, latest Debian 13 point release — 13.8 as of 2026-11-24). Every CI build resolves the current upstream Synchronet `master` commit, validates the version header (`sbbsdefs.h`), upgrades all Debian packages (`apt-get update && apt-get -y upgrade`), installs the latest SHA-256-verified **Deno** release, runs a container smoke test, and gates publication on **0 fixable Critical/High vulnerabilities** in both **Trivy** and **Grype**.

Synchronet is developed at [gitlab.synchro.net/main/sbbs](https://gitlab.synchro.net/main/sbbs). The build fetches the exact commit from the maintained [SynchronetBBS GitHub mirror](https://github.com/SynchronetBBS/sbbs) because unauthenticated GitLab smart-HTTP refs are not consistently available to automated container builders. The packaging modernizes the Debian 11 `bbsio/synchronet` recipe; it is independently maintained and is not an official Synchronet or BBS-IO image.

The persistent data mount follows the `/sbbs-data` layout used by `bbsio/synchronet`. Test upgrades on a cold copy of your data directory first.

---

## Current Versions

<!-- versions:start -->
| Component | Resolved Version |
| --- | --- |
| Synchronet BBS | `3.22a (71df4cf)` |
| Deno | `2.9.8` |
| Base OS | `Debian 13.8 (trixie-slim)` |
| Architectures | `linux/amd64` |
| Uncompressed size (per arch) | `amd64: 135.9 MB` |
| Last verified build (UTC) | `2026-11-25` |
| Published multi-arch digest | `dgcosenza/synchronet@sha256:b04f8f408009efd655648916f0d56f263cffc40ffa46795fc0fe5bcd104d9343` |
| GHCR mirror | `ghcr.io/dgcosenza/synchronet@sha256:b04f8f408009efd655648916f0d56f263cffc40ffa46795fc0fe5bcd104d9343` |
| Supply chain | Cosign OIDC signed + SPDX & CycloneDX SBOM attestations + SLSA Build L3 provenance |
| Security gate (Trivy + Grype on SBOM) | **0 fixable Critical/High** (33 upstream-unfixed) |
<!-- versions:end -->

---

## Supported Tags

| Tag | Policy | Description |
| --- | --- | --- |
| `<version>-<commit>-<YYYYMMDD>` (e.g. `3.22a-c20f737-20261124`) | **Immutable** | Point-in-time build pinning the Synchronet version, upstream commit, and UTC build date. |
| `<version>-<YYYYMMDD>` (e.g. `3.22a-20261124`) | **Immutable** | Date-stamped daily rebuild on the resolved Debian 13 base. |
| `<version>-<commit>` (e.g. `3.22a-c20f737`) | **Immutable** | First verified build for a given upstream Synchronet source commit. |
| `sha-<short>` | **Immutable** | Packaging repository commit tag. |
| `<version>` (e.g. `3.22a`) | Moving | Latest verified build in the current Synchronet release line. |
| `nightly` | Moving | Latest verified build tracking Synchronet `master`. |
| `latest` | Moving | Alias of `nightly` (never a frozen historical release). |

Each published image records the exact Synchronet version, upstream commit SHA, and Deno version in its OCI labels (`org.opencontainers.image.*` and `io.github.dgcosenza.synchronet.*`). See [`CHANGELOG.md`](https://github.com/dgcosenza/synchronet-docker/blob/main/CHANGELOG.md) for recent default pins and release notes.

**Production pinning:** Pin deployments by **registry digest** rather than pulling an unpinned moving tag:

```yaml
image: dgcosenza/synchronet:latest@sha256:<digest>
```

---

## Supported Architectures

| Architecture | Status | Verification |
| --- | --- | --- |
| `linux/amd64` | **Published & natively tested** | Built, smoke-tested, Dive-gated, Syft/Trivy/Grype-scanned, and Cosign-signed on native x86_64 CI runners. |
| `linux/arm64` | **Not supported (upstream limitation)** | Synchronet's embedded SpiderMonkey 1.8.5 runtime registers an `aarch64` Linux constructor (`src/sbbs3/js_global.cpp`, `addr_compat_layout_hack`) that calls `personality(ADDR_COMPAT_LAYOUT)` and aborts with `Operation not permitted` under default container seccomp profiles (upstream `bbsio/synchronet` is likewise `amd64`-only). |

Identical signed OCI digests are published to **Docker Hub** and **GHCR** (`ghcr.io/dgcosenza/synchronet`), accompanied by automated signed [GitHub Releases](https://github.com/dgcosenza/synchronet-docker/releases).
---

## Quick Start

Create a persistent data directory owned by the container service account (**UID/GID `1000:1000`**):

```bash
mkdir -p "$HOME/synchronet/data"
sudo chown -R 1000:1000 "$HOME/synchronet/data"
cd "$HOME/synchronet"
```

### `docker run` (loopback-only example)

This example keeps services on loopback and maps SSH, Telnet, and webv4 to non-privileged host ports. Add other mappings only after reviewing protocol and firewall exposure:

```bash
docker run -d \
  --name synchronet \
  --restart unless-stopped \
  -e TZ=Etc/UTC \
  -p 127.0.0.1:2323:22 \
  -p 127.0.0.1:2324:23 \
  -p 127.0.0.1:8080:80 \
  -v "$PWD/data:/sbbs-data" \
  dgcosenza/synchronet:latest
```

Open the web interface at `http://127.0.0.1:8080/`, or connect via SSH on port `2323` or Telnet on port `2324`. Synchronet initializes missing data directories on first startup.

### Docker Compose

See [`docker-compose.example.yml`](https://github.com/dgcosenza/synchronet-docker/blob/main/docker-compose.example.yml):

```yaml
services:
  bbs:
    image: dgcosenza/synchronet:latest
    container_name: synchronet
    command: ["/sbbs/scripts/sbbs", "syslog"]
    restart: unless-stopped
    environment:
      TZ: Etc/UTC
    volumes:
      - ./data:/sbbs-data
    ports:
      - "127.0.0.1:2323:22"
      - "127.0.0.1:2324:23"
      - "127.0.0.1:8080:80"
      - "127.0.0.1:11230:1123"
    healthcheck:
      test: ["CMD", "curl", "--fail", "--silent", "--show-error", "--output", "/dev/null", "--max-time", "10", "http://127.0.0.1/"]
      interval: 120s
      timeout: 10s
      start_period: 120s
      retries: 3
```

Start with `docker compose up -d` and inspect with `docker compose ps` and `docker compose logs --tail=100 bbs`.

---

## Configuration

### Environment Variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `TZ` | `Etc/UTC` | System timezone used by processes and logs (any installed IANA timezone, e.g. `America/New_York`). |
| `TERM` | `xterm` | Terminal type for console tools. |
| `DENO_DIR` | `/sbbs-data/.deno` | Persistent Deno cache and generated module directory inside the data volume. |
| `SBBSCTRL` | `/sbbs/ctrl` | Synchronet control directory inside the container (symlinks to `/sbbs-data/ctrl`). |
| `SBBSEXEC` | `/sbbs/exec` | Synchronet executable directory inside the container. |
| `PATH` | `/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/sbbs/scripts:/sbbs/exec` | Runtime command search path. Preserve Synchronet paths if overriding. |

Synchronet configuration lives in `/sbbs-data/ctrl/` (`sbbs.ini`, `services.ini`, `modopts.ini`). The initializer does not overwrite an existing `ctrl/sbbs.ini`. Never store sysop credentials in an image layer or public repository.

### Volumes and UID/GID

| Container Path | Mode / Owner | Purpose |
| --- | --- | --- |
| `/sbbs-data` | `1000:1000` (`sbbs`) | Persistent BBS state: `backup/`, `ctrl/`, `data/`, `.deno/`, `fido/`, `mods/`, `nodes/`, `text/`, `web/`, `xtrn/`. |
| `/dev/log` *(optional)* | Host syslog socket | Optional read-write mount so `["/sbbs/scripts/sbbs", "syslog"]` forwards events to host syslog / `fail2ban`. |

Never mount the same `/sbbs-data` directory into two Synchronet containers simultaneously.

### Ports

Ports listen inside the container only when enabled in `ctrl/services.ini` and `ctrl/sbbs.ini`. Publish only the protocols your deployment uses:

| Container Port | Service | Exposure Notes |
| ---: | --- | --- |
| `23` | Telnet | Plaintext; keep off untrusted networks. |
| `22` | Synchronet SSH | Typically mapped to host `2323` to avoid colliding with host `sshd`. |
| `21` | FTP | Plaintext; keep off untrusted networks. |
| `80` / `443` | HTTP / HTTPS (webv4) | Port `80` is probed by the built-in healthcheck. |
| `513` | Rlogin | Legacy plaintext protocol. |
| `1123` / `11235` | Web terminal WebSocket (plain / TLS) | Commonly fronted by a reverse proxy. |
| `6667` / `6697` | IRC / IRC over TLS | Enable explicitly in `services.ini` when needed. |
| `24554` / `24553` | BinkP / BinkP over TLS | FidoNet mail transfer. |
| `25`, `465`, `587` | SMTP / SMTPS / Submission | Mail transfer and submission. |
| `110`, `143`, `993`, `995` | POP3 / IMAP (plain and TLS) | Mail access. |
| `70`, `79`, `119`, `563`, `17`, `18`, `11`, `5500`, `5501`, `10088` | Legacy & JSON API services | Optional; restrict `10088` (JSON API) to trusted networks. |

Block plaintext protocols from untrusted networks using a host firewall (for example, `DOCKER-USER` iptables/nftables rules) before publishing ports.

---

## Healthcheck

```dockerfile
HEALTHCHECK --interval=120s --timeout=10s --start-period=120s --retries=3 \
  CMD curl --fail --silent --show-error --output /dev/null --max-time 10 http://127.0.0.1/
```

The healthcheck probes Synchronet's internal `webv4` HTTP listener on `http://127.0.0.1/` every 120 seconds (avoiding excessive guest login/logout log noise from shorter intervals) and treats HTTP `2xx`/`3xx` as healthy.

---

## Upgrading and Migrating from `bbsio/synchronet`

This image preserves the `/sbbs-data` layout for the Synchronet `3.22a` data line.

> **Important:** The old `bbsio/synchronet:latest` tag is frozen on Synchronet `3.19c` (April 2023), which can spin at 100% CPU while idle in `sbbs/termOutput`. Do not downgrade `3.22a` data to `3.21e` or older.

1. Stop the existing BBS container and take a cold backup of the entire `/sbbs-data` tree (`tar --numeric-owner --acls --xattrs -czf ...`).
2. Start a side-by-side trial container against a **copy** of `/sbbs-data` on unused loopback ports.
3. Verify healthcheck status, startup logs, enabled protocols, and idle CPU.
4. Pin the reviewed image digest in Compose (`dgcosenza/synchronet:latest@sha256:<digest>`), recreate the service, and keep the previous image tag and backup for rollback.

---

## Supply-Chain Verification

Every published digest (multi-arch index and per-architecture manifests) on both Docker Hub and GHCR is keyless-signed with **Sigstore Cosign** (GitHub OIDC), attested with **SPDX** and **CycloneDX** SBOMs, and backed by **SLSA Build L3** provenance (`actions/attest-build-provenance`).

### Verify image signature with Cosign

```bash
cosign verify \
  --certificate-identity-regexp="^https://github\.com/dgcosenza/synchronet-docker/\.github/workflows/daily\.yml@refs/heads/main$" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/dgcosenza/synchronet:latest

# Or against Docker Hub (identical digest):
cosign verify \
  --certificate-identity-regexp="^https://github\.com/dgcosenza/synchronet-docker/\.github/workflows/daily\.yml@refs/heads/main$" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  dgcosenza/synchronet:latest
```

### Verify SPDX / CycloneDX SBOM attestations and SLSA Build Provenance

```bash
cosign verify-attestation \
  --type spdxjson \
  --certificate-identity-regexp="^https://github\.com/dgcosenza/synchronet-docker/\.github/workflows/daily\.yml@refs/heads/main$" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/dgcosenza/synchronet@sha256:<arch-digest>

gh attestation verify oci://ghcr.io/dgcosenza/synchronet:latest --owner dgcosenza
```

---

## Security

- **Vulnerability scan policy:** Every CI build runs **Trivy** (full table artifact, SARIF upload to GitHub Code Scanning, and blocking `--ignore-unfixed` gate) and **Grype** (`--only-fixed`, severity cutoff `high`, blocking gate), plus generates an **SPDX SBOM** artifact via Syft. Publication is blocked on any fixable `CRITICAL` or `HIGH` finding.
- **Current status:** **0 fixable Critical/High** vulnerabilities across Debian 13 OS packages and runtime libraries (verified every build; unfixed upstream Debian advisories, if any, are recorded in the `trivy-report` CI artifact and resolved automatically on daily rebuilds once Debian Security publishes fixes).
- **Non-root runtime and capability model:** The BBS runs as non-root `sbbs` (UID/GID `1000`) with `cap_net_bind_service=+ep` on `/sbbs/exec/sbbs`. Because initialization adjusts volume ownership and low-port privileges via `sudo`, **do not** set `security_opt: no-new-privileges:true` on this container.
- **CA bundle:** Ships the current Debian 13 CA bundle at `/etc/ssl/certs/ca-certificates.crt`.
- See [`SECURITY.md`](https://github.com/dgcosenza/synchronet-docker/blob/main/SECURITY.md) for reporting guidelines.

---

## Build Locally

```bash
git clone https://github.com/dgcosenza/synchronet-docker.git
cd synchronet-docker

docker buildx build \
  --platform linux/amd64 \
  --load \
  --build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --build-arg IMAGE_REVISION="$(git rev-parse HEAD)" \
  -t dgcosenza/synchronet:local \
  .
```

| Build Arg | Default | Purpose |
| --- | --- | --- |
| `DEBIAN_BASE` | `debian:trixie-slim` | Base OS image. |
| `SYNCHRONET_COMMIT` | `c20f7377662025b629978cfeade8563a6a7ac97e` | Pinned upstream Synchronet commit (overridden daily by CI). |
| `SYNCHRONET_VERSION` | `3.22a` | Expected version validated against `sbbsdefs.h`. |
| `DENO_VERSION` | `2.9.8` | Official Deno release used by the init script (overridden daily by CI). |
| `DENO_SHA256` | `e890975b...` | Verified SHA-256 checksum of the Deno archive. |
| `BUILD_DATE` | `unknown` | RFC 3339 UTC build timestamp. |
| `IMAGE_REVISION` | `""` | Packaging repository Git SHA. |
| `IMAGE_SOURCE` | `https://github.com/dgcosenza/synchronet-docker` | Source URL for OCI labels. |

---

## Update Policy

[`.github/workflows/daily.yml`](https://github.com/dgcosenza/synchronet-docker/blob/main/.github/workflows/daily.yml) runs automatically every day at **04:45 UTC**, on pushes to `main`, on pull requests (verification only, without pushing), and via `workflow_dispatch`. Every scheduled run executes a seven-step automated pipeline (gated by `.github/workflows/public-check.yml`):

1. **Upstream check:** Resolves the latest Synchronet `master` commit from `SynchronetBBS/sbbs`, validates `VERSION`/`REVISION` in `src/sbbs3/sbbsdefs.h`, queries the latest Deno release via the authenticated GitHub API (with official SHA-256 verification), compares against `versions.json`, and writes an `upstream-changes.md` artifact.
2. **No-cache rebuild:** Rebuilds `linux/amd64` with `--no-cache` on schedule on fully upgraded `debian:trixie-slim` (`apt-get update && apt-get -y upgrade`) and generates an **SPDX SBOM** (`sbom.spdx.json`) and build provenance artifact.
3. **Vulnerability fix and gate:** Scans with **Trivy** (table, JSON, SARIF upload to Code Scanning, and blocking `--ignore-unfixed` gate) and **Grype** (blocking `--only-fixed` gate, severity cutoff `high`), diffs against the previous scan to report resolved CVEs, and retains scan artifacts for 90 days.
4. **Smoke test:** Executes [`tests/smoke.sh`](https://github.com/dgcosenza/synchronet-docker/blob/main/tests/smoke.sh) to verify fresh `/sbbs-data` initialization, non-root `sbbs` (UID/GID `1000`), `cap_net_bind_service`, HTTP webv4 readiness, and a negative closed-port probe.
5. **Publish:** On non-PR builds when registry credentials are configured, pushes `nightly`, `latest`, `<version>`, `<version>-<YYYYMMDD>`, `<version>-<commit>-<YYYYMMDD>`, `sha-<short>`, and immutable `<version>-<commit>` tags to Docker Hub and records the digest.
6. **Automated documentation sync:** Commits updated `versions.json`, the README `Current Versions` block, and a dated `CHANGELOG.md` entry (upstream changes, resolved CVEs, and digest) via `github-actions[bot]` with `[skip ci]` when content changes, then syncs the Docker Hub overview and short description via `peter-evans/dockerhub-description`.
7. **Failure alerting:** If any step fails on `main` or a scheduled run, CI opens or updates a single GitHub issue labeled `ci-failure` with the failing job and run link, and automatically closes it on the next green run.

---

## Design Decisions

- **Debian 13 (`trixie-slim`) multi-stage build:** Synchronet compiles C/C++ components (including vendored cryptlib and SpiderMonkey) cleanly against current Debian 13 glibc and OpenSSL 3. Compilers and `-dev` headers stay strictly in the `build` stage and are excluded from the `runtime` image.
- **Checksum-verified Deno runtime:** Kept solely for drop-in compatibility with the `bbs-io/synchronet-docker` `/sbbs-data` initialization logic (`init.ts`), verified against the official release SHA-256 on every build.
- **120-second healthcheck interval:** Synchronet records a guest login/logout session for every HTTP probe; 120 seconds keeps liveness detection responsive without flooding BBS logs.
- **No `no-new-privileges`:** Required because `sbbs-init` reconciles `/sbbs-data` ownership and `sbbs` uses `cap_net_bind_service` to bind classic BBS ports below 1024.

---

## License

This repository follows a clear packaging-vs-upstream license split:

- **Container packaging, scripts, CI workflows, and documentation (`packaging: MIT`):** Licensed under the [MIT License](https://github.com/dgcosenza/synchronet-docker/blob/main/LICENSE) — copyright **Daniel G. Cosenza from FNX Labs**.
- **Bundled upstream software — Synchronet BBS (`SynchronetBBS/sbbs`, mirror of `gitlab.synchro.net/main/sbbs`) (`upstream: GPL-2.0-or-later`):** Copyright Rob Swindell — licensed under the [GNU General Public License (GPL-2.0-or-later)](https://www.synchro.net/copyright.html), with `XPDEV`, `SMBLIB`, `CIOLIB`, `UIFC`, and `XSDK` under the LGPL. Initialization scripts are adapted from the ISC-licensed [`bbs-io/synchronet-docker`](https://github.com/bbs-io/synchronet-docker).

Full third-party notices are maintained in [`THIRD-PARTY-NOTICES.md`](https://github.com/dgcosenza/synchronet-docker/blob/main/THIRD-PARTY-NOTICES.md). Release history is maintained in [`CHANGELOG.md`](https://github.com/dgcosenza/synchronet-docker/blob/main/CHANGELOG.md).
