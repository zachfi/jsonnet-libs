local config = import 'jsonnet/config.jsonnet';

local versions = [
  'main',
];

// The files in new versions were moved here:
local path = 'https://raw.githubusercontent.com/zachfi/iotcontroller/%s/config/crd/bases/';

local crds = [
  'iot.iot_conditions.yaml',
  'iot.iot_devices.yaml',
  'iot.iot_devicetypes.yaml',
  'iot.iot_scenes.yaml',
  'iot.iot_zones.yaml',
];

config.new(
  name='iotcontroller',
  specs=[
    {
      output: version,
      prefix: '',
      crds: [
        (path % version) + crd
        for crd in crds
      ],
      localName: 'iotcontroller',
    }
    for version in versions
  ]
)
