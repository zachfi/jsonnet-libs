local config = import 'jsonnet/config.jsonnet';

local versions = [
  '0.7.5',
  '0.7.4',
  '0.7.3',
  '0.7.2',
  '0.7.1',
  '0.7.0',
  '0.6.9',
  '0.6.8',
  '0.6.7',
  '0.6.6',
  '0.6.5',
];

// The files in new versions were moved here:
local path = 'https://raw.githubusercontent.com/zachfi/nodemanager/v%s/config/crd/bases/';

local crds = [
  'common.nodemanager_configsets.yaml',
  'common.nodemanager_managednodes.yaml',
  'freebsd.nodemanager_jails.yaml',
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
