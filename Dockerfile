# syntax=docker/dockerfile:1.7
ARG DEBIAN_BASE=debian:13.8-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0
FROM ${DEBIAN_BASE} AS runtime-base
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG TARGETARCH
ARG DENO_VERSION=2.9.8
ARG DENO_SHA256_AMD64=e890975bc2549807bbcc0b584ffafda72cc7c93349dd99c80483dd784f6c4609
ARG DENO_SHA256_ARM64=d49596c20b9788cf8f5d8ddf644103d4bde56ed239753f0bdb92ba9361d51905
ARG DEBIAN_FRONTEND=noninteractive

ENV TERM=xterm \
    TZ=Etc/UTC \
    DENO_DIR=/sbbs-data/.deno \
    SBBSCTRL=/sbbs/ctrl \
    SBBSEXEC=/sbbs/exec \
    PATH=/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/sbbs/scripts:/sbbs/exec

# Upgrade the current Trixie base, install runtime libraries and archive/network
# tools used by Synchronet doors, install SHA-256-verified Deno for TARGETARCH,
# and configure the non-root sbbs service account in a single layer for Dive efficiency.
RUN set -eux; \
    apt-get update; \
    apt-get -y upgrade; \
    apt-get install -y --no-install-recommends \
      arj arc ca-certificates curl jq less libarchive-tools libcap2-bin \
      libffi8 libncurses6 libnspr4 libssl3t64 lhasa nano openssh-client \
      passwd procps sudo telnet tzdata unzip util-linux wget zip 7zip unrar-free; \
    case "${TARGETARCH:-amd64}" in \
      amd64) DENO_ARCH="x86_64"; DENO_SHA256="${DENO_SHA256_AMD64}" ;; \
      arm64) DENO_ARCH="aarch64"; DENO_SHA256="${DENO_SHA256_ARM64}" ;; \
      *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    curl -fsSLo /tmp/deno.zip \
      "https://github.com/denoland/deno/releases/download/v${DENO_VERSION}/deno-${DENO_ARCH}-unknown-linux-gnu.zip"; \
    echo "${DENO_SHA256}  /tmp/deno.zip" | sha256sum -c -; \
    unzip -q /tmp/deno.zip -d /tmp/deno; \
    install -m 0755 /tmp/deno/deno /usr/local/bin/deno; \
    deno --version; \
    groupadd --gid 1000 sbbs; \
    useradd --uid 1000 --gid 1000 --create-home --home-dir /home/sbbs \
      --shell /bin/bash --comment 'Synchronet service account' sbbs; \
    usermod --append --groups sudo sbbs; \
    printf '%s\n' 'sbbs ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/sbbs; \
    chmod 0440 /etc/sudoers.d/sbbs; \
    visudo -cf /etc/sudoers; \
    install -d -o sbbs -g sbbs /sbbs-data; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

