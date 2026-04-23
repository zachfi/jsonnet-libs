local config = import 'jsonnet/config.jsonnet';

local versions = [
  '0.10.4',
  '0.10.3',
  '0.10.2',
  '0.10.1',
  '0.10.0',
  '0.9.11',
];

// The files in new versions were moved here:
local path = 'https://raw.githubusercontent.com/zachfi/nodemanager/v%s/config/crd/bases/';

local crds = [
  'common.nodemanager_configsets.yaml',
  'common.nodemanager_managednodes.yaml',
  'freebsd.nodemanager_jails.yaml',
  'freebsd.nodemanager_jailtemplates.yaml',
  'freebsd.nodemanager_poudrierebulks.yaml',
  'freebsd.nodemanager_poudrierejails.yaml',
  'freebsd.nodemanager_poudriereports.yaml',
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
