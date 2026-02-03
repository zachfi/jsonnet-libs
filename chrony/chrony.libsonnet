{
  local k = import 'k.libsonnet',

  local app = import 'github.com/zachfi/jsonnet-libs/app/util.libsonnet',

  local container = k.core.v1.container,
  local containerPort = k.core.v1.containerPort,
  local volumeMount = k.core.v1.volumeMount,

  local app_name = 'chrony',

  local localtime_file = 'etclocaltime',

  // namespace: namespace for both client and server (used in client config to target the server).
  // clusterDomain: Kubernetes cluster DNS domain (e.g. 'cluster.local'); used for in-cluster server address.
  // serverName: name of the chrony server service (client config will use serverName.namespace.svc.clusterDomain).
  // image: container image for chrony client and server (and gpsd when using withGPSDevice).
  new(namespace='time', clusterDomain='cluster.local', serverName='chrony-server', image='zachfi/chrony:latest'): {
    local this = self,

    image:: image,
    gpsDeviceVolumeName:: 'gps-device',
    chronyClientConfigVolumeName:: 'chrony-client-config',
    chronyServerConfigVolumeName:: 'chrony-server-config',

    local clientData = {
      'chrony.conf': this.clientConfig,
    },

    local serverData = {
      'chrony.conf': this.serverConfig,
    },

    local serverAddr = '%s.%s.svc.%s' % [serverName, namespace, clusterDomain],

    clientConfig:: |||
      server %(serverAddr)s

      server 0.us.pool.ntp.org
      server 1.us.pool.ntp.org
      server 2.us.pool.ntp.org
      server 3.us.pool.ntp.org

      #cmdallow 127/8
      driftfile /var/lib/chrony/drift
      #local stratum 10
      makestep .1 -1
      rtcsync
      rtconutc
      allow
    ||| % { serverAddr: serverAddr },

    serverConfig:: |||
      server 0.us.pool.ntp.org
      server 1.us.pool.ntp.org
      server 2.us.pool.ntp.org
      server 3.us.pool.ntp.org

      driftfile /var/lib/chrony/drift
      makestep .1 -1

      allow

      #refclock SOCK /run/chrony.ttyACM0.sock refid GPS  precision 1e-3 offset 0.011
      #refclock SOCK /run/chrony.pps0.sock    refid PPS  precision 1e-7
      refclock SHM  0                        refid NMEA precision 1e-3 poll 3 offset 0.011 
    |||,

    client:
      app.new('chrony-client', image, namespace)
      + app.withDaemonSet()
      + app.withHostMount(localtime_file, '/etc/localtime')
      + app.withConfigmapMount('/etc/chrony.conf', clientData, 'chrony.conf')
        {
        container+::
          container.withImagePullPolicy('Always')
          + container.withPorts([
            containerPort.newNamedUDP(123, 'ntp'),
          ])
          + container.withArgs([
            'chronyd',
            '-d',
            '-s',
            '-f',
            '/etc/chrony.conf',
          ])
          + container.mixin.securityContext.capabilities.withAdd('SYS_TIME')
          + this.limits
          + this.readinessProbe
          + this.livenessProbe,
      },


    server:
      app.new('chrony-server', image, namespace)
      + app.withDeployment()
      + app.withHostMount(localtime_file, '/etc/localtime')
      + app.withConfigmapMount('/etc/chrony.conf', serverData, 'chrony.conf')
      + app.withInet6Only()
        {
        container+::
          container.withImagePullPolicy('Always')
          + container.withPorts([
            containerPort.newNamedUDP(123, 'ntp'),
          ])
          + container.withArgs([
            'chronyd',
            '-d',
            '-s',
            '-f',
            '/etc/chrony.conf',
          ])
          + container.mixin.securityContext.capabilities.withAdd('SYS_TIME')
          + this.limits
          + this.readinessProbe
          + this.livenessProbe,
      },

    readinessProbe::
      container.readinessProbe.exec.withCommand(['chronyc', 'tracking'])
      + container.mixin.readinessProbe.withInitialDelaySeconds(10)
      + container.mixin.readinessProbe.withPeriodSeconds(30)
      + container.mixin.readinessProbe.withTimeoutSeconds(5),

    livenessProbe::
      container.livenessProbe.exec.withCommand(['chronyc', 'tracking'])
      + container.mixin.livenessProbe.withInitialDelaySeconds(10)
      + container.mixin.livenessProbe.withPeriodSeconds(30)
      + container.mixin.livenessProbe.withTimeoutSeconds(5),

    limits::
      container.resources.withRequests({ cpu: '10m', memory: '10Mi' })
      + container.resources.withLimits({ cpu: '250m', memory: '50Mi' }),
  },

  withGPSDevice(device='/dev/ttyACM0', nodeKey='gps_device', nodeValue='ttyACM0'): {
    local this = self,

    gpsdContainer::
      container.new('gpsd', this.image)
      + container.withImagePullPolicy('Always')
      + container.withArgs([
        'gpsd',
        '-b',
        '-N',
        '-n',
        '-G',
        '-D',
        '5',
        '-F',
        '/run/gpsd.sock',
        device,
      ])
      + container.securityContext.withPrivileged(true)
      + container.withVolumeMounts([
        volumeMount.new(localtime_file, '/etc/localtime', true),
        volumeMount.new(this.gpsDeviceVolumeName, device),
      ]),

    server+:
      app.withContainer('gpsd', this.gpsdContainer)
      + app.withCharDevice(this.gpsDeviceVolumeName, device, false)
      + app.withNodeSelector({ [nodeKey]: nodeValue }),

    client+:
      app.withAntiNodeSelector(nodeKey, nodeValue),
  },

  withExternalAddresses(addresses): {
    server+:
      app.withExternalAddresses(addresses),
  },
}
