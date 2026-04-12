# jsonnet-libs

Jsonnet libraries for Kubernetes.

## Libraries

- [app](app/) - Application deployment utilities (Deployments, StatefulSets, DaemonSets, Services, PVCs, TLS, etc.)
- [chrony](chrony/) - Chrony NTP client/server
- [restic](restic/) - Restic backup CronJobs for Kubernetes workloads
- [tls](tls/) - TLS/cert-manager integration

## Generated CRD libraries

- [nodemanager-libsonnet](gen/nodemanager-libsonnet/)
- [iotcontroller-libsonnet](gen/iotcontroller-libsonnet/)

API docs: [zachfi.github.io/jsonnet-libs](https://zachfi.github.io/jsonnet-libs/)
