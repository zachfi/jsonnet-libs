// Single app output: LDAP-style StatefulSet mock using only jsonnet-libs (app, tls, restic).
// No znet/* or ldif imports; inline mock data so this evaluates and generates useful manifests.
// Invocation pattern matches real usage: app.new + mixins, then restic.resticForApp at top level.
local app = import 'github.com/zachfi/jsonnet-libs/app/util.libsonnet';
local restic = import 'github.com/zachfi/jsonnet-libs/restic/restic.libsonnet';
local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.33/main.libsonnet';

local containerPort = k.core.v1.containerPort;
local envVar = k.core.v1.envVar;
local servicePort = k.core.v1.servicePort;

local namespace = 'auth';
local appName = 'ldap';
local image = 'bitnami/openldap:latest';

// Mock LDAP config (no znet/data or ldif files).
local ldifData = {
  'people.ldif': 'dn: ou=people\nou: people\n',
  'groups.ldif': 'dn: ou=groups\nou: groups\n',
};
local ldifConfigData = {
  'cn_config_init.ldif': 'dn: cn=config\nobjectClass: olcGlobal\ncn: config\n',
};

local ldap =
  app.new(appName, image, namespace)
  + app.withStatefulSet()
  + app.withRunAsNonRoot()
  + app.withReplicas(3)
  + app.withServicePorts(ports=[
    servicePort.newNamed('ldaps', 636, 1636),
    servicePort.newNamed('ldap', 389, 1389),
  ])
  + app.withInet6Only()
  + app.withService()
  + app.withPorts([
    containerPort.newNamed(1636, 'ldaps'),
    containerPort.newNamed(1389, 'ldap'),
  ])
  + app.withSessionAffinity('ClientIP')
  + app.withLocalDataMount('/bitnami/openldap', size='200Mi', storageClass='local-path')
  + app.withConfigmapMount('/ldifs', ldifData, nameOverride='%s-ldif' % appName)
  + app.withConfigmapMount('/ldif_config', ldifConfigData, nameOverride='%s-config-ldif' % appName)
  + app.withFsPermissions(1001, 1001)
  + app.withCertificate(
    tld='cluster.local',
    altNames=['ldap.auth.svc.cluster.local'],
    mountPath='/ldap/tls'
  )
  + app.withSelector({ app: appName, name: appName })
  + app.withAntiAffinity()
  + app.withEnvironmentMixin([
    envVar.new('LDAP_SKIP_DEFAULT_TREE', 'yes'),
    envVar.new('LDAP_ROOT', 'dc=znet'),
    envVar.new('LDAP_CUSTOM_LDIF_DIR', '/ldifs'),
    envVar.new('LDAP_ENABLE_TLS', 'yes'),
    envVar.new('LDAP_TLS_CERT_FILE', '/ldap/tls/tls.crt'),
    envVar.new('LDAP_TLS_KEY_FILE', '/ldap/tls/tls.key'),
    envVar.new('LDAP_TLS_CA_FILE', '/ldap/tls/ca.crt'),
  ]);

// Restic backup at top level (resticForApp); include its outputs in manifest.
local backup = restic.resticForApp(ldap, {
  bucketURL: 's3://mock-bucket',
  secretRefData: {
    accessKey: 'mock-access',
    secretKey: 'mock-secret',
    resticPassword: 'mock-restic-pw',
  },
  backupTargets: [
    { volumeName: ldap.dataVolumeName, mountPath: '/bitnami/openldap' },
  ],
  schedule: '0 */6 * * *',
  ttl: 86400,
  cert: { mountPath: '/ldap/tls', volumeName: ldap.tlsVolumeName },
  fsPermissions: { uid: 1001, gid: 1001 },
});

// Flatten all manifest objects for tk export.
[
  ldap.workload,
  ldap.service,
  ldap.certificate,
] + ldap.pvc
  + [
    backup.scriptsConfigMap,
    backup.configSecret,
    backup.backupCron,
  ]
  + [
    // ConfigMaps from withConfigmapMount (keys are dynamic).
    ldap['configmap_config__%s-ldif' % appName],
    ldap['configmap_config__%s-config-ldif' % appName],
  ]
