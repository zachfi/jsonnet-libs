# Compiled output and checks

This directory provides **compiled output** for multiple app samples that use `app/util.libsonnet` (and chrony, restic, etc.). You can review the generated manifests and CI runs `make -C compiled all` and fails if they are out of date.

## Layout

One directory per app sample; each has `main.jsonnet` and output in `compiled/<env>/gen/`:

```bash
find compiled/ -name main.jsonnet
# compiled/app/main.jsonnet
# compiled/chrony/main.jsonnet
```

The Makefile scales via **APP_ENVS**: add a new directory (e.g. `compiled/myapp/` with `main.jsonnet` and `spec.json`) and add its name to **APP_ENVS** in the Makefile.

## Usage

From the repo root:

```bash
make -C compiled all
```

From this directory:

```bash
make all
```

### Targets

| Target | Description |
|--------|-------------|
| **all** | Run `jb`, copy jsonnetfile, `gen`, then `check` (default). |
| **jb** | Install jsonnet deps at repo root and ensure same-repo import path (`vendor/github.com/zachfi/jsonnet-libs` → repo root). |
| **copy-jsonnetfile** | Copy `jsonnetfile.json` and `jsonnetfile.lock.json` into `out/` (local-only, not committed). |
| **gen** | For each **APP_ENVS** env: run `tk export` to a temp dir, then copy `*.yaml` into **compiled/<env>/gen/**. |
| **check** | Fail if there are uncommitted or untracked changes in any **compiled/<env>/gen**. Enforces: (1) all generated files tracked and up to date, (2) deleted files removed from git, (3) any diff → non-zero exit. |
| **clean** | Remove `out/`, all **compiled/<env>/gen**, and temp dirs. |

### Output

After `make gen`:

- **compiled/app/gen/*.yaml** – Manifests from the LDAP-style mock (StatefulSet, Service, Certificate, ConfigMaps, Secret, PVC, restic CronJob, etc.).
- **compiled/chrony/gen/*.yaml** – Chrony sample: client DaemonSet, server Deployment, and their ConfigMaps.
- **out/** – Local-only copy of `jsonnetfile.json` and `jsonnetfile.lock.json` (gitignored; not committed).

Only **compiled/<env>/gen/** is committed and checked. To have `make check` pass (e.g. in CI), commit every **compiled/<env>/gen/** so that re-running `gen` produces no diff; new files must be added, removed files must be deleted from the repo, and any change must be committed.

### Adding another app sample

1. Create **compiled/<name>/** with `spec.json` and `main.jsonnet` that imports and uses your lib (e.g. `app/util.libsonnet` or `chrony/chrony.libsonnet`) and returns a list of manifest objects.
2. Add `<name>` to **APP_ENVS** in the Makefile: `APP_ENVS ?= app chrony <name>`.
3. Run `make -C compiled gen` and commit **compiled/<name>/gen/*.yaml**.

## App samples

### app (LDAP-style mock)

**compiled/app/main.jsonnet** mirrors real usage with only in-repo libs:

- **app**: `app.new()` + `withStatefulSet()`, `withService()`, `withLocalDataMount()`, `withCertificate()`, `withConfigmapMount()`, `withFsPermissions()`, `withSelector()`, `withAntiAffinity()`, `withEnvironmentMixin()`, etc.
- **restic** at top level: `restic.resticForApp(ldap, { ... })`.
- No znet/* or ldif files; inline mock data.

### chrony

**compiled/chrony/main.jsonnet** uses **chrony** (`chrony/chrony.libsonnet`):

- `chrony.new()` returns client (DaemonSet) and server (Deployment), each with a ConfigMap for `chrony.conf`.
- Output: client workload, server workload, and both ConfigMaps for review.

## CI

The workflow in **.github/workflows/compiled-check.yml** runs on push/PR to `main` (or `master`). It installs `jb` and `tk`, then runs **make -C compiled all**. If you change jsonnet without re-running `make -C compiled gen` and committing the updated **compiled/*/gen/** files, CI fails.
