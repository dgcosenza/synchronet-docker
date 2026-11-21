# syntax=docker/dockerfile:1.7
ARG DEBIAN_BASE=debian:trixie-slim
FROM ${DEBIAN_BASE} AS runtime-base
ARG DEBIAN_BASE
ARG DENO_VERSION=2.9.8
ARG DENO_SHA256=e890975bc2549807bbcc0b584ffafda72cc7c93349dd99c80483dd784f6c4609
ARG DEBIAN_FRONTEND=noninteractive

ENV TERM=xterm \
    TZ=Etc/UTC \
    DENO_DIR=/sbbs-data/.deno \
    SBBSCTRL=/sbbs/ctrl \
    SBBSEXEC=/sbbs/exec \
    PATH=/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/sbbs/scripts:/sbbs/exec

# Upgrade the current Trixie base at build time, then install current runtime
# libraries and the supported archive/network tools used by Synchronet doors.
RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get install -y --no-install-recommends \
       arj arc ca-certificates curl jq less libarchive-tools libcap2-bin \
       libffi8 libncurses6 libnspr4 libssl3t64 lhasa nano openssh-client \
       passwd procps sudo telnet tzdata unzip util-linux wget zip 7zip unrar-free \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install the current Deno release from its official release archive and verify
# the publisher's SHA-256 checksum. CI updates these build args daily.
RUN set -eux; \
    curl -fsSLo /tmp/deno.zip \
      "https://github.com/denoland/deno/releases/download/v$DENO_VERSION/deno-x86_64-unknown-linux-gnu.zip"; \
    echo "$DENO_SHA256  /tmp/deno.zip" | sha256sum -c -; \
    unzip -q /tmp/deno.zip -d /tmp/deno; \
    install -m 0755 /tmp/deno/deno /usr/local/bin/deno; \
    deno --version; \
    rm -rf /tmp/deno /tmp/deno.zip

RUN groupadd --gid 1000 sbbs \
    && useradd --uid 1000 --gid 1000 --create-home --home-dir /home/sbbs \
       --shell /bin/bash --comment 'Synchronet service account' sbbs \
    && usermod --append --groups sudo sbbs \
    && printf '%s\n' 'sbbs ALL=(ALL) NOPASSWD: ALL' \
       > /etc/sudoers.d/sbbs \
    && chmod 0440 /etc/sudoers.d/sbbs \
    && visudo -cf /etc/sudoers \
    && install -d -o sbbs -g sbbs /sbbs-data

FROM runtime-base AS build
ARG SYNCHRONET_COMMIT=e1a997ca9d009389416e39f5e2c83c239c82103f
ARG SYNCHRONET_VERSION=3.22a
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get install -y --no-install-recommends \
       build-essential git libarchive-dev libffi-dev libncurses-dev \
       libnspr4-dev libssl-dev patch perl pkgconf python3 unzip zlib1g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# GitLab is the canonical upstream; SynchronetBBS/sbbs is its live GitHub
# mirror. Fetch the exact GitLab API-confirmed commit from that mirror.
RUN set -eux; \
    git init /tmp/sbbs; \
    git -C /tmp/sbbs remote add origin https://github.com/SynchronetBBS/sbbs.git; \
    git -C /tmp/sbbs fetch --depth 1 origin "$SYNCHRONET_COMMIT"; \
    git -C /tmp/sbbs checkout --detach FETCH_HEAD; \
    test "$(git -C /tmp/sbbs rev-parse HEAD)" = "$SYNCHRONET_COMMIT"; \
    mkdir -p /sbbs; \
    mv /tmp/sbbs /sbbs/repo; \
    upstream_version=$(sed -n 's/^#define VERSION[[:space:]]*"\([^"]*\)".*/\1/p' /sbbs/repo/src/sbbs3/sbbsdefs.h); \
    upstream_revision=$(sed -n "s/^#define REVISION[[:space:]]*'\([^']*\)'.*/\1/p" /sbbs/repo/src/sbbs3/sbbsdefs.h); \
    test "$upstream_version$upstream_revision" = "$SYNCHRONET_VERSION"

# Build the release binaries from the pinned current source. NO_X omits X11
# tools; NOCAP defers the low-port capability to the final runtime image.
RUN set -eux; \
    cd /sbbs/repo/install; \
    make RELEASE=1 NO_X=1 NOCAP=1 SBBSDIR=/sbbs -f install-sbbs.mk install; \
    make -C /sbbs/repo/src/sbbs3 RELEASE=1 NO_X=1 NOCAP=1 SBBSDIR=/sbbs install

COPY scripts /sbbs/scripts
RUN chmod 0755 /sbbs/scripts/sbbs /sbbs/scripts/sbbs-init /sbbs/scripts/post-build.sh \
    && /sbbs/scripts/post-build.sh

FROM runtime-base AS runtime
ARG BUILD_DATE=unknown
ARG SYNCHRONET_COMMIT=e1a997ca9d009389416e39f5e2c83c239c82103f
ARG SYNCHRONET_VERSION=3.22a
ARG DENO_VERSION=2.9.8

COPY --from=build --chown=0:0 /sbbs /sbbs
COPY --from=build --chown=0:0 /usr/local/bin/deno /usr/local/bin/deno

RUN set -eux; \
    chmod 0755 /sbbs/scripts/sbbs /sbbs/scripts/sbbs-init; \
    chown -R root:root /sbbs; \
    chmod -R go-w /sbbs; \
    setcap cap_net_bind_service=+ep /sbbs/exec/sbbs; \
    getcap /sbbs/exec/sbbs; \
    install -d -m 0750 -o sbbs -g sbbs /sbbs/temp; \
    for exe in sbbs jsexec; do \
      ldd "/sbbs/exec/$exe" > "/tmp/ldd-$exe.txt"; \
      cat "/tmp/ldd-$exe.txt"; \
      ! grep -q 'not found' "/tmp/ldd-$exe.txt"; \
    done; \
    rm -f /tmp/ldd-*.txt; \
    install -d -o sbbs -g sbbs /sbbs-data

WORKDIR /sbbs
USER sbbs:sbbs

EXPOSE 11 17 18 21 22 23 25 64 70 79 110 1123 119 128 143 443 465 513 563 587 993 995 5500 5501 6667 6697 24553 24554 11235 10088

HEALTHCHECK --interval=120s --timeout=10s --start-period=120s --retries=3 \
  CMD curl --fail --silent --show-error --output /dev/null --max-time 10 http://127.0.0.1/

VOLUME ["/sbbs-data"]
CMD ["/sbbs/scripts/sbbs", "syslog"]

LABEL org.opencontainers.image.source="https://github.com/dgcosenza/synchronet-docker" \
      org.opencontainers.image.revision="$SYNCHRONET_COMMIT" \
      org.opencontainers.image.created="$BUILD_DATE" \
      org.opencontainers.image.title="Synchronet BBS on Debian 13" \
      org.opencontainers.image.description="Source-built Synchronet BBS for Debian 13 Trixie, pinned to upstream commit $SYNCHRONET_COMMIT." \
      org.opencontainers.image.version="$SYNCHRONET_VERSION" \
      org.opencontainers.image.licenses="NOASSERTION" \
      org.opencontainers.image.base.name="debian:trixie-slim" \
      org.synchronet.version="$SYNCHRONET_VERSION" \
      org.synchronet.commit="$SYNCHRONET_COMMIT" \
      org.deno.version="$DENO_VERSION"
