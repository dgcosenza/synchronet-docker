# Synchronet BBS for Debian 13

## Overview

This repository builds and maintains a source-built Synchronet BBS container on Debian 13 Trixie. Daniel G. Cosenza maintains the image under the dgcosenza account. The image tracks current Synchronet upstream master, builds the commit recorded in its OCI labels, upgrades Debian packages during each build, and uses the current checksum-verified Deno release.

Synchronet is developed at [gitlab.synchro.net/main/sbbs](https://gitlab.synchro.net/main/sbbs). The build fetches the matching commit from the maintained [SynchronetBBS GitHub mirror](https://github.com/SynchronetBBS/sbbs) because unauthenticated GitLab smart-HTTP refs are not consistently available to container builders. The packaging modernizes the Debian 11 based bbsio/synchronet recipe; it is independently maintained and is not an official Synchronet or BBS-IO image.

The persistent data mount follows the /sbbs-data layout used by bbsio/synchronet. This release is built from Synchronet 3.22a source and is intended to read 3.22a data. Test upgrades on a copy first.

## Tags and versioning

- dgcosenza/synchronet:3.22a-6bd53d6 identifies Synchronet 3.22a and source commit 6bd53d6b60c4edaddead52a36be2c5479f1aeafb. Version-and-commit tags are immutable after publication.
- dgcosenza/synchronet:nightly moves to the latest upstream master commit that builds, passes the image scan, and is published by CI or the approved manual Server workflow.
- dgcosenza/synchronet:latest aliases the same current Debian 13 and current Synchronet build as nightly. It is never a frozen historical release.
- Pin production deployments by registry digest after review. A moving tag is a discovery channel, not a deployment pin.

The initial build uses Debian 13.7 (debian:trixie-slim) and upgrades all available packages at build time. The version-and-commit tag records the Synchronet source revision; the complete image digest records the exact image, including its Debian packages.

## Supported architecture

The published image targets linux/amd64. Other architectures are not built or tested by this repository.

## Quick start

Create a data directory and make it writable by the container service account (UID/GID 1000):

    mkdir -p "$HOME/synchronet/data"
    sudo chown -R 1000:1000 "$HOME/synchronet/data"
    cd "$HOME/synchronet"

### Docker run

This example keeps services on loopback and maps SSH, Telnet, and webv4 to non-privileged host ports. Add other mappings only after reviewing protocol and firewall exposure.

    docker run -d --name synchronet --restart unless-stopped --env TZ=Etc/UTC --publish 127.0.0.1:2323:22 --publish 127.0.0.1:2324:23 --publish 127.0.0.1:8080:80 --volume "$PWD/data:/sbbs-data" dgcosenza/synchronet:nightly

Open the web interface at http://127.0.0.1:8080/. Connect to SSH on port 2323 or Telnet on port 2324. Synchronet initializes missing data directories on the first run.

### Docker Compose

Save this complete example as compose.yaml in the directory containing data/:

    services:
      bbs:
        image: dgcosenza/synchronet:nightly
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

Start with docker compose up -d. Inspect with docker compose ps and docker compose logs --tail=100 bbs.

## Environment variables

| Variable | Image default | Purpose |
| --- | --- | --- |
| TZ | Etc/UTC | System timezone used by processes and logs. Set an installed IANA timezone such as America/Argentina/Cordoba when needed. |
| TERM | xterm | Terminal type for console tools. |
| DENO_DIR | /sbbs-data/.deno | Persistent Deno cache and generated module directory. Keep it inside the data volume. |
| SBBSCTRL | /sbbs/ctrl | Synchronet control directory inside the container; it links to /sbbs-data/ctrl. |
| SBBSEXEC | /sbbs/exec | Synchronet executable directory inside the container. |
| PATH | /usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/sbbs/scripts:/sbbs/exec | Runtime command search path. Do not replace it without preserving system and Synchronet paths. |

Synchronet configuration is stored in the mounted control directory; there are no image-specific passwords or required application environment variables. Do not put sysop credentials in an image layer or public repository.

Build-time arguments are DEBIAN_BASE (default debian:trixie-slim), SYNCHRONET_COMMIT (exact upstream commit), SYNCHRONET_VERSION (version string validated against that commit), DENO_VERSION and DENO_SHA256 (verified Deno release archive), and BUILD_DATE (OCI metadata). They do not configure a running BBS.

## Ports and network exposure

Ports listen inside the container only when enabled by ctrl/services.ini and ctrl/sbbs.ini. Docker publishes only ports listed in ports:. The production mapping used for the source data this image was prepared against is:

| Host port | Container port | Service | Exposure notes |
| ---: | ---: | --- | --- |
| 23 | 23 | Telnet | Plaintext; keep off untrusted networks. |
| 2323 | 22 | Synchronet SSH | Host uses 2323 to avoid replacing host SSH. |
| 21 | 21 | FTP | Plaintext; keep off untrusted networks. |
| 513 | 513 | Rlogin | Legacy plaintext protocol. |
| 1123 | 1123 | Web terminal WebSocket | Existing Nginx virtual host fronts this service. |
| 6667 | 6667 | IRC | Publish only when the IRC service is enabled. |
| 24554 | 24554 | BinkP | FidoNet mail transfer. |
| 25 | 25 | SMTP | Mail service. |
| 110 | 110 | POP3 | Plaintext unless separately protected. |
| 143 | 143 | IMAP | Plaintext unless separately protected. |
| 465 | 465 | SMTP over TLS | Encrypted mail submission. |
| 587 | 587 | SMTP submission | Use the configured TLS policy. |
| 993 | 993 | IMAP over TLS | Encrypted mail access. |
| 995 | 995 | POP3 over TLS | Encrypted mail access. |
| 70 | 70 | Gopher | Optional legacy service. |
| 79 | 79 | Finger | Optional legacy service. |
| 119 | 119 | NNTP | Plaintext unless separately protected. |
| 563 | 563 | NNTP over TLS | Encrypted news access. |
| 17 | 17 | QOTD | Optional legacy service. |
| 18 | 18 | MSP | Optional legacy service. |
| 11 | 11 | ActiveUser | Optional Synchronet status service. |
| 5500 | 5500 | Hotline | Optional service. |
| 5501 | 5501 | Hotline transfer | Optional service. |
| 24553 | 24553 | BinkP over TLS | Encrypted FidoNet transfer. |
| 11235 | 11235 | Secure web terminal | WebSocket TLS service. |
| 10088 | 10088 | JSON API | Keep on trusted networks and behind access controls. |

The internal HTTP service on port 80 is used by the image healthcheck and can serve webv4. Port 443 is available for a separately configured HTTPS service. PETSCII ports 64 and 128 are intentionally not published in the production stack. Do not publish every listed port automatically: enable and publish only the services the BBS needs.

On the home Server, a host DOCKER-USER firewall rule blocks plaintext services from the WAN. This image does not change host firewall, Nginx, DNS, tunnel, or public exposure rules. Recreate equivalent firewall controls on other hosts before publishing ports.

## Data volume and layout

Mount one persistent directory at /sbbs-data. The image initializes missing directories from build defaults, links them into /sbbs, saves image defaults under backup/defaults, and runs upstream update.js when its recorded Synchronet version changes.

| Path under /sbbs-data | Contents |
| --- | --- |
| backup/ | Backups and backup/defaults/, the image's shipped defaults. |
| ctrl/ | sbbs.ini, services.ini, modopts.ini, text configuration, and BBS settings. |
| data/ | User records, message bases, file metadata, and other live BBS data. |
| .deno/ | Deno cache and generated files. |
| fido/ | FidoNet configuration and queue data. |
| mods/ | Local scripts and customizations. |
| nodes/ | Persistent node directories such as node1, node2, and later nodes. |
| text/ | Menus and BBS text files. |
| web/ | Web content served by webv4. |
| xtrn/ | External programs and door configuration. |

Keep all data mounted when replacing the container. The container runs as sbbs UID/GID 1000; host bind-mounted data should be owned by UID/GID 1000. Never run a trial container against a directory used by a live Synchronet process.

The host syslog socket can optionally be mounted read-write at /dev/log when the host is configured to receive Synchronet syslog messages. The default command is ["/sbbs/scripts/sbbs", "syslog"].

## Configuration

Edit persistent configuration in data/ctrl/ on the host:

- sbbs.ini controls the Synchronet server and interfaces.
- services.ini enables services and selects their ports.
- modopts.ini holds module options, including webv4 behavior.

The image ships a container-compatible default interface and web path. The initializer does not overwrite an existing ctrl/sbbs.ini; use Synchronet configuration tools or edit persistent files deliberately. Keep a copy of ctrl/ before changing settings. For a reverse proxy, attach only the BBS and proxy to a private shared network, and keep Docker's published ports and host firewall aligned.

## Migration from bbsio/synchronet

This image preserves the /sbbs-data layout and is designed for the live 3.22a data line. Stop the old container and make a complete cold copy of the data before testing. Never mount the same data directory into both images.

The old bbsio/synchronet:latest tag is frozen on Synchronet 3.19c (April 2023). That release can spin at 100% CPU while idle in sbbs/termOutput. Do not use that tag as an upgrade source or destination. The live 3.22a nightly line avoids that idle-loop regression. Do not downgrade live data to 3.21e or older.

Safe migration sequence:

1. Stop the existing BBS service.
2. Copy the entire /sbbs-data tree, including .deno, ctrl, data, fido, mods, nodes, text, web, and xtrn.
3. Start a side-by-side container using the copied tree, loopback-only host mappings, and unused host ports.
4. Check health, logs, login menu, enabled protocols, data version, and idle CPU.
5. Only after those checks pass, arrange rollback and update the live Compose service to the reviewed image digest.
6. Keep the previous image digest, Compose files, and original data backup until the new service has been stable.

Inspect the registry digest and pin it in Compose before production deployment. Nightly and latest may move after upstream or Debian updates.

## Backup and restore

For a consistent filesystem backup, stop the BBS service first. From the directory containing compose.yaml and data/:

    docker compose stop bbs
    tar --numeric-owner --acls --xattrs -czf "../synchronet-data-$(date -u +%Y%m%dT%H%M%SZ).tar.gz" data
    docker compose start bbs

Store backups off-host and test restores. To restore a selected archive, stop the service, preserve the current directory, extract the archive, restore ownership, then restart:

    docker compose down
    mv data data.before-restore
    mkdir data
    archive="$(ls -1t ../synchronet-data-*.tar.gz | head -n1)"
    tar --numeric-owner --acls --xattrs -xzf "$archive" -C data
    sudo chown -R 1000:1000 data
    docker compose up -d

The restore example selects the newest matching archive; choose another file explicitly if that is not the intended backup. Retain the original directory until the restored BBS is verified.

## Security

- The main process runs as unprivileged sbbs (UID/GID 1000). The data directory must be writable by that account.
- The image grants sbbs passwordless sudo for initialization and low-port compatibility and gives the Synchronet executable cap_net_bind_service. Do not add Docker's no-new-privileges option to the live service: it prevents the required privilege transition and has caused low-port startup failures. Do not set security_opt: no-new-privileges:true.
- Telnet, FTP, Rlogin, and some mail/news services may transmit credentials or content in plaintext. Use encrypted protocols where configured and preserve host-side WAN firewall blocks.
- Synchronet syslog output can feed the host fail2ban jail when /dev/log is mounted and the host routes the synchronet identifier. Fail2ban and firewall rules are host responsibilities.
- The image includes Debian's CA bundle at /etc/ssl/certs/ca-certificates.crt. If a host has a documented local CA-store mitigation, preserve its read-only CA mounts and verify outbound TLS before removing them.
- Do not put SYSOP-CREDENTIALS, Docker Hub credentials, or other secrets in an image, Compose file, CI logs, or public repository.
- Apply resource limits and host network policy appropriate to the deployment. The sample Compose file binds to loopback.

## Healthcheck

The image checks http://127.0.0.1/ with curl every 120 seconds, allows a 120-second startup period, and fails after three unsuccessful checks. The check treats HTTP 2xx and 3xx responses as healthy. Compose can override it, but should continue probing webv4 over HTTP; /dev/tcp shell probes are not supported.

## Build from source

The build targets linux/amd64. It uses debian:trixie-slim, upgrades packages at build time, verifies the Deno archive SHA-256, and compiles the exact Synchronet commit passed as SYNCHRONET_COMMIT.

    docker buildx build --platform linux/amd64 --load --build-arg SYNCHRONET_COMMIT=6bd53d6b60c4edaddead52a36be2c5479f1aeafb --build-arg SYNCHRONET_VERSION=3.22a --build-arg DENO_VERSION=2.9.8 --build-arg DENO_SHA256=e890975bc2549807bbcc0b584ffafda72cc7c93349dd99c80483dd784f6c4609 --build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" --tag dgcosenza/synchronet:3.22a-6bd53d6 .

The build stage installs current Debian compiler and upstream prerequisites, including GNU make, GCC/G++, libarchive, ncurses, NSPR, OpenSSL development files, Perl, Python 3, patch, and pkgconf. Synchronet builds vendored cryptlib and SpiderMonkey/libmozjs from the pinned upstream tree. The final stage contains runtime libraries and tools, not the compiler toolchain. Debian packages and Deno can change between builds; use the image digest to identify an exact published artifact.

## Daily maintenance and CI

The public repository's GitHub Actions workflow runs daily and on manual dispatch. Each run polls Synchronet master, resolves the current version from source, fetches the current Deno release, rebuilds on the floating Debian Trixie base with apt-get upgrade, and scans with Trivy. A fixable critical or high vulnerability fails the scan and prevents publication.

The workflow builds and scans even when Docker Hub credentials are absent. Its push step requires the GitHub Actions secrets DOCKERHUB_USERNAME and DOCKERHUB_TOKEN; Dani must create a Docker Hub access token and add those secrets before unattended Hub publishing can start. The Server's existing Docker Hub login is reserved for approved manual pushes and is never copied to GitHub.

For Server deployments, keep the moving tag paired with its immutable registry digest so the fleet helpers can detect upstream movement without running an unpinned image. To establish the initial pin, pull `dgcosenza/synchronet:nightly`, read its manifest digest with `docker image inspect dgcosenza/synchronet:nightly --format '{{index .RepoDigests 0}}'`, then set the Compose image to `dgcosenza/synchronet:nightly@sha256:<manifest-digest>`. Use the service's Compose name with `docker compose pull <service>` and `docker compose up -d --no-deps <service>` when applying that exact digest.

The fleet's weekly `/opt/fnxlabs/bin/docker-tag-check.sh` compares pinned images with their floating tags and reports movement. After reviewing and testing a new Synchronet image and its data compatibility, promote the BBS container with `/opt/fnxlabs/bin/docker-tag-promote.sh bbs`; the helper backs up the Compose file, updates its digest pin, checks the project, and rolls back if the promotion fails. Do not deploy an unpinned moving tag, add Watchtower, or change the existing `update-all` hook. The home Server's `update-all.timer` runs at 01:00 ART; do not interrupt an active update.

## Troubleshooting

- Container exits while binding low ports: confirm the service is not configured with no-new-privileges, check getcap /sbbs/exec/sbbs, and inspect Synchronet startup logs.
- Permission denied under /sbbs-data: make the host directory and its contents UID/GID 1000, then restart. Avoid world-writable permissions.
- Healthcheck is unhealthy: verify the web service is enabled, curl http://127.0.0.1/ returns 2xx/3xx inside the container, and inspect docker logs.
- Upgrade or version error: stop the new container, preserve its data copy and logs, and restore the pre-upgrade data if needed. Do not test migrations against the only live copy.
- High idle CPU: confirm the image is 3.22a or newer. Do not use the frozen bbsio/synchronet:latest 3.19c image.
- TLS trust failures: verify the system CA file and any read-only host CA override; do not remove an existing mitigation until outbound TLS checks pass.
- Service bind errors: compare enabled ports in ctrl/services.ini with container ports and host mappings. Confirm that another process is not already using the host port.

## License and credits

Synchronet Version 3 is copyrighted by Rob Swindell. Its components are covered by the GNU GPL, with XPDEV, SMBLIB, CIOLIB, UIFC, and XSDK under the LGPL; see the [official Synchronet copyright notice](https://www.synchro.net/copyright.html) and the license files in the pinned source tree. Synchronet includes vendored cryptlib and SpiderMonkey/libmozjs components; their notices remain in upstream source.

The build adapts the ISC-licensed bbs-io/synchronet-docker recipe and initialization behavior. Its copyright and permission notice is retained in THIRD-PARTY-NOTICES.md. Debian packages and Deno are distributed under their respective upstream licenses. This repository does not claim ownership of Synchronet or its third-party components.

## Changelog

- 2026-11-20: Initial Debian 13 image, built from Synchronet 3.22a commit 6bd53d6b60c4edaddead52a36be2c5479f1aeafb; uses Debian Trixie 13.7, Deno 2.9.8, a multi-stage source build, UID/GID 1000 runtime, webv4 healthcheck, and digest-based release policy.
