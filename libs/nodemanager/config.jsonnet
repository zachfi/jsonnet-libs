local config = import 'jsonnet/config.jsonnet';

local versions = [
  '0.9.1',
  '0.9.0',
  '0.8.1',
  '0.8.0',
];

// The files in new versions were moved here:
local path = 'https://raw.githubusercontent.com/zachfi/nodemanager/v%s/config/crd/bases/';

local crds = [
  'common.nodemanager_configsets.yaml',
  'common.nodemanager_managednodes.yaml',
  'freebsd.nodemanager_jails.yaml',
  'freebsd.nodemanager_jailtemplates.yaml',
];

config.new(
  name='nodemanager-libsonnet',
  specs=[
    {
      output: version,
      prefix: '',
      crds: [
        (path % version) + crd
        for crd in crds
      ],
      localName: 'nodemanager',
    }
    for version in versions
  ]
)
{
  repository: self.name,
}
