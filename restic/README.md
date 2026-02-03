# restic.libsonnet

Restic backup support for Kubernetes workloads. Use [restic](https://restic.net/) to back up workload volumes on a schedule via a CronJob that runs on the same node as the workload (pod affinity).

## Preferred: resticForApp(app, opts)

Build backup at **top level** from the app and explicit opts. No backup state on the app.

```jsonnet
local restic = import 'github.com/zachfi/jsonnet-libs/restic/restic.libsonnet';

// Define what to back up (e.g. config PVC only, not NFS).
local ldap_backup_targets = [
  { volumeName: 'ldap-data', mountPath: '/bitnami/openldap' },
];

{
  ldap: app.new('ldap', images.ldap, namespace='auth')
    + app.withStatefulSet()
    + app.withLocalDataMount('/bitnami/openldap', size='200Mi', ...)
    + app.withCertificate(tld='cluster.local', mountPath='/ldap/tls')  // or your cluster DNS domain
    + ...,

  // Caller owns the Secret (or use ExternalSecret from Vault).
  ldap_restic_secret: k.core.v1.secret.new('ldap-restic-config', {
    accessKey: std.base64(data.restic.accessKey),
    secretKey: std.base64(data.restic.secretKey),
    resticPassword: std.base64(data.restic.resticPassword),
  }) + k.core.v1.secret.metadata.withNamespace(namespace),

  ldap_backup: restic.resticForApp(self.ldap, {
    bucketURL: data.restic.bucketURL,
    secretRefName: 'ldap-restic-config',
    backupTargets: ldap_backup_targets,
    schedule: '0 */6 * * *',
    ttl: 86400,
    image: images.restic,
    cert: { mountPath: '/ldap/tls', volumeName: 'ldap-tls' },  // workload TLS for S3
    fsPermissions: { uid: 1001, gid: 1001 },
    nodeSelector: { 'workload/ldap': 'true' },
    resources: { requests: { memory: '256Mi' }, limits: { memory: '1Gi' } },
  }),
}
```

Include in your manifest: the restic Secret (or ExternalSecret) from the app, `ldap_backup.scriptsConfigMap`, `ldap_backup.cron`.

### opts

| Field | Required | Description |
|-------|----------|-------------|
| bucketURL | yes | S3 bucket URL (e.g. `s3:https://s3.example:9000/bucket`) |
| secretRefName | no | Name of existing Secret (default `appName-restic-config`). Caller must create or sync it. |
| secretKeys | no | Map of logical keys to secret key names: `{ accessKey, secretKey, resticPassword }`. Override when your secret uses different names (e.g. from Vault). |
| backupTargets | yes | `[ { volumeName, mountPath } ]` — only these volumes are backed up |
| schedule | yes | Cron schedule (e.g. `'0 */6 * * *'`) |
| ttl | no | Job TTL seconds (default 86400) |
| image | no | Restic image |
| resources | no | `{ requests: {}, limits: {} }` for the restic container |
| caCertPath | no | Path to CA cert for S3 (e.g. `/tls/ca.crt`) when not using workload cert |
| cert | no | `{ mountPath, volumeName }` when using workload TLS for S3 (mount path + secret volume name) |
| fsPermissions | no | `{ uid, gid }` for CronJob pod securityContext |
| nodeSelector | no | Node selector for the CronJob pod |

Use **cert** when the app uses `withCertificate` and the cert is mounted at a custom path (e.g. `/ldap/tls`). Use **caCertPath** when S3 has a private CA and you’re not using the workload cert.

## Dependencies

- `k.libsonnet` (Kubernetes Jsonnet lib, e.g. `github.com/jsonnet-libs/k8s-libsonnet/1.33`)
- `github.com/zachfi/jsonnet-libs/tls/util.libsonnet` (optional; for restic lib’s `withCertificate` when composing manually)

## Secrets (caller-owned)

The restic library does not create the S3/restic Secret. You must provide a Secret (or ExternalSecret) in the same namespace with keys: **accessKey**, **secretKey**, **resticPassword**. Create it in your app or use an ExternalSecret (e.g. from Vault). Pass `secretRefName` to resticForApp and optionally `secretKeys` if your secret uses different key names. Repo URL is `bucketURL/namespace/appName` (e.g. `s3:https://.../pvbackups/auth/ldap`).

## Lower-level usage

You can still build a restic backup by hand with `restic.new(appName, namespace)` and mixins: `withS3Bucket`, `withPVC`, `withBackupCron`, `withCronPodAffinity`, `withResticCacert`, `withVolume`/`withVolumeMount`, `withFsPermissions`, `withNodeSelector`. Use this when you need a custom flow; otherwise prefer `resticForApp`.