FROM runtime-base AS build
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG SYNCHRONET_COMMIT=c20f7377662025b629978cfeade8563a6a7ac97e
ARG SYNCHRONET_VERSION=3.22a
ARG DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    apt-get update; \
    apt-get -y upgrade; \
    apt-get install -y --no-install-recommends \
      build-essential git libarchive-dev libffi-dev libncurses-dev \
      libnspr4-dev libssl-dev patch perl pkgconf python3 unzip zlib1g-dev; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*; \
    git init /tmp/sbbs; \
    git -C /tmp/sbbs remote add origin https://github.com/SynchronetBBS/sbbs.git; \
    git -C /tmp/sbbs fetch --depth 1 origin "${SYNCHRONET_COMMIT}"; \
    git -C /tmp/sbbs checkout --detach FETCH_HEAD; \
    test "$(git -C /tmp/sbbs rev-parse HEAD)" = "${SYNCHRONET_COMMIT}"; \
    mkdir -p /sbbs; \
    mv /tmp/sbbs /sbbs/repo; \
    upstream_version="$(sed -n 's/^#define VERSION[[:space:]]*"\([^"]*\)".*/\1/p' /sbbs/repo/src/sbbs3/sbbsdefs.h)"; \
    upstream_revision="$(sed -n "s/^#define REVISION[[:space:]]*'\([^']*\)'.*/\1/p" /sbbs/repo/src/sbbs3/sbbsdefs.h)"; \
    test "${upstream_version}${upstream_revision}" = "${SYNCHRONET_VERSION}"

# Build the release binaries from the pinned current source. NO_X omits X11
# tools; NOCAP defers the low-port capability to the final runtime image.
WORKDIR /sbbs/repo/install
RUN set -eux; \
    make RELEASE=1 NO_X=1 NOCAP=1 SBBSDIR=/sbbs -f install-sbbs.mk install; \
    make -C /sbbs/repo/src/sbbs3 RELEASE=1 NO_X=1 NOCAP=1 SBBSDIR=/sbbs install

COPY --chmod=0755 scripts /sbbs/scripts
RUN /sbbs/scripts/post-build.sh

FROM runtime-base AS runtime
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG BUILD_DATE=unknown
ARG SYNCHRONET_COMMIT=c20f7377662025b629978cfeade8563a6a7ac97e
ARG SYNCHRONET_VERSION=3.22a
ARG DENO_VERSION=2.9.8
ARG IMAGE_REVISION=""
ARG IMAGE_SOURCE="https://github.com/dgcosenza/synchronet-docker"

COPY --from=build --chown=0:0 /sbbs /sbbs

RUN set -eux; \
    chmod 0755 /sbbs/scripts/sbbs /sbbs/scripts/sbbs-init; \
    chmod -R go-w /sbbs; \
    setcap cap_net_bind_service=+ep /sbbs/exec/sbbs; \
    getcap /sbbs/exec/sbbs; \
    install -d -m 0750 -o sbbs -g sbbs /sbbs/temp; \
    for exe in sbbs jsexec; do \
      ldd "/sbbs/exec/${exe}" > "/tmp/ldd-${exe}.txt"; \
      cat "/tmp/ldd-${exe}.txt"; \
      if grep -q 'not found' "/tmp/ldd-${exe}.txt"; then exit 1; fi; \
    done; \
    rm -f /tmp/ldd-*.txt; \
    install -d -o sbbs -g sbbs /sbbs-data

WORKDIR /sbbs
USER sbbs:sbbs

EXPOSE 11 17 18 21 22 23 25 64 70 79 110 1123 119 128 143 443 465 513 563 587 993 995 5500 5501 6667 6697 24553 24554 11235 10088

HEALTHCHECK --interval=120s --timeout=10s --start-period=120s --retries=3 \
  CMD ["curl", "--fail", "--silent", "--show-error", "--output", "/dev/null", "--max-time", "10", "http://127.0.0.1/"]

VOLUME ["/sbbs-data"]
CMD ["/sbbs/scripts/sbbs", "syslog"]

LABEL org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.url="https://hub.docker.com/r/dgcosenza/synchronet" \
      org.opencontainers.image.documentation="${IMAGE_SOURCE}#readme" \
      org.opencontainers.image.revision="${IMAGE_REVISION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.title="Synchronet BBS on Debian 13" \
      org.opencontainers.image.description="Source-built Synchronet BBS for Debian 13 (trixie, linux/amd64), pinned to upstream commit ${SYNCHRONET_COMMIT}, maintained by Daniel G. Cosenza from FNX Labs." \
      org.opencontainers.image.version="${SYNCHRONET_VERSION}" \
      org.opencontainers.image.licenses="GPL-2.0-or-later AND MIT" \
      org.opencontainers.image.authors="Daniel G. Cosenza from FNX Labs" \
      org.opencontainers.image.vendor="Daniel G. Cosenza from FNX Labs" \
      org.opencontainers.image.base.name="debian:13.8-slim" \
      io.github.dgcosenza.synchronet.upstream_version="${SYNCHRONET_VERSION}" \
      io.github.dgcosenza.synchronet.upstream_commit="${SYNCHRONET_COMMIT}" \
      io.github.dgcosenza.synchronet.deno_version="${DENO_VERSION}" \
      org.synchronet.version="${SYNCHRONET_VERSION}" \
      org.synchronet.commit="${SYNCHRONET_COMMIT}" \
      org.deno.version="${DENO_VERSION}"
