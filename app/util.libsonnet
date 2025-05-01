// A useful utility for deploying apps on Kubernetes with Jsonnet.
{
  local k = import 'k.libsonnet',
  local kausal = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet',

  local configMap = k.core.v1.configMap,
  local container = k.core.v1.container,
  local containerPort = kausal.core.v1.containerPort,
  local cronJob = k.batch.v1.cronJob,
  local daemonset = k.apps.v1.daemonSet,
  local deployment = k.apps.v1.deployment,
  local envVar = k.core.v1.envVar,
  local nodeSelectorRequirement = k.core.v1.nodeSelectorRequirement,
  local nodeSelectorTerm = k.core.v1.nodeSelectorTerm,
  local pvc = k.core.v1.persistentVolumeClaim,
  local pv = k.core.v1.persistentVolume,
  local service = k.core.v1.service,
  local statefulset = k.apps.v1.statefulSet,
  local volume = k.core.v1.volume,
  local volumeMount = k.core.v1.volumeMount,

  local restic = import 'github.com/zachfi/jsonnet-libs/restic/restic.libsonnet',
  local tls = import 'github.com/zachfi/jsonnet-libs/tls/util.libsonnet',

  new(appName, image, namespace): {
    local app = self,

    // A few internal variables

    app:: {
      name: appName,
      namespace: namespace,
    },

    appName:: appName,
    configVolumeName:: '%s-config' % appName,
    dataVolumeName:: '%s-data' % appName,

    // Used to adjust the name that restic will use to attach when a statefulset is used.
    pvcFinalName:: app.dataVolumeName,

    tlsVolumeName:: '%s-tls' % appName,

    // The initial objects to be modified by the function calls below

    pv: [],
    pvc: [],

    container::
      container.new(appName, image)
      + container.withImagePullPolicy('IfNotPresent'),

    initContainer:: {},

    svc::
      kausal.util.serviceFor(app.workload)
      + service.spec.withIpFamilyPolicy('RequireDualStack')
      + service.spec.withIpFamilies(['IPv6', 'IPv4']),

    deployment::
      deployment.new(
        appName,
        1,
        app.container,
      )
      + deployment.spec.template.metadata.withAnnotationsMixin({
        container_hash: std.md5(std.toString(app.container)),
      })
      + deployment.spec.strategy.rollingUpdate.withMaxSurge(0)
      + deployment.spec.strategy.rollingUpdate.withMaxUnavailable(1)
      + deployment.spec.template.spec.withTerminationGracePeriodSeconds(45),

    statefulset::
      statefulset.new(
        appName,
        1,
        app.container,
      )
      + statefulset.mixin.spec.template.metadata.withAnnotations({
        container_hash: std.md5(std.toString(app.container)),
      })
      + statefulset.mixin.spec.withServiceName(appName),

    daemonset::
      daemonset.new(
        appName,
        app.container,
      ),

    cronJob::
      local this = self;
      cronJob.new(appName, '*/3 * * * *', [this.container])
      + cronJob.spec.jobTemplate.spec.withTtlSecondsAfterFinished(300)  // 1 week
      + cronJob.spec.jobTemplate.spec.withBackoffLimit(1)
      + cronJob.spec.jobTemplate.spec.template.spec.withRestartPolicy('Never'),

    backup::
      local this = self;
      restic.new(this.appName, this.app.namespace),

    // Use withResticBackup() to enable restic backups for the workload.
    resticBackup: {},

    // Workload is used to define the overall replicaset.  This allows
    // functions to modify the behavior of both the statefulset and deployment
    // keys, without knowing which one will be used in the end.  Use
    // withDeployment(), withStatefulSet(), or withDaemonSet() to get the final
    // workload.
    workload: {},
  },

  withNodeSelector(key, value): {
    deployment+:
      deployment.spec.template.spec.withNodeSelector({ [key]: value }),

    statefulset+:
      statefulset.spec.template.spec.withNodeSelector({ [key]: value }),

    daemonset+:
      daemonset.spec.template.spec.withNodeSelector({ [key]: value }),

    backup+:
      restic.withNodeSelector(key, value),
  },

  withSelector(hsh={}): {
    deployment+:
      deployment.spec.selector.withMatchLabels(hsh)
      + deployment.spec.template.metadata.withLabels(hsh)
    ,

    statefulset+:
      statefulset.spec.selector.withMatchLabels(hsh)
      + statefulset.spec.template.metadata.withLabels(hsh),


    daemonset+:
      daemonset.spec.selector.withMatchLabels(hsh)
      + daemonset.spec.template.metadata.withLabels(hsh),
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

    v::
      volumeMount.new(this.tlsVolumeName, mountPath),

    // container+:
    //   container.withVolumeMountsMixin(this.v),

    initContainer+:
      container.withVolumeMountsMixin(this.v),

    container+:
      container.withVolumeMountsMixin(this.v),

    local reloader = import 'reloader/main.libsonnet',
    deployment+:
      deployment.metadata.withAnnotationsMixin(
        reloader.reloadOnSecretsAnnotation(this.tlsVolumeName,).metadata.annotations
      )
      + deployment.spec.template.spec.withVolumesMixin([
        volume.fromSecret(this.tlsVolumeName, this.tlsVolumeName),
      ]),

    statefulset+:
      statefulset.metadata.withAnnotationsMixin(
        reloader.reloadOnSecretsAnnotation(this.tlsVolumeName,).metadata.annotations
      )
      + statefulset.spec.template.spec.withVolumesMixin([
        volume.fromSecret(this.tlsVolumeName, this.tlsVolumeName),
      ]),
  },

  withInitContainer(container): {
    local this = self,

    initContainer: container,

    deployment+:
      deployment.spec.template.spec.withInitContainers([this.initContainer]),

    statefulset+:
      statefulset.spec.template.spec.withInitContainers([this.initContainer]),
  },

  withInitRestore(): {
    local this = self,
    deployment+:
      deployment.spec.template.spec.withInitContainers(this.backup.restoreContainer)
      + deployment.spec.template.spec.withVolumesMixin(this.backup.volumes)
    ,

    statefulset+:
      statefulset.spec.template.spec.withInitContainers(this.backup.restoreContainer)
      + deployment.spec.template.spec.withVolumesMixin(this.backup.volumes),

    restic_config: this.backup.resticConfig,
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

  // withResticBackup enables restic backups for the workload.  The bucketURL
  // is the root of the bucket, which the app should have read and write access
  // to.  The secretRefName is the name of the secret that contains the restic
  // credentials.  The secretRefData is the data to be stored in the secret. If
  // secretRefData is not provided, the secret will not be created, and the app
  // is responsible for creating the secret.  The referenced secret or the
  // secretRefData must contain the `accessKey` and `secretKey` keys.
  withResticBackup(bucketURL, secretRefName='restic-config', secretRefData={}): {
    local this = self,

    backup+:
      restic.withBucketURL(bucketURL)
      + restic.withSecretRefName(secretRefName)
      + (
        if secretRefData != {} then
          restic.withSecretRefData(secretRefData)
        else {}
      )
    ,

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


    local configVolumeName = if std.isEmpty(nameOverride) then
      (if std.isEmpty(subPath) then this.configVolumeName else (this.configVolumeName + '-' + std.strReplace(subPath, '.', '')))
    else nameOverride,

    ['configmap_config' + subPath]:
      configMap.new(configVolumeName)
      + configMap.withData(data),

    // container+:
    //   container.withVolumeMountsMixin([
    //     volumeMount.withName(this.configVolumeName)
    //     + volumeMount.withMountPath(mountPath),
    //   ]),

    deployment+:
      deployment.spec.template.metadata.withAnnotationsMixin({
        [configHashName]: std.md5(std.toString(data)),
      })
      + kausal.util.configVolumeMount(
        configVolumeName,
        mountPath,
        if std.isEmpty(subPath) then {} else volumeMount.withSubPath(subPath)
      )
    ,

    statefulset+:
      statefulset.spec.template.metadata.withAnnotations({
        [configHashName]: std.md5(std.toString(data)),
      })
      + kausal.util.configVolumeMount(
        configVolumeName,
        mountPath,
        if std.isEmpty(subPath) then {} else volumeMount.withSubPath(subPath)
      )
    ,

    daemonset+:
      daemonset.spec.template.metadata.withAnnotationsMixin({
        [configHashName]: std.md5(std.toString(data)),
      })
      + kausal.util.configVolumeMount(
        configVolumeName,
        mountPath,
        if std.isEmpty(subPath) then {} else volumeMount.withSubPath(subPath)
      )
    ,

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

    container+:
      container.withVolumeMountsMixin([
        volumeMount.new(self.dataVolumeName, mountPath),
      ]),

    initContainer+:
      container.withVolumeMountsMixin([
        volumeMount.new(self.dataVolumeName, mountPath),
      ]),

    dataPvc:
      pvc.new(this.dataVolumeName)
      + pvc.spec.resources.withRequests({ storage: size })
      + pvc.spec.withAccessModes(['ReadWriteOnce'])
      + pvc.spec.withStorageClassName(storageClass)
      + pvc.mixin.metadata.withLabels({ app: this.appName }),

    deployment+:
      deployment.spec.template.spec.withVolumesMixin([
        volume.fromPersistentVolumeClaim(self.dataVolumeName, this.dataPvc.metadata.name),
      ]),

    statefulset+:
      statefulset.spec.withVolumeClaimTemplatesMixin(
        this.dataPvc
      )

      + statefulset.spec.template.spec.withVolumesMixin([
        volume.fromPersistentVolumeClaim(self.dataVolumeName, this.dataPvc.metadata.name),
      ]),

    backup+:
      restic.withPVC(this.pvcFinalName, mountPath),
  },

  withCharDevice(volumeName, mountPath, mount=true): {
    local this = self,

    // Disabling mount is useful when withContainers() includes additional
    // contianers and not all contianers need the char device.
    container+:
      if mount then
        container.withVolumeMountsMixin([
          volumeMount.new(volumeName, mountPath),
        ])
      else {},

    deployment+:
      deployment.spec.template.spec.withVolumesMixin([
        volume.fromHostPath(volumeName, mountPath)
        + volume.hostPath.withType('CharDevice'),
      ]),

    statefulset+:
      statefulset.spec.template.spec.withVolumesMixin([
        volume.fromHostPath(volumeName, mountPath)
        + volume.hostPath.withType('CharDevice'),
      ]),
  },

  withHostMount(volumeName, mountPath, readOnly=true): {
    local this = self,

    container+:
      container.withVolumeMountsMixin([
        volumeMount.new(volumeName, mountPath, readOnly),
      ]),

    deployment+:
      deployment.spec.template.spec.withVolumesMixin([
        volume.fromHostPath(volumeName, mountPath),
      ]),

    daemonset+:
      daemonset.spec.template.spec.withVolumesMixin([
        volume.fromHostPath(volumeName, mountPath),
      ]),

    statefulset+:
      statefulset.spec.template.spec.withVolumesMixin([
        volume.fromHostPath(volumeName, mountPath),
      ]),

    cronJob+:
      cronJob.spec.jobTemplate.spec.template.spec.withVolumesMixin([
        volume.fromHostPath(volumeName, mountPath),
      ]),


  },

  withDeployment(): {
    workload: self.deployment,
    service: self.svc,
  },

  withStatefulSet(): {
    workload: self.statefulset,
    service: self.svc,
    pvcFinalName: '%s-%s-0' % [self.dataVolumeName, self.appName],
  },

  withDaemonSet(): {
    workload: self.daemonset,
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

    exporter_container::
      container.new('exporter', image)
      + container.withPorts([
        containerPort.new('http-metrics', port),
      ])
      + container.withArgs(args)
      + container.withEnvMixin(env)
      + kausal.util.resourcesRequests('10m', '100Mi')
      + kausal.util.resourcesLimits('500m', '1Gi'),

    deployment+::
      deployment.spec.template.metadata.withAnnotationsMixin({
        exporter_container_hash: std.md5(std.toString(this.exporter_container)),
      })
      + deployment.spec.template.spec.withContainersMixin(
        this.exporter_container
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

    container+::
      container.withVolumeMountsMixin([
        volumeMount.new(volumeName, mountPath),
      ]),

    deployment+::
      deployment.mixin.spec.template.spec.withVolumesMixin([
        volume.withName(volumeName)
        + volume.nfs.withPath(nfsPath)
        + volume.nfs.withServer(nfsServer),
      ]),
  },

  withReplicas(replicas): {
    deployment+:
      deployment.spec.withReplicas(replicas),

    statefulset+:
      statefulset.spec.withReplicas(replicas),
  },

  withServicePorts(ports=[]): {
    svc+:
      service.spec.withPortsMixin(
        ports
      ),
  },

  withPullPolicy(policy='IfNotPresent'): {
    container+:
      container.withImagePullPolicy(policy),
  },
}
