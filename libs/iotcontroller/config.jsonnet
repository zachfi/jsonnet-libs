local config = import 'jsonnet/config.jsonnet';

// CRDs that have existed in every released version of iotcontroller.
local baseCrds = [
  'iot.iot_conditions.yaml',
  'iot.iot_devices.yaml',
  'iot.iot_devicetypes.yaml',
  'iot.iot_scenes.yaml',
  'iot.iot_zones.yaml',
];

// CRDs per version. Older versions stay frozen at their original
// shape; newer versions add resources as the API evolves.
//
// v0.4.0 introduces the Binding CRD with the Event trigger
// (replaces the v0.3.x ZCL/MQTT triggers, which never made it into
// any released libsonnet wrapper).
local versionCrds = {
  '0.1.0': baseCrds,
  '0.2.0': baseCrds,
  '0.4.0': baseCrds + ['iot.iot_bindings.yaml'],
};

local path = 'https://raw.githubusercontent.com/zachfi/iotcontroller/v%s/config/crd/bases/';

config.new(
  name='iotcontroller-libsonnet',
  specs=[
    {
      output: version,
      prefix: '',
      crds: [
        (path % version) + crd
        for crd in versionCrds[version]
      ],
      localName: 'iotcontroller',
    }
    for version in std.objectFields(versionCrds)
  ]
)
{
  repository: self.name,
}
