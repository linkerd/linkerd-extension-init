FROM --platform=$BUILDPLATFORM ghcr.io/linkerd/dev:v43-rust-musl as builder
ARG BUILD_TYPE="release"
WORKDIR /build
RUN mkdir -p target/bin
COPY . .
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    cargo fetch
ARG TARGETARCH
# Install cross compiler toolchains
RUN case "$TARGETARCH" in \
        amd64) true ;; \
        arm64) apt-get -y update && apt-get install --no-install-recommends -y gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu ;; \
    esac && rm -rf /var/lib/apt/lists/*

ENV AWS_LC_SYS_CFLAGS_aarch64_unknown_linux_musl='-fuse-ld=/usr/aarch64-linux-gnu/bin/ld'
RUN --mount=type=cache,target=target \
    --mount=type=cache,target=/usr/local/cargo/registry \
    target=$(case "$TARGETARCH" in \
        amd64) echo x86_64-unknown-linux-musl ;; \
        arm64) echo aarch64-unknown-linux-musl ;; \
        *) echo "unsupported architecture: $TARGETARCH" >&2; exit 1 ;; \
    esac) && \
    just-cargo profile=$BUILD_TYPE target=$target build --package=linkerd-extension-init && \
    mv "target/$target/$BUILD_TYPE/linkerd-extension-init" /tmp/

FROM scratch as runtime
COPY --from=builder /tmp/linkerd-extension-init /bin/
ENTRYPOINT ["/bin/linkerd-extension-init"]
