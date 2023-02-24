# linkerd-extension-init

A utility for initializing Linkerd extension namespaces after installation.

## Usage

```text
Add metadata to extension namespaces

The added metadata is used by the Linkerd CLI to recognize the extensions
installed in the cluster. Note that this is only required when installing
extensions via Helm.

Usage: linkerd-extension-init [OPTIONS] --extension <EXTENSION> --namespace
<NAMESPACE> --linkerd-namespace <LINKERD_NAMESPACE>

Options: --log-level <LOG_LEVEL> [env: LINKERD_NS_LABELER_LOG_LEVEL=] [default:
info]

      --log-format <LOG_FORMAT> [env: LINKERD_NS_LABELER_LOG_FORMAT=] [default:
      plain]

      --extension <EXTENSION> Extension name (e.g. viz, multicluster, jaeger)

  -n, --namespace <NAMESPACE> Namespace where the extension is installed

      --linkerd-namespace <LINKERD_NAMESPACE> Namespace where the Linkerd
      control-plane is installed

      --prometheus-url <PROMETHEUS_URL> URL of external Prometheus instance, if
      any (only used by the viz extension)

  -h, --help Print help (see a summary with '-h')

  -V, --version Print version
```

## Building

```bash
$ just build <registry> <tag>

# e.g. build and push a multi-arch images in a manifest $
DOCKER_TARGET=multi-arch DOCKER_PUSH=1 just build ghcr.io/linkerd v0.2.0
```
