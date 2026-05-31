local config = import 'jsonnet/config.jsonnet';

local versions = [
  '0.19.0',
  '0.18.1',
  '0.17.0',
  '0.16.4',
  '0.15.1',
  '0.14.0',
  '0.13.13',
  '0.13.12',
  '0.13.10',
  '0.13.8',
  '0.13.7',
  '0.13.6',
  '0.13.4',
  '0.13.3',
  '0.13.2',
  '0.12.7',
  '0.12.5',
  '0.12.4',
  '0.12.3',
  '0.12.2',
  '0.12.1',
  '0.11.0',
  '0.10.15',
  '0.10.14',
  '0.10.13',
  '0.10.11',
  '0.10.10',
  '0.10.9',
  '0.10.8',
  '0.10.7',
  '0.10.6',
  '0.10.5',
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
