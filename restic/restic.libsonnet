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

  new(appName, namespace): {
    local this = self,

    local config = import 'config.libsonnet',
    local backupDir = '/tmp/source',

    cacert:: '/tls/ca.crt',
    configVolumeName:: '%s-restic-config' % appName,
    image:: 'zachfi/shell:archlinux',
    tlsVolumeName:: 'restic-tls',

    // Override with withSecretRefName().
    secretRefName:: 'restic-config',
    // Override with withBucketURL().
    bucketURL:: '',

    volumes:: [
      volume.fromConfigMap(this.configVolumeName, this.configVolumeName),
      volume.fromSecret(this.tlsVolumeName, this.tlsVolumeName),
    ],

    // Hardcode the name here for re-use by other new() calls.  We only care about the CA certificate.
    certificate:
      tls.simpleCert.new(this.tlsVolumeName, 'vault-issuer', 'restic.cli.cluster.znet'),

    containerEnv::
      local repoURL = '%s/%s/%s' % [this.bucketURL, namespace, appName];

      container.withEnvMixin([
        envVar.fromSecretRef('AWS_ACCESS_KEY_ID', this.secretRefName, 'accessKey'),
        envVar.fromSecretRef('AWS_SECRET_ACCESS_KEY', this.secretRefName, 'secretKey'),
        envVar.fromSecretRef('RESTIC_PASSWORD', this.secretRefName, 'secretKey'),
        envVar.new('RESTIC_REPOSITORY', repoURL),
        envVar.new('RESTIC_CACERT', this.cacert),
      ]),

    configData:: {
      'init.sh': |||
        #!/bin/bash
        set -e
        RESTIC="restic -v"

        $RESTIC snapshots || $RESTIC init
        $RESTIC forget --keep-monthly 3 --keep-weekly 5 --keep-daily 10 --prune
      ||| % this,
      'backup.sh': |||
        #!/bin/bash
        set -e
        RESTIC="restic -v"

        $RESTIC snapshots || $RESTIC init
        $RESTIC unlock
        $RESTIC forget --keep-monthly 3 --keep-weekly 5 --keep-daily 10 --prune
      ||| % this,
    },

    script_config:
      configMap.new(this.configVolumeName)
      + configMap.withData(this.configData),

    resticContainer::
      container.new('restic', this.image)
      + this.containerEnv
      + container.withCommand('/bin/bash')
      + container.withArgs([
        '/restic/init.sh',
      ])
      + container.withVolumeMounts([
        volumeMount.new(this.configVolumeName, '/restic'),
        volumeMount.new(this.tlsVolumeName, '/tls'),
      ])
      + kausal.util.resourcesRequests('10m', '100Mi')
      + kausal.util.resourcesLimits('1', '1Gi'),

    // A container to init the restic backend.
    initContainer::
      this.resticContainer
      + container.withArgs([
        '/restic/init.sh',
      ]),

    backupContainer::
      this.resticContainer
      + container.withArgs([
        '/restic/backup.sh',
      ]),

    restoreContainer::
      this.resticContainer
      + container.withCommand('restic')
      + container.withArgs([
        'restore',
        'latest',
        '--target',
        '/',
      ]),

    backupCron:
      cronJob.new('restic-backup-%s' % appName)
      + cronJob.spec.withSchedule('13 */3 * * *')
      + cronJob.spec.withConcurrencyPolicy('Forbid')
      + cronJob.spec.jobTemplate.spec.withBackoffLimit(1)
      + cronJob.spec.jobTemplate.spec.withTtlSecondsAfterFinished(86400)  // 1 day
      + cronJob.spec.jobTemplate.spec.template.spec.withContainers(this.backupContainer)
      + cronJob.spec.jobTemplate.spec.template.spec.withRestartPolicy('Never')
      + cronJob.spec.jobTemplate.spec.template.spec.withVolumes(this.volumes),
  },

  withMatchLabels(matchers={}): {
    backupCron+:
      cronJob.metadata.withLabels(matchers),
  },

  withFsPermissions(uid, gid): {
    backupCron+:
      cronJob.spec.jobTemplate.spec.template.spec.securityContext.withFsGroup(gid)
      + cronJob.spec.jobTemplate.spec.template.spec.securityContext.withRunAsGroup(gid)
      + cronJob.spec.jobTemplate.spec.template.spec.securityContext.withRunAsUser(uid),
  },

  withPVC(volumeName, mountPath): {
    configData+: {
      'backup.sh'+: |||
        $RESTIC backup %s
      ||| % mountPath,
    },

    backupContainer+:
      container.withVolumeMountsMixin([
        volumeMount.new(volumeName, mountPath)
        + volumeMount.withReadOnly(true),
      ]),

    restoreContainer+:
      container.withVolumeMountsMixin([
        volumeMount.new(volumeName, mountPath),
      ]),

    backupCron+:
      cronJob.spec.jobTemplate.spec.template.spec.withVolumesMixin([
        volume.fromPersistentVolumeClaim(volumeName, volumeName),
      ]),
  },

  withNodeSelector(key, value): {
    backupCron+:
      cronJob.spec.jobTemplate.spec.template.spec.withNodeSelector({ [key]: value }),
  },

  withSecretRefName(name): {
    secretRefName: name,
  },

  withSecretRefData(data): {
    local this = self,
    configSecret:
      secret.new(this.secretRefName, data),
  },

  withBucketURL(bucket): {
    bucketURL: bucket,
  },
}
