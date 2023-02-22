FROM --platform=$BUILDPLATFORM ghcr.io/linkerd/dev:v39-rust-musl as builder
ARG BUILD_TYPE="release"
WORKDIR /build
RUN mkdir -p target/bin
COPY . .
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    cargo fetch
ARG TARGETARCH
RUN --mount=type=cache,target=target \
    --mount=type=cache,target=/usr/local/cargo/registry \
    target=$(case "$TARGETARCH" in \
        amd64) echo x86_64-unknown-linux-musl ;; \
        arm64) echo aarch64-unknown-linux-musl ;; \
        arm) echo armv7-unknown-linux-musleabihf ;; \
        *) echo "unsupported architecture: $TARGETARCH" >&2; exit 1 ;; \
    esac) && \
    just-cargo profile=$BUILD_TYPE target=$target build --package=linkerd-extension-init && \
    mv "target/$target/$BUILD_TYPE/linkerd-extension-init" /tmp/

FROM scratch as runtime
COPY --from=builder /tmp/linkerd-extension-init /bin/
ENTRYPOINT ["/bin/linkerd-extension-init"]
