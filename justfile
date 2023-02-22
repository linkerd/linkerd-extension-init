# See https://just.systems/man/en

# By default we compile in development mode mode because it's faster.
rs-build-type := if env_var_or_default("RELEASE", "") == "" { "debug" } else { "release" }

# Overriddes the default Rust toolchain version.
rs-toolchain := ""

rs-features := 'all'

_cargo := "cargo" + if rs-toolchain != "" { " +" + rs-toolchain } else { "" }

archs := 'linux/amd64,linux/arm64,linux/arm/v7'

# Check that the Rust code is formatted correctly.
rs-check-fmt:
    {{ _cargo }} fmt --all -- --check

# Fetch Rust dependencies.
rs-fetch:
    {{ _cargo }} fetch --locked

# Lint Rust code.
rs-clippy:
    {{ _cargo }} clippy --frozen --workspace --all-targets --no-deps {{ _features }} {{ _fmt }}

# Generate Rust documentation.
rs-doc *flags:
    {{ _cargo }} doc --frozen \
        {{ if rs-build-type == "release" { "--release" } else { "" } }} \
        {{ _features }} \
        {{ flags }}

rs-test-build:
    {{ _cargo-test }} --no-run --frozen \
        {{ _features }} \
        {{ _fmt }}

# Run Rust unit tests
rs-test *flags:
    {{ _cargo-test }} --frozen \
        {{ if rs-build-type == "release" { "--release" } else { "" } }} \
        {{ _features }} \
        {{ flags }}

build:
    {{ _cargo }} build

build-image registry tag:
    #!/usr/bin/env bash
    set -euo pipefail

    DOCKER_BUILDKIT_CACHE=${DOCKER_BUILDKIT_CACHE:-}
    DOCKER_TARGET=${DOCKER_TARGET:-}
    DOCKER_PUSH=${DOCKER_PUSH:-}

    cache_params=""

    if [ "$DOCKER_BUILDKIT_CACHE" ]; then
      cache_params="--cache-from type=local,src=${DOCKER_BUILDKIT_CACHE} --cache-to type=local,dest=${DOCKER_BUILDKIT_CACHE},mode=max"
    fi

    output_params="--load"
    if [ "$DOCKER_TARGET" = 'multi-arch' ]; then
      output_params="--platform {{ archs }}"
      if [ "$DOCKER_PUSH" ]; then
        output_params+=" --push"
      else
        echo 'Error: env DOCKER_PUSH=1 is missing'
        echo 'When building the multi-arch images it is required to push the images to the registry'
        echo 'See https://github.com/docker/buildx/issues/59 for more details'
        exit 1
      fi
    fi

    docker buildx build . $cache_params $output_params -t "{{ registry }}/linkerd-extension-init:{{ tag }}"

# This tests that some namespace gets annotated as expected. The helm-upgrade
# integration test in the linkerd2 repo tests this in the context of the
# namespace-metadata job.
integration-test:
    #!/usr/bin/env bash
    set -euo pipefail

    scurl -sL https://run.linkerd.io/install | sh
    export PATH=$PATH:/home/runner/.linkerd2/bin

    just-k3d create
    just-k3d kubectl create ns foobar

    linkerd install --crds | just-k3d kubectl apply -f -
    linkerd install | just-k3d kubectl apply -f -
    linkerd check

    {{ _cargo }} run -- -n foobar --linkerd-namespace linkerd --extension extname --prometheus-url promurl

    expected_annotations='{"viz.linkerd.io/external-prometheus":"promurl"}'
    expected_labels='{"kubernetes.io/metadata.name":"foobar","linkerd.io/extension":"extname","pod-security.kubernetes.io/enforce":"privileged"}'
    ns=$(just-k3d kubectl get ns foobar -ojson)
    ann=$(echo $ns | jq .metadata.annotations | tr -d '[:space:]')
    labels=$(echo $ns | jq .metadata.labels | tr -d '[:space:]')
    if [[ "$ann" != "$expected_annotations" || "$labels" != "$expected_labels" ]]; then
      echo "Metadata didn't match"
      echo $ns
      exit 1
    fi

# If we're running in github actions and cargo-action-fmt is installed, then add
# a command suffix that formats errors.
_fmt := if env_var_or_default("GITHUB_ACTIONS", "") != "true" { "" } else {
    ```
    if command -v cargo-action-fmt >/dev/null 2>&1; then
        echo "--message-format=json | cargo-action-fmt"
    fi
    ```
}

# Configures which features to enable when invoking cargo commands.
_features := if rs-features == "all" {
        "--all-features"
    } else if rs-features != "" {
        "--no-default-features --features=" + rs-features
    } else { "" }

# Use cargo-nextest if it is available. It may not be available when running
# outside of the devcontainer.
_cargo-test := _cargo + ```
    if command -v cargo-nextest >/dev/null 2>&1 ; then
        echo " nextest run"
    else
        echo " test"
    fi
    ```
