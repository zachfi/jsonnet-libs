// Chrony sample: client (DaemonSet) + server (Deployment) from chrony.libsonnet.
// Uses app/util via chrony; output for review and to scale the Makefile with future apps.
local chrony = import 'github.com/zachfi/jsonnet-libs/chrony/chrony.libsonnet';

local c = chrony.new();

// Client: DaemonSet + configmap. Server: Deployment + configmap. (No withService() in chrony.)
[
  c.client.workload,
  c.server.workload,
  c.client['configmap_config_chrony.conf_'],
  c.server['configmap_config_chrony.conf_'],
]
