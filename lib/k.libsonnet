// Re-export vendored k8s-libsonnet 1.33 so that import 'k.libsonnet' resolves
// when this repo is on the jpath (e.g. -J lib -J . or Tanka env with lib/k.libsonnet).
// Requires: jb install (github.com/jsonnet-libs/k8s-libsonnet 1.33).
import 'github.com/jsonnet-libs/k8s-libsonnet/1.33/main.libsonnet'
