local config = import 'jsonnet/config.jsonnet';

local versions = [
  '0.5.4',
];

// The files in new versions were moved here:
local path = 'https://raw.githubusercontent.com/zachfi/nodemanager/v%s/config/crd/bases/';

config.new(
  name='nodemanager',
  specs=[
    {
      output: version,
      prefix: '',
      crds: [
        (path % version) + 'common.nodemanager_configsets.yaml',
        (path % version) + 'common.nodemanager_managednodes.yaml',
      ],
      localName: 'nodemanager',
    }
    for version in versions
  ]
)
