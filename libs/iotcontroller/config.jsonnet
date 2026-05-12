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
//
// v0.4.11 carries the schema additions that landed during the Stage
// 1/2/3 work on the unified-evaluator plan: Binding.spec.event.values
// (cross-device action vocabularies), Remediation.active_brightness_delta
// (relative brightness adjust). The cluster had been hand-patched with
// kubectl apply -f for those fields since v0.4.8; this regen lets
// deployment_tools tk apply produce a strict-decoding-safe manifest
// without the workaround.
//
// v0.5.0 lands the unified-evaluator Stage 4 first PR: the eval-loop
// schema additions on the Condition CRD (Remediation.active_compute,
// Remediation.active_compute_args, TimeIntervalSpec.sun_relative with
// the SunWindow type). The Binding CRD is unchanged from v0.4.11.
local versionCrds = {
  '0.1.0': baseCrds,
  '0.2.0': baseCrds,
  '0.4.0': baseCrds + ['iot.iot_bindings.yaml'],
  '0.4.11': baseCrds + ['iot.iot_bindings.yaml'],
  '0.5.0': baseCrds + ['iot.iot_bindings.yaml'],
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
