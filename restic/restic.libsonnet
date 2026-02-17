// Restic backup/restore support for Kubernetes workloads.
//
// Preferred: resticForApp(app, opts) at top level. Pass the app and explicit
// opts (bucketURL, secretRefName, backupTargets: [{ volumeName, mountPath }],
// schedule, cert or caCertPath for TLS, etc.). The Secret must exist (caller
// creates it or syncs via ExternalSecret); the library only references it.
// Include in manifest: result.scriptsConfigMap, result.cron (and the Secret
// or ExternalSecret from the app).
//
// Lower-level: restic.new(appName, namespace) then withS3Bucket, withPVC,
// withBackupCron, withCronPodAffinity, etc. for custom composition.
//
{
  local k = import 'k.libsonnet',

  local configMap = k.core.v1.configMap,
  local container = k.core.v1.container,
  local cronJob = k.batch.v1.cronJob,
  local envVar = k.core.v1.envVar,
  local job = k.batch.v1.job,
  local podAffinityTerm = k.core.v1.podAffinityTerm,
  local volume = k.core.v1.volume,
  local volumeMount = k.core.v1.volumeMount,

  local tls = import 'github.com/zachfi/jsonnet-libs/tls/util.libsonnet',

  // new(appName, namespace) creates a restic backup context. Can be used as a
  // "sleep" init container (operator runs restic manually), a sidecar that
  // backs up on an interval, or with a cronJob for single-instance workloads.
  new(appName, namespace, image='zachfi/restic:latest', sleepContainerSeconds='200'): {
    local this = self,

    cacert:: '/tls/ca.crt',
    scriptsVolumeName:: '%s-restic-scripts' % appName,
    image:: image,

    volumes:: [
      volume.fromConfigMap(this.scriptsVolumeName, this.scriptsVolumeName),
    ],

    mounts:: [
      volumeMount.new(this.scriptsVolumeName, '/restic'),
    ],

    containerEnv:: [],
    containerArgs:: ['/restic/sleep.sh'],

    configData:: {
      'init.sh': |||
        #!/bin/bash
        set -e
        RESTIC="restic -v"
        $RESTIC snapshots || $RESTIC init
      ||| % this,
      // Backup.sh is extended by the withPVC() method.
      'backup.sh': |||
        #!/bin/bash
        RESTIC="restic -v"
        $RESTIC snapshots || $RESTIC init
      ||| % this,
      'restore.sh': |||
        #!/bin/bash
        set -e
        RESTIC="restic -v"
        $RESTIC restore latest --target /
      ||| % this,
      'sleep.sh': |||
        #!/bin/bash
        echo "Sleeping for %(sleepContainerSeconds)s seconds"
        sleep %(sleepContainerSeconds)s
      ||| % this,
    },

    scriptsConfigMap:
      configMap.new(this.scriptsVolumeName)
      + configMap.withData(this.configData)
      + (if namespace != '' then configMap.metadata.withNamespace(namespace) else {}),

    resticContainer::
      container.new('restic', this.image)
      + container.withCommand('/bin/bash')
      + container.withArgs(this.containerArgs)
      + container.withVolumeMounts(this.mounts)
      + container.withEnv(this.containerEnv)
      + container.resources.withRequests({ cpu: '10m', memory: '100Mi' })
      + container.resources.withLimits({ cpu: '1', memory: '1Gi' }),

    // The number of seconds to sleep when executing the sleep.sh script.
    sleepContainerSeconds:: sleepContainerSeconds,

    // A set of key value pairs used to select which nodes the restic cronJob will run on.
    nodeSelector:: {},

    backupCron::
      cronJob.new('restic-backup-%s' % appName)
      + (if namespace != '' then cronJob.metadata.withNamespace(namespace) else {})
      + cronJob.spec.withConcurrencyPolicy('Forbid')
      + cronJob.spec.jobTemplate.spec.withBackoffLimit(1)
      + cronJob.spec.jobTemplate.spec.template.spec.withNodeSelector(this.nodeSelector)
      + cronJob.spec.jobTemplate.spec.template.spec.withContainers(
        this.resticContainer
        + container.withArgs([
          '/restic/backup.sh',
        ])
      )
      + cronJob.spec.jobTemplate.spec.template.spec.withRestartPolicy('Never')
      + cronJob.spec.jobTemplate.spec.template.spec.withVolumes(this.volumes),
  },

  withImage(image):: {
    image: image,
  },

  // withResticResources sets requests and/or limits on the restic container
  // (CronJob, init container, sidecar). Pass objects with keys such as cpu and
  // memory (e.g. requests={ memory: '256Mi' }, limits={ memory: '1Gi' }).
  // Only non-empty objects are applied.
  withResticResources(requests={}, limits={}): {
    resticContainer+:
      (if std.length(requests) > 0 then container.resources.withRequests(requests) else {})
      + (if std.length(limits) > 0 then container.resources.withLimits(limits) else {}),
  },

  // withPVC adds a path to backup and a mount for the restic container. Also
  // adds the PVC to volumes so a CronJob can mount it (use withCronPodAffinity
  // so the CronJob runs on the same node as the workload and can use the PVC).
  // Use readOnly=false when this backup context is also used for init restore.
  withPVC(volumeName, mountPath, readOnly=false): {
    configData+: {
      'backup.sh'+: |||
        $RESTIC backup %s
      ||| % mountPath,
    },

    mounts+: [
      volumeMount.new(volumeName, mountPath, readOnly),
    ],

    volumes+: [
      volume.fromPersistentVolumeClaim(volumeName, volumeName),
    ],
  },

  // withCertificate creates a TLS certificate for restic, used to validate
  // endpoints in the case of a private CA, or for use as a client.
  withCertificate(volumeName, issuer, cn, mountPath='/tls'): {
    local this = self,

    certificate: tls.newSimpleCert(volumeName, issuer, cn),

    volumes+: [
      volume.fromSecret(volumeName, volumeName),
    ],

    mounts+: [
      volumeMount.new(volumeName, mountPath),
    ],
  },

  withVolumeMount(volumeName, mountPath): {
    mounts+: [
      volumeMount.new(volumeName, mountPath),
    ],
  },

  // withVolume adds a volume to the backup so the CronJob pod can mount it
  // (e.g. TLS secret). Use together with withVolumeMount when the volume is
  // added from outside the restic lib (e.g. app withCertificate).
  withVolume(vol): {
    volumes+: [vol],
  },

  // withResticCacert sets RESTIC_CACERT so restic uses the CA cert at the given
  // path. Use when the CA path comes from a workload cert mount (the app’s
  // withCertificate calls this). Replaces any RESTIC_CACERT from withS3Bucket.
  withResticCacert(path): {
    containerEnv:: (
      std.filter(function(e) e.name != 'RESTIC_CACERT', super.containerEnv)
    ) + [envVar.new('RESTIC_CACERT', path)],
  },

  withNodeSelector(hsh): {
    nodeSelector:: hsh,
  },

  withInitSleep(): {
    local this = self,
    containerArgs:: ['/restic/sleep.sh'],
  },

  // withInitRestore sets the init script to restore.sh. Ensure volumes added
  // via withPVC use readOnly=false when using restore so the container can write.
  withInitRestore(): {
    local this = self,
    containerArgs:: ['/restic/restore.sh'],
  },

  // withInitScript creates an init container which runs a /bin/bash script.
  withInitScript(script): {
    local this = self,
    containerArgs:: [script],
  },

  // withS3Bucket sets up the environment variables for restic to use an S3 bucket.
  // The Secret must already exist (e.g. created by the app, or synced via ExternalSecret
  // from Vault). This library only references it by name and key mapping.
  //
  // secretRefName: name of the existing Secret in the same namespace.
  // secretKeys: optional mapping of logical names to secret key names. Defaults assume
  //   the secret has keys 'accessKey', 'secretKey', 'resticPassword'. Override when
  //   your secret uses different key names (e.g. from Vault).
  // bucketURL: S3 bucket URL, e.g. s3://bucket-name; repo URL becomes
  //   s3://bucket-name/namespace/name.
  // caCertPath: optional path to CA cert for S3 (e.g. /tls/ca.crt). Omit when using
  //   workload cert mount and withResticCacert.
  withS3Bucket(
    secretRefName,
    bucketURL,
    namespace,
    name,
    secretKeys={ accessKey: 'accessKey', secretKey: 'secretKey', resticPassword: 'resticPassword' },
    caCertPath=null,
  ):: {

    local repoURL = std.join('/', [bucketURL, namespace, name]),

    containerEnv+:
      [
        envVar.fromSecretRef('AWS_ACCESS_KEY_ID', secretRefName, secretKeys.accessKey),
        envVar.fromSecretRef('AWS_SECRET_ACCESS_KEY', secretRefName, secretKeys.secretKey),
        envVar.fromSecretRef('RESTIC_PASSWORD', secretRefName, secretKeys.resticPassword),
        envVar.new('RESTIC_REPOSITORY', repoURL),
      ]
      + (if caCertPath != null then [envVar.new('RESTIC_CACERT', caCertPath)] else []),
  },

  // A backup cronJob can be used for workloads which have a single instance.
  // This is important because in the case of a statefulset where the PVC is a
  // template and multiple underlying volumes are created, the cronJob will
  // only schedule on a single instance.  If the workload is entirely
  // replicated, this may be sufficient.

  // Schedule the CronJob pod on the same node as pods matching matchLabels
  // (e.g. the workload's pods). Required for RWO PVCs: the CronJob can then
  // mount the same PVC as the workload. Call with the workload's pod selector
  // labels (e.g. { name: appName }).
  withCronPodAffinity(matchLabels): {
    backupCron+:
      cronJob.spec.jobTemplate.spec.template.spec.affinity.podAffinity.withRequiredDuringSchedulingIgnoredDuringExecution([
        podAffinityTerm.labelSelector.withMatchLabels(matchLabels)
        + podAffinityTerm.withTopologyKey('kubernetes.io/hostname'),
      ]),
  },

  // TODO: allow an "instance" flag so the backup targets the correct volume
  // when using a claimTemplate (e.g. statefulset), matching the volume of the
  // node on which the cron Job is scheduled.

  // withBackupCron enables and configures the schedule and ttl for the backup cron job.
  withBackupCron(schedule, ttl=86400): {
    local this = self,

    backupCron+:
      cronJob.spec.withSchedule(schedule)
      + cronJob.spec.jobTemplate.spec.withTtlSecondsAfterFinished(ttl),

    // Expose the cronJob for rendering when this function is used.
    cron: this.backupCron,
  },

  // withMatchLabels modifies the backupCron to include the label matchers.
  withMatchLabels(matchers={}): {
    backupCron+:
      cronJob.metadata.withLabels(matchers),
  },

  // withFsPermissions modifies the backupCron to include the fsGroup and runAsUser.
  withFsPermissions(uid, gid): {
    backupCron+:
      cronJob.spec.jobTemplate.spec.template.spec.securityContext.withFsGroup(gid)
      + cronJob.spec.jobTemplate.spec.template.spec.securityContext.withRunAsUser(uid),
  },

  // resticForApp builds a restic backup from an app and opts. Use at top level:
  //   backup: restic.resticForApp(self.ldap, { bucketURL: ..., secretRefName: ..., backupTargets: [...], schedule: ..., cert: ... })
  // opts: bucketURL, secretRefName (optional, default '%s-restic-config' % appName), secretKeys (optional key mapping),
  //       backupTargets ([{ volumeName, mountPath }]), schedule, ttl (default 86400), image (optional),
  //       resources (optional { requests, limits }), caCertPath (optional), cert (optional { mountPath, volumeName }),
  //       fsPermissions (optional { uid, gid }), nodeSelector (optional {}).
  // Caller must ensure the Secret exists (e.g. create it in the app or use ExternalSecret). Include in manifest:
  //   result.scriptsConfigMap, result.cron, and the Secret/ExternalSecret from the app.
  resticForApp(app, opts)::
    local appName = app.appName;
    local namespace = app.app.namespace;
    local matchLabels = app.workload.spec.selector.matchLabels;
    local secretRefName = if std.objectHas(opts, 'secretRefName') then opts.secretRefName else '%s-restic-config' % appName;
    local secretKeys = if std.objectHas(opts, 'secretKeys') then opts.secretKeys else { accessKey: 'accessKey', secretKey: 'secretKey', resticPassword: 'resticPassword' };
    local caCertPathVal = if std.objectHas(opts, 'caCertPath') then opts.caCertPath else null;
    local resReqs = if std.objectHas(opts, 'resources') && opts.resources != null && std.objectHas(opts.resources, 'requests') then opts.resources.requests else {};
    local resLimits = if std.objectHas(opts, 'resources') && opts.resources != null && std.objectHas(opts.resources, 'limits') then opts.resources.limits else {};
    local ttl = if std.objectHas(opts, 'ttl') then opts.ttl else 86400;
    local base = self.new(appName, namespace)
                 + self.withS3Bucket(secretRefName, opts.bucketURL, namespace, appName, secretKeys=secretKeys, caCertPath=caCertPathVal)
                 + (if std.objectHas(opts, 'image') && opts.image != null then self.withImage(opts.image) else {})
                 + (if std.objectHas(opts, 'resources') && opts.resources != null && opts.resources != {} then self.withResticResources(resReqs, resLimits) else {});
    local withTargets = std.foldr(function(t, acc) acc + self.withPVC(t.volumeName, t.mountPath), opts.backupTargets, base);
    withTargets
    + (if std.objectHas(opts, 'cert') && opts.cert != null then self.withVolumeMount(opts.cert.volumeName, opts.cert.mountPath) + self.withVolume(volume.fromSecret(opts.cert.volumeName, opts.cert.volumeName)) + self.withResticCacert(opts.cert.mountPath + '/ca.crt') else {})
    + self.withBackupCron(opts.schedule, ttl)
    + self.withCronPodAffinity(matchLabels)
    + (if std.objectHas(opts, 'fsPermissions') && opts.fsPermissions != null then self.withFsPermissions(opts.fsPermissions.uid, opts.fsPermissions.gid) else {})
    + (if std.objectHas(opts, 'nodeSelector') && opts.nodeSelector != {} then self.withNodeSelector(opts.nodeSelector) else {}),
}
