<!-- markdownlint-disable-file MD041 -->
<!-- Appended to PROMPT.md under "## Repository extension (supplied)". -->

## Critical paths in this repo

- **Kubernetes clients.** `kube`, `k8s-openapi`, and `kubert`, which patch the
  extension namespace's metadata.
- **JSON patch and YAML.** `json-patch` and `jsonptr`, which build the
  namespace patch, and `serde_yaml`, which reads the `linkerd-config` values.
- **TLS.** `rustls` with the `aws-lc-rs` provider, used by the Kubernetes
  client.
- **Build and test base.** The Rust toolchain and `ghcr.io/linkerd/dev`.
