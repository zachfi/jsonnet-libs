{
  local k = import 'k.libsonnet',
  local kausal = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet',

  local configMap = k.core.v1.configMap,
  local container = k.core.v1.container,
  local cronJob = k.batch.v1.cronJob,
  local envVar = k.core.v1.envVar,
  local job = k.batch.v1.job,
  local podAffinityTerm = k.core.v1.podAffinityTerm,
  local secret = k.core.v1.secret,
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
        set -e
        RESTIC="restic -v"
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
      + kausal.util.resourcesRequests('10m', '100Mi')
      + kausal.util.resourcesLimits('1', '1Gi'),

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

  // withS3Bucket sets up the environment variables for restic to use an S3 bucket
  // The secret should contain the following keys:
  // - accessKey
  // - secretKey
  // - resticPassword
  //
  // secretRefData can be supplied to create the secret from the received data.
  //
  // The bucketURL is the S3 bucket URL, e.g. s3://bucket-name, which is then
  // used to calculate the repoURL using namespace and name path delimiters,
  // e.g. s3://bucket-name/namespace/name.
  withS3Bucket(
    secretRefName,
    bucketURL,
    namespace,
    name,
    secretRefData={},
    caCertPath='/tls/ca.crt',
  ):: {

    local repoURL = std.join('/', [bucketURL, namespace, name]),

    containerEnv+: [
      envVar.fromSecretRef('AWS_ACCESS_KEY_ID', secretRefName, 'accessKey'),
      envVar.fromSecretRef('AWS_SECRET_ACCESS_KEY', secretRefName, 'secretKey'),
      envVar.fromSecretRef('RESTIC_PASSWORD', secretRefName, 'resticPassword'),
      envVar.new('RESTIC_REPOSITORY', repoURL),
      envVar.new('RESTIC_CACERT', caCertPath),
    ],

    configSecret:
      if secretRefData != {} then
        secret.new(secretRefName, secretRefData)
        + secret.metadata.withNamespace(namespace)
      else {},
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

}
