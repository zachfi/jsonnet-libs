{
  local k = import 'k.libsonnet',
  local kausal = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet',

  local configMap = k.core.v1.configMap,
  local container = k.core.v1.container,
  local cronJob = k.batch.v1.cronJob,
  local envVar = k.core.v1.envVar,
  local job = k.batch.v1.job,
  local secret = k.core.v1.secret,
  local volume = k.core.v1.volume,
  local volumeMount = k.core.v1.volumeMount,

  local tls = import 'github.com/zachfi/jsonnet-libs/tls/util.libsonnet',

  // Restic configures a container environment for executing restic commands.
  // This can be used as a "sleep" init contianer, whereby the operator is
  // expected to perform the interactions manually.  It can also be used to run
  // a sidecar container which loops indefinately and executes a backup every X
  // seconds. For single instance deployments, a cronJob can be used to
  // schedule a backup job.
  new(appName, namespace): {
    local this = self,

    cacert:: '/tls/ca.crt',
    scriptsVolumeName:: '%s-restic-scripts' % appName,
    image:: 'zachfi/restic:latest',

    volumes:: [
      volume.fromConfigMap(this.scriptsVolumeName, this.scriptsVolumeName),
    ],

    mounts:: [
      volumeMount.new(this.scriptsVolumeName, '/restic'),
    ],

    containerEnv:: [],

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

    scripts:
      configMap.new(this.scriptsVolumeName)
      + configMap.withData(this.configData),

    containerArgs:: ['/restic/sleep.sh'],

    resticContainer::
      container.new('restic', this.image)
      + container.withCommand('/bin/bash')
      + container.withArgs(this.containerArgs)
      + container.withVolumeMounts(this.mounts)
      + container.withEnv(this.containerEnv)
      + kausal.util.resourcesRequests('10m', '100Mi')
      + kausal.util.resourcesLimits('1', '1Gi'),

    // The number of seconds to sleep when executing the sleep.sh script.
    sleepContainerSeconds:: '200',

    // A set of key value pairs used to select which nodes the restic cronJob will run on.
    nodeSelector:: {},

    backupCron::
      cronJob.new('restic-backup-%s' % appName)
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

  withPVC(volumeName, mountPath, readOnly=true): {
    configData+: {
      'backup.sh'+: |||
        $RESTIC backup %s
      ||| % mountPath,
    },

    volumes+: [
      volume.fromPersistentVolumeClaim(volumeName, volumeName),
    ],

    mounts+: [
      volumeMount.new(volumeName, mountPath)
      + volumeMount.withReadOnly(readOnly),
    ],
  },

  // withCertificate creates a TLS certificate for restic, used to validate
  // endpoints in the case of a private CA.
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

  withNodeSelector(hsh): {
    nodeSelector:: hsh,
  },

  withInitSleep(): {
    local this = self,
    containerArgs:: ['/restic/sleep.sh'],
  },

  // TODO: this needs to be set non-readonly in withPVC somehow.
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
  // used to calculate the repoURL using namespace and name path dilimiters,
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
      else {},
  },

  // A backup cronJob can be used for workloads which have a single instance.
  // This is important because in the case of a statefulset where the PVC is a
  // template and multiple underlying volumes are created, the cronJob will
  // only schedule on a single instance.  If the workload is entirely
  // replicated, this may be sufficient.

  // TODO: work out a way to allow the user to pass in an "instnace" flag which
  // will change the target volume name to match the workload.  When a
  // claimTemplate is used as in a statefulset, then we want to match the
  // volume of the node on which we are scheduled.

  // withBackupCron enables and configures the schedule and ttl for the backup cron job.
  withBackupCron(schedule, ttl=86400): {
    local this = self,

    backupCron+:
      cronJob.spec.withSchedule(schedule)
      + cronJob.spec.jobTemplate.spec.withTtlSecondsAfterFinished(ttl),

    // Realize the cronJob only when requeted through the use of this function.
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
