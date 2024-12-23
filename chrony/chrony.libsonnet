{
  local k = import 'k.libsonnet',
  local kausal = import 'github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet',

  local app = import 'github.com/zachfi/jsonnet-libs/app/util.libsonnet',

  local container = k.core.v1.container,
  local containerPort = k.core.v1.containerPort,
  local volumeMount = k.core.v1.volumeMount,
  local deployment = k.apps.v1.deployment,
  local volume = k.core.v1.volume,

  local app_name = 'chrony',

  local localtime_file = 'etclocaltime',

  local image = 'zachfi/chrony:latest',

  new(): {
    local this = self,

    gpsDeviceVolumeName:: 'gps-device',
    chronyClientConfigVolumeName:: 'chrony-client-config',
    chronyServerConfigVolumeName:: 'chrony-server-config',
    // emptyVolumeName:: 'time-run',

    local clientData = {
      'chrony.conf': this.clientConfig,
    },

    local serverData = {
      'chrony.conf': this.serverConfig,
    },

    clientConfig:: |||
      server chrony-server.time.svc.cluster.znet

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
    |||,

    serverConfig:: |||
      server 0.us.pool.ntp.org
      server 1.us.pool.ntp.org
      server 2.us.pool.ntp.org
      server 3.us.pool.ntp.org

      driftfile /var/lib/chrony/drift
      makestep .1 -1

      allow
      rtcsync

      # gpsd looks for this path: /@RUNDIR@/chrony.XXX.sock
      # /var/run is a symlink to /run
      #refclock SOCK /run/chrony.ttyACM0.sock refid GPS precision 1e-3 offset 0.000
      #refclock SOCK /run/chrony.ttyACM0.sock refid GPS precision 1e-1 offset 0.9999
      #refclock SOCK /run/chrony.ttyACM0.sock refid PPS precision 1e-7

      # refclock SOCK /run/chrony.pps0.sock    refid PPS  precision 1e-7
      #refclock SHM 0 refid NMEA offset 0.000 precision 1e-3 poll 3 noselect
      # refclock SHM 0  delay 0.5 refid NMEA
      # SHM1 from gpsd (if present) is from the kernel PPS_LDISC
      # module.  It includes PPS and will be accurate to a few ns
      # refclock SHM 1 offset 0.0 delay 0.1 refid NMEA2
      # refclock PPS /run/pps0 refid PPS

      refclock SHM 0 refid GPS precision 1e-1 offset 0.9999 delay 0.2
      refclock SHM 1 refid PPS precision 1e-7
    |||,

    client:
      app.new('chrony-client', image, 'time')
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
      app.new('chrony-server', image, 'time')
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
          + container.securityContext.capabilities.withAdd('SYS_TIME')
          + this.limits
          + this.readinessProbe
          + this.livenessProbe,
      },

    readinessProbe::
      container.readinessProbe.exec.withCommand(['chronyc', 'tracking'])
      + container.mixin.readinessProbe.withInitialDelaySeconds(3)
      + container.mixin.readinessProbe.withPeriodSeconds(30)
      + container.mixin.readinessProbe.withTimeoutSeconds(5),

    livenessProbe::
      container.livenessProbe.exec.withCommand(['chronyc', 'tracking'])
      + container.mixin.livenessProbe.withInitialDelaySeconds(10)
      + container.mixin.livenessProbe.withPeriodSeconds(30)
      + container.mixin.livenessProbe.withTimeoutSeconds(5),

    limits::
      kausal.util.resourcesRequests('10m', '10Mi')
      + kausal.util.resourcesLimits('250m', '50Mi'),
  },

  withGPSDevice(device='/dev/ttyACM0', nodeKey='gps_device', nodeValue='ttyACM0'): {
    local this = self,

    gpsdContainer::
      container.new('gpsd', image)
      + container.withImagePullPolicy('Always')
      // + container.withCommand('/usr/sbin/gpsd')
      + container.withCommand(['sh', '-c'])
      // + container.withArgs([
      //   '-Nn',
      //   // '-b',
      //   // '-N',
      //   // '-n',
      //   // '-G',
      //   '-D2',
      //   // '-F',
      //   // '/run/gpsd.sock',
      //   device,
      // ])
      + container.withArgs([
        'sleep 10; echo "Starting"; gpsdebuginfo; gpsd -nN -D0 -F/run/gpsd.sock -r %s' % device,
      ])
      + container.securityContext.withPrivileged(true)
      + container.securityContext.withRunAsUser(0)
      + container.securityContext.withRunAsGroup(0)
      + container.securityContext.capabilities.withAdd('SYS_TIME')
      + container.withVolumeMounts([
        volumeMount.new(localtime_file, '/etc/localtime', true),
        volumeMount.new(this.gpsDeviceVolumeName, device),
        // volumeMount.new(this.emptyVolumeName, '/run'),
      ]),

    server+:
      app.withContainer('gpsd', this.gpsdContainer)
      + app.withCharDevice(this.gpsDeviceVolumeName, device, false)
      + app.withNodeSelector(nodeKey, nodeValue)
      + app.withEmptyMount('/run')
      + {
        deployment+::
          deployment.spec.strategy.rollingUpdate.withMaxSurge(0)
          + deployment.spec.strategy.rollingUpdate.withMaxUnavailable(1),
      }
    ,

    client+:
      app.withAntiNodeSelector(nodeKey, nodeValue),
  },

  withExternalAddresses(addresses): {
    server+:
      app.withExternalAddresses(addresses),
  },
}
