// A useful utility for deploying apps on Kubernetes with Jsonnet.
{
  local k = import 'k.libsonnet',
  local kausal = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet',

  local configMap = k.core.v1.configMap,
  local container = k.core.v1.container,
  local containerPort = k.core.v1.containerPort,
  local cronJob = k.batch.v1.cronJob,
  local daemonset = k.apps.v1.daemonSet,
  local deployment = k.apps.v1.deployment,
  local envVar = k.core.v1.envVar,
  local labelSelector = k.meta.v1.labelSelector,
  local labelSelectorRequirement = k.meta.v1.labelSelectorRequirement,
  local nodeSelectorRequirement = k.core.v1.nodeSelectorRequirement,
  local nodeSelectorTerm = k.core.v1.nodeSelectorTerm,
  local podAntiAffinity = k.core.v1.podAntiAffinity,
  local podAffinityTerm = k.core.v1.podAffinityTerm,
  local pvc = k.core.v1.persistentVolumeClaim,
  local pv = k.core.v1.persistentVolume,
  local service = k.core.v1.service,
  local statefulset = k.apps.v1.statefulSet,
  local volume = k.core.v1.volume,
  local volumeMount = k.core.v1.volumeMount,

  local restic = import 'github.com/zachfi/jsonnet-libs/restic/restic.libsonnet',
  local tls = import 'github.com/zachfi/jsonnet-libs/tls/util.libsonnet',

  new(appName, image, namespace): {
    local this = self,

    // A few internal variables

    app:: {
      name: appName,
      namespace: namespace,
    },

    appName:: appName,
    configVolumeName:: '%s-config' % appName,
    dataVolumeName:: '%s-data' % appName,
    tlsVolumeName:: '%s-tls' % appName,

    // The initial objects to be modified by the function calls.

    // pv and pvc are used to create a persistent volume and claim.
    pv: [],
    pvc: [],

    // volumes and mounts are realized by the default workload objects.
    volumes:: [],
    mounts:: [],

    defaultContainer(name, image)::
      container.new(name, image)
      + container.withImagePullPolicy('IfNotPresent')
      + container.withVolumeMounts(this.mounts)
    ,

    extraContainers:: [],
    container:: this.defaultContainer(appName, image),
    initContainer:: this.defaultContainer('init', image),

    svcPorts:: [],
    svc::
      service.new(appName, this.workload.spec.selector.matchLabels, this.svcPorts)
      + service.metadata.withLabels({ name: appName })
      + service.spec.withIpFamilyPolicy('RequireDualStack')
      + service.spec.withIpFamilies(['IPv6', 'IPv4'])
    ,

    annotations:: {
      container_hash: std.md5(std.toString(this.container)),
    },

    deployment::
      deployment.new(appName, 1, this.container,)
      + deployment.spec.template.metadata.withAnnotations(this.annotations)
      + deployment.spec.strategy.rollingUpdate.withMaxSurge(0)
      + deployment.spec.strategy.rollingUpdate.withMaxUnavailable(1)
      + deployment.spec.template.spec.withTerminationGracePeriodSeconds(45)
      + deployment.spec.template.spec.withContainers([this.container] + this.extraContainers)
      + deployment.spec.template.spec.withVolumes(this.volumes)
    ,

    statefulset::
      statefulset.new(appName, 1, this.container,)
      + statefulset.spec.withServiceName(appName)
      + statefulset.spec.template.metadata.withAnnotations(this.annotations)
      + statefulset.spec.updateStrategy.rollingUpdate.withMaxUnavailable(1)
      + statefulset.spec.template.spec.withContainers([this.container] + this.extraContainers)
      + statefulset.spec.template.spec.withVolumes(this.volumes)
    ,

    daemonset::
      daemonset.new(appName, this.container,)
      + daemonset.spec.template.metadata.withAnnotations(this.annotations)
      + daemonset.spec.template.spec.withContainers([this.container] + this.extraContainers)
      + daemonset.spec.template.spec.withVolumes(this.volumes)
    ,

    cronJob::
      local this = self;
      cronJob.new(appName, '*/3 * * * *', [this.container])
      + cronJob.spec.jobTemplate.spec.withTtlSecondsAfterFinished(300)  // 1 week
      + cronJob.spec.jobTemplate.spec.withBackoffLimit(1)
      + cronJob.spec.jobTemplate.spec.template.spec.withRestartPolicy('Never'),

    backup::
      local this = self;
      restic.new(this.appName, this.app.namespace),

    // Workload is used to define the overall replicaset.  This allows
    // functions to modify the behavior of both the statefulset and deployment
    // keys, without knowing which one will be used in the end.  Use
    // withDeployment(), withStatefulSet(), or withDaemonSet() to get the final
    // workload.
    workload: {},
  },

  withNodeSelector(hsh): {
    deployment+:
      deployment.spec.template.spec.withNodeSelector(hsh),

    statefulset+:
      statefulset.spec.template.spec.withNodeSelector(hsh),

    daemonset+:
      daemonset.spec.template.spec.withNodeSelector(hsh),

    cronJob+:
      cronJob.spec.template.spec.withNodeSelector(hsh),

    backup+:
      restic.withNodeSelector(hsh),
  },

  withSelector(hsh={}): {
    deployment+:
      deployment.spec.selector.withMatchLabels(hsh)
      + deployment.spec.template.metadata.withLabels(hsh),

    statefulset+:
      statefulset.spec.selector.withMatchLabels(hsh)
      + statefulset.spec.template.metadata.withLabels(hsh),

    daemonset+:
      daemonset.spec.selector.withMatchLabels(hsh)
      + daemonset.spec.template.metadata.withLabels(hsh),
  },

  withAntiAffinity(): {
    local this = self,

    local lbls = { name: this.appName },

    local requirements = [
      labelSelectorRequirement.withKey('name')
      + labelSelectorRequirement.withOperator('In')
      + labelSelectorRequirement.withValues([this.appName]),
    ],

    local selector =
      podAffinityTerm.labelSelector.withMatchExpressions(requirements)
      + podAffinityTerm.withTopologyKey('kubernetes.io/hostname'),

    deployment+:
      deployment.spec.template.spec.affinity.podAntiAffinity.withRequiredDuringSchedulingIgnoredDuringExecution([selector]),

    statefulset+:
      statefulset.spec.template.spec.affinity.podAntiAffinity.withRequiredDuringSchedulingIgnoredDuringExecution([selector]),
  },

  withAntiNodeSelector(key, value): {
    local terms = nodeSelectorTerm.withMatchExpressions([
      nodeSelectorRequirement.withKey(key)
      + nodeSelectorRequirement.withOperator('NotIn')
      + nodeSelectorRequirement.withValues([value]),
    ]),

    deployment+:
      deployment.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.withNodeSelectorTerms([terms]),

    statefulset+:
      statefulset.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.withNodeSelectorTerms([terms]),

    daemonset+:
      daemonset.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.withNodeSelectorTerms([terms]),
  },

  withServiceAccountName(name): {
    deployment+:
      deployment.spec.template.spec.withServiceAccountName(
        name
      ),

    // TODO:
    // statefulset+:
    //   statefulset.spec.template.spec.withServiceAccountName(
    //     name
    //   ),

    daemonset+:
      daemonset.spec.template.spec.withServiceAccountName(
        name
      ),
  },

  withCertificate(issuer='vault-issuer', tld='cluster.local', altNames=[], mountPath='/tls'): {
    local this = self,

    certificate:
      tls.newSimpleCert(
        this.tlsVolumeName,
        issuer,
        '%s.%s.svc.%s' % [this.appName, this.app.namespace, tld],
        altNames
      ),

    mounts+: [
      volumeMount.new(this.tlsVolumeName, mountPath),
    ],

    volumes+: [
      volume.fromSecret(this.tlsVolumeName, this.tlsVolumeName),
    ],

    local reloader = import 'reloader/main.libsonnet',
    annotations+: reloader.reloadOnSecretsAnnotation(this.tlsVolumeName,).metadata.annotations,
  },

  withInitContainer(container): {
    local this = self,

    initContainer+:: container,

    deployment+:
      deployment.spec.template.spec.withInitContainers([this.initContainer])
      + deployment.spec.template.spec.withVolumesMixin(this.backup.volumes),

    statefulset+:
      statefulset.spec.template.spec.withInitContainers([this.initContainer])
      + statefulset.spec.template.spec.withVolumesMixin(this.backup.volumes),
  },

  // withInitRestoreSleep is used to add a sleep container to the init which
  // can be used to manually with restic.
  withInitRestoreSleep(): {
    local this = self,

    sleepContainerSeconds:: '100',

    sleepContainer+::
      this.backup.restoreContainer
      + container.withCommand('sleep')
      + container.withArgs([this.sleepContainerSeconds]),

    deployment+:
      deployment.spec.template.spec.withInitContainers(this.sleepContainer)
      + deployment.spec.template.spec.withVolumesMixin(this.backup.volumes)
    ,

    statefulset+:
      statefulset.spec.template.spec.withInitContainers(this.sleepContainer)
      + statefulset.spec.template.spec.withVolumesMixin(this.backup.volumes),
  },

  // TODO: we should receive a container, in the case of restic, recieve the
  // container and then mount the configmap scripts to loop and perform the
  // backup.
  // The received container must include the /bin/bash binary.
  withCronSidecarContainer(c, hook='', interval=10000, path='/scripts'):: {
    local this = self,
    local name = '%s-%s' % [this.appName, c.name],

    sidecarCronConfigMaps+: [
      configMap.new(name)
      + configMap.withData({
        'cron.sh': |||
          #! /bin/bash
          while true; do
            sleep %(s)d
            bash %(scripts)s/hook.sh
          done
        ||| % { s: interval, scripts: path },
        'hook.sh': hook,
      }),
    ],


    mounts+: [
      volumeMount.new(name, path),
    ],

    volumes+: [
      volume.fromConfigMap(name, name),
    ],


    // BUG: this is not working, the container is not being added to the
    extraContainers+: [
      c
      + container.withVolumeMountsMixin(this.mounts)
      + container.withCommand(['/bin/bash'])
      + container.withArgs([
        '%(scripts)s/cron.sh' % { scripts: path },
      ]),
    ],

    annotations+: {
      [name + '_cron_container_hash']: std.md5(std.toString(c)),
    },
  },

  // withCronSidecar adds a cron sidecar to the deployment or statefulset.
  // This should be after all modifications to container have been made, since
  // we copy container as a base.
  withCronSidecar(name, image, hook='', sleep=10000):: {
    local this = self,

    // TODO: this appears to be unused
    sidecarCronConfigMaps+: [
      configMap.new(name)
      + configMap.withData({
        'cron.sh': |||
          #! /bin/bash
          while true; do
            sleep %(s)d
            bash /scripts/hook.sh
          done
        ||| % { s: sleep },
        'hook.sh': hook,
      }),
    ],

    local cronContainer =
      this.defaultContainer(name, image)
      + container.withVolumeMountsMixin([
        volumeMount.new(name, '/scripts'),
      ])
      + container.withCommand(['/bin/bash'])
      + container.withArgs([
        '/scripts/cron.sh',
      ]),

    extraContainers+: [cronContainer],

    deployment+:
      deployment.spec.template.spec.withVolumesMixin([
        volume.fromConfigMap(name, name),
      ])
      + deployment.spec.template.spec.withVolumesMixin(this.backup.volumes)
      + deployment.spec.template.metadata.withAnnotationsMixin({
        [name + '_cron_container_hash']: std.md5(std.toString(cronContainer)),
      }),

    statefulset+:
      statefulset.spec.template.spec.withVolumesMixin([
        volume.fromConfigMap(name, name),
      ])
      + statefulset.spec.template.spec.withVolumesMixin(this.backup.volumes)
      + statefulset.spec.template.metadata.withAnnotationsMixin({
        [name + '_cron_container_hash']: std.md5(std.toString(cronContainer)),
      }),
  },

  withRunAsNonRoot():: {
    local this = self,

    container+:
      container.securityContext.withRunAsNonRoot(true),

    deployment+:
      deployment.spec.template.spec.securityContext.withRunAsNonRoot(true),

    statefulset+:
      statefulset.spec.template.spec.securityContext.withRunAsNonRoot(true),

  },

  withInitRestore(): {
    local this = self,
    deployment+:
      deployment.spec.template.spec.withInitContainers(this.backup.restoreContainer)
      + deployment.spec.template.spec.withVolumesMixin(this.backup.volumes)
    ,

    statefulset+:
      statefulset.spec.template.spec.withInitContainers(this.backup.restoreContainer)
      + statefulset.spec.template.spec.withVolumesMixin(this.backup.volumes),
  },

  withInitChown(path, uid, gid):: {
    initContainer+:
      container.withImage('alpine:latest')
      + container.securityContext.withRunAsUser(0)
      + container.withCommand([
        'sh',
        '-c',
        '(chmod 0775 %(p)s; chgrp %(g)s %(p)s)' % { p: path, g: gid },
      ]),
  },

  withFsPermissions(uid, gid): {
    backup+:
      restic.withFsPermissions(uid, gid),

    // This worked for the init container to restore the data, but when
    // starting the another container, root was now not root, so was unable to
    // mkdir in /var/run (owned by root).  Not sure the righ workaround.

    // 2024-01-29T02:04:26+0000
    // Had to comment this again for media.
    // https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
    // Aparantly the ownership inside the volume is changed on pod
    // start, but not sure.  Hmm.

    statefulset+:
      statefulset.spec.template.spec.securityContext.withFsGroup(gid)
      + statefulset.spec.template.spec.securityContext.withRunAsUser(uid),

    deployment+:
      deployment.spec.template.spec.securityContext.withFsGroup(gid)
      + deployment.spec.template.spec.securityContext.withRunAsUser(uid),
  },

  withSecurityPermissions(uid, gid): {
    deployment+:
      deployment.spec.template.spec.securityContext.withFsGroup(gid),
    // + deployment.spec.template.spec.securityContext.withRunAsGroup(gid)
    // + deployment.spec.template.spec.securityContext.withRunAsUser(uid),
  },

  withService(): {
    local this = self,

    service:
      this.svc,
  },

  withServicePorts(ports=[]): {
    local this = self,
    svcPorts+: ports,

    svc+:
      service.spec.withPorts(this.svcPorts),
  },

  withInetOnly(): {
    svc+:
      service.spec.withIpFamilyPolicy('SingleStack')
      + service.spec.withIpFamilies(['IPv4']),
  },

  withInet6Only(): {
    svc+:
      service.spec.withIpFamilyPolicy('SingleStack')
      + service.spec.withIpFamilies(['IPv6']),
  },

  withSessionAffinity(affinity='ClientIP'): {
    svc+:
      service.spec.withSessionAffinity(affinity),
  },

  withExternalAddresses(addresses=[]): {
    svc+:
      service.spec.withExternalIPs(addresses),
  },

  withDeploymentPermissions(uid, gid): {
    deployment+:
      deployment.spec.template.spec.securityContext.withFsGroup(gid)
      + deployment.spec.template.spec.securityContext.withRunAsGroup(gid)
      + deployment.spec.template.spec.securityContext.withRunAsUser(uid),

  },

  // TODO: we want the app to pass in the bucket, and secretRefName.  If
  // secretRefData is passed in, create the secret.  Perhaps to avoid conflict
  // between apps creating the same secret, we could create the secrets in a
  // way that includes the bucket URL.  In this way as long as the same bucket
  // were referenced, the credentials would be unique.  But as I type this, I
  // see that apps may want to use different credentials for the same bucket.

  // withResticS3Backup enables restic backups to s3 for the workload.  The
  // bucketURL is the root of the bucket, which the app should have read and
  // write access to.  The secretRefName is the name of the secret that
  // contains the restic credentials.  The secretRefData is the data to be
  // stored in the secret. If secretRefData is not provided, the secret will
  // not be created, and the app is responsible for creating the secret.  The
  // referenced secret or the secretRefData must contain the `accessKey` and
  // `secretKey` keys.
  withResticS3Backup(bucketURL, secretRefName='restic-config', secretRefData={}, image='zalegrala/restic:latest'): {
    local this = self,

    local refName = '%s-%s' % [this.appName, secretRefName],

    backup+:
      restic.withS3Bucket(refName, bucketURL, this.app.namespace, this.appName, secretRefData=secretRefData)
      + restic.withImage(image)
    ,

    volumes+: this.backup.volumes,

    // mounts+: this.backup.mounts,

    // volumes+: [
    //   volume.fromSecret(refName, refName),
    // ] + this.backup.volumes,

    resticBackup: this.backup,
  },

  withMatchLabels(matchers={}): {
    deployment+:
      deployment.spec.template.metadata.withLabelsMixin(matchers)
      + deployment.spec.selector.withMatchLabels(matchers),

    statefulset+:
      statefulset.spec.template.metadata.withLabelsMixin(matchers)
      + statefulset.spec.selector.withMatchLabels(matchers),

    backup+:
      restic.withMatchLabels(matchers),
  },

  withConfigmapMount(mountPath, data, subPath='', nameOverride=''): {
    local this = self,

    local configHashName = if std.isEmpty(subPath) then 'config_hash' else (std.strReplace(subPath, '.', '_') + '_hash'),

    local configVolumeName =
      if std.isEmpty(nameOverride)
      then
        (
          if std.isEmpty(subPath)
          then
            this.configVolumeName
          else
            (this.configVolumeName + '-' + std.strReplace(subPath, '.', ''))
        )
      else nameOverride,

    ['configmap_config_%s_%s' % [subPath, nameOverride]]:
      configMap.new(configVolumeName)
      + configMap.withData(data),

    mounts+: [
      volumeMount.withName(configVolumeName)
      + volumeMount.withMountPath(mountPath)
      + (if std.isEmpty(subPath) then {} else volumeMount.withSubPath(subPath)),
    ],

    volumes+: [
      volume.fromConfigMap(configVolumeName, configVolumeName),
    ],

    // TODO: move cron volumeMount to the mounts and volumes pattern above.
    cronJob+::
      cronJob.spec.jobTemplate.spec.template.spec.withVolumes(
        volume.fromConfigMap(configVolumeName, configVolumeName),
      )
      + {
        spec+: { jobTemplate+: { spec+: { template+: { spec+: { containers: [
          i
          + container.withVolumeMountsMixin([
            volumeMount.withName(configVolumeName)
            + volumeMount.withMountPath(mountPath),
          ])

          for i in super.containers
        ] } } } } },
      },
  },

  withLocalDataMount(mountPath='/data', storageClass='local-path', size='10Gi'): {
    local this = self,

    mounts+: [
      volumeMount.new(this.dataVolumeName, mountPath),
    ],

    volumes+: [
      volume.fromPersistentVolumeClaim(this.dataVolumeName, this.dataVolumeName),
    ],

    dataPvc:
      pvc.new(this.dataVolumeName)
      + pvc.spec.resources.withRequests({ storage: size })
      + pvc.spec.withAccessModes(['ReadWriteOnce'])
      + pvc.spec.withStorageClassName(storageClass)
      + pvc.metadata.withLabels({ app: this.appName }),

    statefulset+:
      statefulset.spec.withVolumeClaimTemplatesMixin(this.dataPvc),

    backup+:
      //   // restic.withPVC(this.dataVolumeName + '-ldap-1', mountPath),
      restic.withPVC(this.dataVolumeName, mountPath),
  },

  withCharDevice(volumeName, mountPath, mount=true): {
    local this = self,

    // Disabling mount is useful when withContainers() includes additional
    // contianers and not all contianers need the char device.
    mounts+: (
      if mount then
        [volumeMount.new(volumeName, mountPath)]
      else []
    ),

    volumes+: [
      volume.fromHostPath(volumeName, mountPath)
      + volume.hostPath.withType('CharDevice'),
    ],
  },

  withHostMount(volumeName, mountPath, readOnly=true, type=''): {
    local this = self,

    mounts+: [
      volumeMount.new(volumeName, mountPath, readOnly),
    ],

    volumes+: [
      volume.fromHostPath(volumeName, mountPath)
      + volume.hostPath.withType(type),
    ],
  },

  withDeployment(): {
    local this = self,
    workload: this.deployment,
  },

  withStatefulSet(): {
    local this = self,
    workload: this.statefulset,
  },

  withDaemonSet(): {
    local this = self,
    workload: this.daemonset,
  },

  withNvidia(): {
    deployment+:
      deployment.spec.template.spec.withRuntimeClassName('nvidia'),

    statefulset+:
      statefulset.spec.template.spec.withRuntimeClassName('nvidia'),

    container+:
      container.withEnvMixin(
        [
          envVar.new('NVIDIA_VISIBLE_DEVICES', 'all'),
          envVar.new('NVIDIA_DRIVER_CAPABILITIES', 'all'),
        ]
      ),
  },

  withEnvironmentMixin(env):: {
    container+:
      container.withEnvMixin(env),
  },

  withCron(schedule='0 * * * *'): {
    cronJob+:
      cronJob.spec.withSchedule(schedule),

    cron: self.cronJob,
  },

  withContainer(name, container): {
    deployment+::
      deployment.spec.template.metadata.withAnnotationsMixin({
        [name]: std.md5(std.toString(container)),
      })
      + deployment.spec.template.spec.withContainersMixin(container),

    daemonset+::
      daemonset.spec.template.metadata.withAnnotationsMixin({
        [name]: std.md5(std.toString(container)),
      })
      + daemonset.spec.template.spec.withContainersMixin(container),

    statefulset+::
      statefulset.spec.template.metadata.withAnnotationsMixin({
        [name]: std.md5(std.toString(container)),
      })
      + statefulset.spec.template.spec.withContainersMixin(container),
  },

  withExporter(image, port, env=[], args=[]): {
    local this = self,

    exporterContainer::
      container.new('exporter', image)
      + container.withPorts([
        containerPort.newNamed(port, 'http-metrics'),
      ])
      + container.withArgs(args)
      + container.withEnvMixin(env)
      + kausal.util.resourcesRequests('10m', '100Mi')
      + kausal.util.resourcesLimits('500m', '1Gi'),

    deployment+::
      deployment.spec.template.metadata.withAnnotationsMixin({
        exporter_container_hash: std.md5(std.toString(this.exporterContainer)),
      })
      + deployment.spec.template.spec.withContainersMixin(
        this.exporterContainer
      ),
  },

  withPorts(ports=[]): {
    container+:
      container.withPorts(ports),
  },

  withNfs(nfsServer, nfsPath, mountVolume, mountPath): {
    local volumeName = '%s-%s' % [self.appName, mountVolume],

    pv+: [
      pv.new(volumeName)
      + pv.spec.withCapacity({ storage: '1Gi' })
      + pv.spec.withAccessModes('ReadWriteMany')
      + pv.spec.withMountOptions(['hard', 'nolock', 'nosuid', 'nofail', 'noatime', 'vers=v4'])
      + pv.spec.nfs.withPath(nfsPath)
      + pv.spec.nfs.withServer(nfsServer)
      + pv.spec.nfs.withReadOnly(false),
    ],

    // TODO: consider NFS 4.1
    // mountOptions:
    //     - hard
    //     - nfsvers=4.1

    pvc+: [
      pvc.new(volumeName)
      + pvc.mixin.spec.resources.withRequests({ storage: '1Mi' })
      + pvc.mixin.spec.withAccessModes(['ReadWriteMany'])
      // + pvc.mixin.metadata.withLabels({ app: self.app.name })
      + pvc.mixin.spec.withStorageClassName(''),
    ],

    mounts+: [
      volumeMount.new(volumeName, mountPath),
    ],

    volumes+: [
      // volume.fromPersistentVolumeClaim(volumeName, volumeName),
      volume.withName(volumeName)
      + volume.nfs.withPath(nfsPath)
      + volume.nfs.withServer(nfsServer),
    ],
  },

  withReplicas(replicas): {
    deployment+:
      deployment.spec.withReplicas(replicas),

    statefulset+:
      statefulset.spec.withReplicas(replicas),
  },

  withPullPolicy(policy='IfNotPresent'): {
    container+:
      container.withImagePullPolicy(policy),

    extraContainers:: [
      c + container.withImagePullPolicy(policy)
      for c in super.extraContainers
    ],
  },
}
