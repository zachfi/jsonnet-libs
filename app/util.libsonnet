// A useful utility for deploying apps on Kubernetes with Jsonnet.
//
// Usage / ordering:
//   1. app.new(appName, image, namespace)
//   2. Choose workload: withDeployment(), withStatefulSet(), or withDaemonSet()
//   3. withService() if you need a Service
//   4. withPDB(), withVPA() — call after (2) so workload is set
//   5. Other mixins (ports, volumes, certificate, topology spread, etc.) in any order
//   Include in manifest output as needed: workload, service, and any of pdb, vpa,
//   certificate, configmap_*, sidecarCronConfigMaps, pv, pvc.
//
// Backup (restic) is decoupled from the app. The app does not expose backup methods or
// a backup: key. Instead, define the app as a top-level key (e.g. myapp: app.new(...)),
// then create a separate key (e.g. myapp_backup: restic.resticForApp(self.myapp, opts)).
// That gives explicit control over the restic CronJob and its resources; the CronJob
// uses pod affinity to run on the same nodes as the workload so local PVCs are available.
// Include in manifest: backup.scriptsConfigMap, backup.configSecret, backup.cron.
//
{
  local k = import 'k.libsonnet',

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
  local pdb = k.policy.v1.podDisruptionBudget,
  local pvc = k.core.v1.persistentVolumeClaim,
  local pv = k.core.v1.persistentVolume,
  local service = k.core.v1.service,
  local statefulset = k.apps.v1.statefulSet,
  local volume = k.core.v1.volume,
  local volumeMount = k.core.v1.volumeMount,

  local tls = import 'github.com/zachfi/jsonnet-libs/tls/util.libsonnet',
  local vpa = import 'github.com/jsonnet-libs/vertical-pod-autoscaler-libsonnet/1.0.0/main.libsonnet',
  local verticalPodAutoscaler = vpa.autoscaling.v1.verticalPodAutoscaler,

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
    isStatefulSet:: false,
    volumeClaimTemplates:: [],

    // volumes and mounts are realized by the default workload objects.
    volumes:: [],
    mounts:: [],

    defaultContainer(name, image)::
      container.new(name, image)
      + container.withImagePullPolicy('IfNotPresent')
      + container.withVolumeMounts(this.mounts)
    ,

    container:: this.defaultContainer(appName, image),
    extraContainers:: [],
    initContainers:: [],

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
      + deployment.spec.template.spec.withInitContainers(this.initContainers)
    ,

    statefulset::
      statefulset.new(appName, 1, this.container,)
      + statefulset.spec.withServiceName(appName)
      + statefulset.spec.withVolumeClaimTemplates(this.volumeClaimTemplates)
      + statefulset.spec.persistentVolumeClaimRetentionPolicy.withWhenDeleted('Retain')
      + statefulset.spec.updateStrategy.rollingUpdate.withMaxUnavailable(1)
      + statefulset.spec.template.metadata.withAnnotations(this.annotations)
      + statefulset.spec.template.spec.withContainers([this.container] + this.extraContainers)
      + statefulset.spec.template.spec.withVolumes(this.volumes)
      + statefulset.spec.template.spec.withInitContainers(this.initContainers)
    ,

    daemonset::
      daemonset.new(appName, this.container,)
      + daemonset.spec.template.metadata.withAnnotations(this.annotations)
      + daemonset.spec.template.spec.withContainers([this.container] + this.extraContainers)
      + daemonset.spec.template.spec.withVolumes(this.volumes)
      + daemonset.spec.template.spec.withInitContainers(this.initContainers)
    ,

    cronJob::
      local this = self;
      cronJob.new(appName, '*/3 * * * *', [this.container])
      + cronJob.spec.jobTemplate.spec.withTtlSecondsAfterFinished(300)  // 1 week
      + cronJob.spec.jobTemplate.spec.withBackoffLimit(1)
      + cronJob.spec.jobTemplate.spec.template.spec.withRestartPolicy('Never')
      + cronJob.spec.jobTemplate.spec.template.spec.withVolumes(this.volumes),

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
      cronJob.spec.jobTemplate.spec.template.spec.withNodeSelector(hsh),
  },

  withTerminationGracePeriodSeconds(seconds): {
    deployment+:
      deployment.spec.template.spec.withTerminationGracePeriodSeconds(seconds),

    statefulset+:
      statefulset.spec.template.spec.withTerminationGracePeriodSeconds(seconds),

    daemonset+:
      daemonset.spec.template.spec.withTerminationGracePeriodSeconds(seconds),

    cronJob+:
      cronJob.spec.jobTemplate.spec.template.spec.withTerminationGracePeriodSeconds(seconds),
  },

  // withTopologySpreadConstraints sets pod topology spread (e.g. zone spreading).
  // Build constraints with your k8s lib (e.g. k.core.v1.topologySpreadConstraint).
  // Example (exact API may vary by k lib version; use appName from new() for selector):
  //   local tsc = k.core.v1.topologySpreadConstraint;
  //   + app.withTopologySpreadConstraints([
  //       tsc.new()
  //       + tsc.withMaxSkew(1)
  //       + tsc.withTopologyKey('topology.kubernetes.io/zone')
  //       + tsc.withWhenUnsatisfiable('DoNotSchedule')
  //       + tsc.labelSelector.withMatchLabels({ name: appName }),
  //     ])
  withTopologySpreadConstraints(constraints): {
    deployment+:
      deployment.spec.template.spec.withTopologySpreadConstraints(constraints),

    statefulset+:
      statefulset.spec.template.spec.withTopologySpreadConstraints(constraints),

    daemonset+:
      daemonset.spec.template.spec.withTopologySpreadConstraints(constraints),
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
      deployment.spec.template.spec.withServiceAccountName(name),

    statefulset+:
      statefulset.spec.template.spec.withServiceAccountName(name),

    daemonset+:
      daemonset.spec.template.spec.withServiceAccountName(name),
  },

  // tld: cluster DNS domain (e.g. 'cluster.local')
  withCertificate(issuer='vault-issuer', tld='cluster.local', altNames=[], mountPath='/tls'): {
    local this = self,
    local certVolume = volume.fromSecret(this.tlsVolumeName, this.tlsVolumeName),

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

    // Add TLS volume directly to each workload so the volume is always present
    // (avoids "volume not found" when spec is built from this.volumes in some evaluation contexts).
    // Use withVolumesMixin so we don't assume spec.template.spec.volumes exists yet.
    deployment+:
      deployment.spec.template.spec.withVolumesMixin([certVolume]),
    statefulset+:
      statefulset.spec.template.spec.withVolumesMixin([certVolume]),
    daemonset+:
      daemonset.spec.template.spec.withVolumesMixin([certVolume]),

    // Stakater Reloader: when this secret changes, Reloader restarts the
    // workload. Requires the Reloader controller to be installed (e.g. via
    // Helm chart). Annotation format: secret.reloader.stakater.com/reload
    annotations+: {
      'secret.reloader.stakater.com/reload': this.tlsVolumeName,
    },

  },

  withInitContainer(c): {
    local this = self,

    initContainers+: [
      c
      + container.withVolumeMountsMixin(this.mounts),
    ],
  },

  // The received container must include the /bin/bash binary.
  withCronSidecarContainer(c, hook='', interval=10000, path='/scripts'):: {
    local this = self,
    local name = '%s-%s' % [this.appName, c.name],
    local volumeName = '%s-cron' % name,

    sidecarCronConfigMaps+: [
      configMap.new(volumeName)
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

    // The mount is intended to only used by this container.
    local containerMount = volumeMount.new(volumeName, path),

    // The volume needs to be included on the workload we can mount it in this container.
    volumes+: [
      volume.fromConfigMap(volumeName, volumeName),
    ],

    extraContainers+: [
      c
      + container.withVolumeMountsMixin([containerMount])
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
  withCronSidecar(name, image, hook='', sleep=10000, path='/scripts'):: {
    local this = self,
    local volumeName = '%s-cron' % name,

    sidecarCronConfigMaps+: [
      configMap.new(volumeName)
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

    local containerMount = volumeMount.new(volumeName, path),

    local cronContainer =
      this.defaultContainer(name, image)
      + container.withCommand(['/bin/bash'])
      + container.withArgs([
        '%s/cron.sh' % path,
      ])
      + container.withVolumeMountsMixin([containerMount])
    ,

    // The volume needs to be included on the workload we can mount it in this container.
    volumes+: [
      volume.fromConfigMap(volumeName, volumeName),
    ],

    extraContainers+: [cronContainer],

    annotations+: {
      [name + '_container_hash']: std.md5(std.toString(cronContainer)),
    },
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

  withInitChown(path, uid, gid):: {
    local this = self,

    initContainers+: [
      container.new('init-chown', 'alpine:latest')
      + container.securityContext.withRunAsUser(0)
      + container.withCommand([
        'sh',
        '-c',
        '(chmod 0775 %(p)s; chgrp %(g)s %(p)s)' % { p: path, g: gid },
      ])
      + container.withVolumeMountsMixin(this.mounts),
    ],
  },

  withFsPermissions(uid, gid): {
    // This worked for the init container to restore the data, but when
    // starting the another container, root was now not root, so was unable to
    // mkdir in /var/run (owned by root).  Not sure the right workaround.

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

  // withPDB adds a PodDisruptionBudget for the workload. Call after
  // withDeployment()/withStatefulSet()/withDaemonSet() so the selector
  // matches the workload. Use maxUnavailable (int or string, e.g. "25%") or
  // minAvailable, but not both.
  withPDB(maxUnavailable=1, minAvailable=null): {
    local this = self,

    pdb:
      pdb.new(this.appName)
      + pdb.metadata.withNamespace(this.app.namespace)
      + pdb.metadata.withLabels({ name: this.appName })
      + pdb.spec.selector.withMatchLabels(this.workload.spec.selector.matchLabels)
      + (
        if minAvailable != null then
          pdb.spec.withMinAvailable(minAvailable)
        else
          pdb.spec.withMaxUnavailable(maxUnavailable)
      ),
  },

  // withVPA adds a VerticalPodAutoscaler targeting the workload. Call after
  // withDeployment()/withStatefulSet()/withDaemonSet(). When using VPA to
  // manage resources, do not set resources on the workload (omit withResources)
  // so VPA is the single source of truth and the workload is not deployed with
  // conflicting or stale values. Optional containerPolicies can be passed
  // for full control; if omitted, a default policy is built for the first
  // container using controlledResources and min/max cpu/memory (all optional).
  // controlledResources is a list of resource names, e.g. ['cpu', 'memory'].
  withVPA(
    updateMode='Auto',
    minReplicas=1,
    containerPolicies=null,
    controlledResources=['cpu', 'memory'],
    minCpu='50m',
    maxCpu='2',
    minMemory='64Mi',
    maxMemory='2Gi',
  ): {
    local this = self,

    local minAllowed = (
      (if minCpu != null then { cpu: minCpu } else {})
      + (if minMemory != null then { memory: minMemory } else {})
    ),
    local maxAllowed = (
      (if maxCpu != null then { cpu: maxCpu } else {})
      + (if maxMemory != null then { memory: maxMemory } else {})
    ),

    local defaultPolicy =
      verticalPodAutoscaler.spec.resourcePolicy.containerPolicies.withContainerName(this.container.name)
      + verticalPodAutoscaler.spec.resourcePolicy.containerPolicies.withMode('Auto')
      + verticalPodAutoscaler.spec.resourcePolicy.containerPolicies.withControlledValues('RequestsAndLimits')
      + verticalPodAutoscaler.spec.resourcePolicy.containerPolicies.withControlledResources(controlledResources)
      + (if std.length(minAllowed) > 0 then verticalPodAutoscaler.spec.resourcePolicy.containerPolicies.withMinAllowed(minAllowed) else {})
      + (if std.length(maxAllowed) > 0 then verticalPodAutoscaler.spec.resourcePolicy.containerPolicies.withMaxAllowed(maxAllowed) else {}),

    local policies = if containerPolicies != null then
      containerPolicies
    else
      [defaultPolicy],

    vpa:
      verticalPodAutoscaler.new(this.appName)
      + verticalPodAutoscaler.metadata.withNamespace(this.app.namespace)
      + verticalPodAutoscaler.spec.withTargetRef(this.workload)
      + verticalPodAutoscaler.spec.updatePolicy.withUpdateMode(updateMode)
      + verticalPodAutoscaler.spec.updatePolicy.withMinReplicas(minReplicas)
      + verticalPodAutoscaler.spec.resourcePolicy.withContainerPolicies(policies),
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

  // withMatchLabels adds the given labels to both the workload selector
  // (spec.selector.matchLabels) and the pod template (spec.template.metadata.labels),
  // so selector and template stay in sync. Use for labels that identify which pods
  // belong to this workload. For labels only on the pod template (e.g. display or
  // app.kubernetes.io/component), add them via the workload’s template elsewhere.
  withMatchLabels(matchers={}): {
    deployment+:
      deployment.spec.template.metadata.withLabelsMixin(matchers)
      + deployment.spec.selector.withMatchLabels(matchers),

    statefulset+:
      statefulset.spec.template.metadata.withLabelsMixin(matchers)
      + statefulset.spec.selector.withMatchLabels(matchers),
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

    annotations+: {
      [configHashName]: std.md5(std.toString(data)),
    },

    mounts+: [
      volumeMount.withName(configVolumeName)
      + volumeMount.withMountPath(mountPath)
      + (if std.isEmpty(subPath) then {} else volumeMount.withSubPath(subPath)),
    ],

    volumes+: [
      volume.fromConfigMap(configVolumeName, configVolumeName),
    ],
  },

  // withLocalDataMount adds a PVC and mounts it on the workload. To back it up
  // with restic, use restic.resticForApp(app, { ..., backupTargets: [{
  // volumeName: this.dataVolumeName, mountPath }], ... }) and pass the same
  // volumeName and mountPath.
  // Add the volume directly to each workload (withVolumesMixin) so it is present
  // regardless of evaluation order; do not add to this.volumes to avoid duplicate.
  withLocalDataMount(mountPath='/data', storageClass='local-path', size='10Gi'): {
    local this = self,
    local dataVol = volume.fromPersistentVolumeClaim(this.dataVolumeName, this.dataVolumeName),

    mounts+: [
      volumeMount.new(this.dataVolumeName, mountPath),
    ],

    deployment+:
      deployment.spec.template.spec.withVolumesMixin([dataVol]),
    statefulset+:
      statefulset.spec.template.spec.withVolumesMixin([dataVol]),
    daemonset+:
      daemonset.spec.template.spec.withVolumesMixin([dataVol]),

    local dataPvc =
      pvc.new(this.dataVolumeName)
      + pvc.spec.resources.withRequests({ storage: size })
      + pvc.spec.withAccessModes(['ReadWriteOnce'])
      + pvc.spec.withStorageClassName(storageClass)
      + pvc.metadata.withLabels({ app: this.appName }),

    volumeClaimTemplates+:: [dataPvc],
    pvc+: if this.isStatefulSet then [] else [dataPvc],
  },

  withCharDevice(volumeName, mountPath, mount=true): {
    local this = self,

    // Disabling mount is useful when withContainer() includes additional
    // containers and not all containers need the char device.
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
    isStatefulSet:: true,
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
    local this = self,

    cronJob+:
      cronJob.spec.withSchedule(schedule),

    cron: this.cronJob,
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
      + container.resources.withRequests({ cpu: '10m', memory: '100Mi' })
      + container.resources.withLimits({ cpu: '500m', memory: '1Gi' }),

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

  // withResources sets requests and/or limits on the main container. Pass
  // objects with keys such as cpu and memory (e.g. requests={ cpu: '100m',
  // memory: '128Mi' }). Only non-empty objects are applied.
  withResources(requests={}, limits={}): {
    container+:
      (if std.length(requests) > 0 then container.resources.withRequests(requests) else {})
      + (if std.length(limits) > 0 then container.resources.withLimits(limits) else {}),
  },

  // withHttpProbe adds readiness and liveness HTTP GET probes to the main
  // container. By default both probes use the same path and port; pass
  // separate livenessPath/livenessPort to override the liveness target.
  withHttpProbe(
    path='/ready',
    port='http',
    initialDelaySeconds=10,
    periodSeconds=10,
    timeoutSeconds=5,
    failureThreshold=3,
    livenessPath=null,
    livenessPort=null,
  ): {
    local lPath = if livenessPath != null then livenessPath else path,
    local lPort = if livenessPort != null then livenessPort else port,

    container+:
      container.readinessProbe.httpGet.withPath(path)
      + container.readinessProbe.httpGet.withPort(port)
      + container.readinessProbe.withInitialDelaySeconds(initialDelaySeconds)
      + container.readinessProbe.withPeriodSeconds(periodSeconds)
      + container.readinessProbe.withTimeoutSeconds(timeoutSeconds)
      + container.readinessProbe.withFailureThreshold(failureThreshold)
      + container.livenessProbe.httpGet.withPath(lPath)
      + container.livenessProbe.httpGet.withPort(lPort)
      + container.livenessProbe.withInitialDelaySeconds(initialDelaySeconds)
      + container.livenessProbe.withPeriodSeconds(periodSeconds)
      + container.livenessProbe.withTimeoutSeconds(timeoutSeconds)
      + container.livenessProbe.withFailureThreshold(failureThreshold),
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

    pvc+: [
      pvc.new(volumeName)
      + pvc.spec.resources.withRequests({ storage: '1Mi' })
      + pvc.spec.withAccessModes(['ReadWriteMany'])
      // + pvc.mixin.metadata.withLabels({ app: self.app.name })
      + pvc.spec.withStorageClassName(''),
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

  withPVCMount(volumeName, mountPath, readOnly=false): {
    local this = self,

    mounts+: [
      volumeMount.new(volumeName, mountPath, readOnly),
    ],

    volumes+: [
      volume.fromPersistentVolumeClaim(volumeName, volumeName),
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
