local config = import 'jsonnet/config.jsonnet';

local versions = [
  '0.6.4',
  '0.5.21',
];

// The files in new versions were moved here:
local path = 'https://raw.githubusercontent.com/zachfi/nodemanager/v%s/config/crd/bases/';

local crds = [
  'common.nodemanager_configsets.yaml',
  'common.nodemanager_managednodes.yaml',
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
