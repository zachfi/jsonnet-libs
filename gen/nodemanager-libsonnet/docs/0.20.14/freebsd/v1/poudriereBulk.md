---
permalink: /0.20.14/freebsd/v1/poudriereBulk/
---

# freebsd.v1.poudriereBulk

"PoudriereBulk is the Schema for the poudrierebulks API"

## Index

* [`fn new(name)`](#fn-new)
* [`obj metadata`](#obj-metadata)
  * [`fn withAnnotations(annotations)`](#fn-metadatawithannotations)
  * [`fn withAnnotationsMixin(annotations)`](#fn-metadatawithannotationsmixin)
  * [`fn withClusterName(clusterName)`](#fn-metadatawithclustername)
  * [`fn withCreationTimestamp(creationTimestamp)`](#fn-metadatawithcreationtimestamp)
  * [`fn withDeletionGracePeriodSeconds(deletionGracePeriodSeconds)`](#fn-metadatawithdeletiongraceperiodseconds)
  * [`fn withDeletionTimestamp(deletionTimestamp)`](#fn-metadatawithdeletiontimestamp)
  * [`fn withFinalizers(finalizers)`](#fn-metadatawithfinalizers)
  * [`fn withFinalizersMixin(finalizers)`](#fn-metadatawithfinalizersmixin)
  * [`fn withGenerateName(generateName)`](#fn-metadatawithgeneratename)
  * [`fn withGeneration(generation)`](#fn-metadatawithgeneration)
  * [`fn withLabels(labels)`](#fn-metadatawithlabels)
  * [`fn withLabelsMixin(labels)`](#fn-metadatawithlabelsmixin)
  * [`fn withName(name)`](#fn-metadatawithname)
  * [`fn withNamespace(namespace)`](#fn-metadatawithnamespace)
  * [`fn withOwnerReferences(ownerReferences)`](#fn-metadatawithownerreferences)
  * [`fn withOwnerReferencesMixin(ownerReferences)`](#fn-metadatawithownerreferencesmixin)
  * [`fn withResourceVersion(resourceVersion)`](#fn-metadatawithresourceversion)
  * [`fn withSelfLink(selfLink)`](#fn-metadatawithselflink)
  * [`fn withUid(uid)`](#fn-metadatawithuid)
* [`obj spec`](#obj-spec)
  * [`fn withJail(jail)`](#fn-specwithjail)
  * [`fn withPorts(ports)`](#fn-specwithports)
  * [`fn withPortsMixin(ports)`](#fn-specwithportsmixin)
  * [`fn withReconcilePeriod(reconcilePeriod)`](#fn-specwithreconcileperiod)
  * [`fn withTree(tree)`](#fn-specwithtree)
  * [`obj spec.executor`](#obj-specexecutor)
    * [`fn withType(type)`](#fn-specexecutorwithtype)
    * [`obj spec.executor.command`](#obj-specexecutorcommand)
      * [`fn withDispatch(dispatch)`](#fn-specexecutorcommandwithdispatch)
      * [`fn withDispatchMixin(dispatch)`](#fn-specexecutorcommandwithdispatchmixin)
      * [`fn withDispatchTimeout(dispatchTimeout)`](#fn-specexecutorcommandwithdispatchtimeout)
      * [`fn withEnv(env)`](#fn-specexecutorcommandwithenv)
      * [`fn withEnvMixin(env)`](#fn-specexecutorcommandwithenvmixin)
      * [`fn withSecretEnv(secretEnv)`](#fn-specexecutorcommandwithsecretenv)
      * [`fn withSecretEnvMixin(secretEnv)`](#fn-specexecutorcommandwithsecretenvmixin)
      * [`fn withStatusTimeout(statusTimeout)`](#fn-specexecutorcommandwithstatustimeout)
      * [`obj spec.executor.command.env`](#obj-specexecutorcommandenv)
        * [`fn withName(name)`](#fn-specexecutorcommandenvwithname)
        * [`fn withValue(value)`](#fn-specexecutorcommandenvwithvalue)
        * [`obj spec.executor.command.env.valueFrom`](#obj-specexecutorcommandenvvaluefrom)
          * [`obj spec.executor.command.env.valueFrom.configMapKeyRef`](#obj-specexecutorcommandenvvaluefromconfigmapkeyref)
            * [`fn withKey(key)`](#fn-specexecutorcommandenvvaluefromconfigmapkeyrefwithkey)
            * [`fn withName(name)`](#fn-specexecutorcommandenvvaluefromconfigmapkeyrefwithname)
            * [`fn withOptional(optional)`](#fn-specexecutorcommandenvvaluefromconfigmapkeyrefwithoptional)
          * [`obj spec.executor.command.env.valueFrom.fieldRef`](#obj-specexecutorcommandenvvaluefromfieldref)
            * [`fn withApiVersion(apiVersion)`](#fn-specexecutorcommandenvvaluefromfieldrefwithapiversion)
            * [`fn withFieldPath(fieldPath)`](#fn-specexecutorcommandenvvaluefromfieldrefwithfieldpath)
          * [`obj spec.executor.command.env.valueFrom.fileKeyRef`](#obj-specexecutorcommandenvvaluefromfilekeyref)
            * [`fn withKey(key)`](#fn-specexecutorcommandenvvaluefromfilekeyrefwithkey)
            * [`fn withOptional(optional)`](#fn-specexecutorcommandenvvaluefromfilekeyrefwithoptional)
            * [`fn withPath(path)`](#fn-specexecutorcommandenvvaluefromfilekeyrefwithpath)
            * [`fn withVolumeName(volumeName)`](#fn-specexecutorcommandenvvaluefromfilekeyrefwithvolumename)
          * [`obj spec.executor.command.env.valueFrom.resourceFieldRef`](#obj-specexecutorcommandenvvaluefromresourcefieldref)
            * [`fn withContainerName(containerName)`](#fn-specexecutorcommandenvvaluefromresourcefieldrefwithcontainername)
            * [`fn withDivisor(divisor)`](#fn-specexecutorcommandenvvaluefromresourcefieldrefwithdivisor)
            * [`fn withResource(resource)`](#fn-specexecutorcommandenvvaluefromresourcefieldrefwithresource)
          * [`obj spec.executor.command.env.valueFrom.secretKeyRef`](#obj-specexecutorcommandenvvaluefromsecretkeyref)
            * [`fn withKey(key)`](#fn-specexecutorcommandenvvaluefromsecretkeyrefwithkey)
            * [`fn withName(name)`](#fn-specexecutorcommandenvvaluefromsecretkeyrefwithname)
            * [`fn withOptional(optional)`](#fn-specexecutorcommandenvvaluefromsecretkeyrefwithoptional)
      * [`obj spec.executor.command.secretEnv`](#obj-specexecutorcommandsecretenv)
        * [`fn withName(name)`](#fn-specexecutorcommandsecretenvwithname)
        * [`obj spec.executor.command.secretEnv.secretRef`](#obj-specexecutorcommandsecretenvsecretref)
          * [`fn withKey(key)`](#fn-specexecutorcommandsecretenvsecretrefwithkey)
          * [`fn withName(name)`](#fn-specexecutorcommandsecretenvsecretrefwithname)
          * [`fn withOptional(optional)`](#fn-specexecutorcommandsecretenvsecretrefwithoptional)

## Fields

### fn new

```ts
new(name)
```

new returns an instance of PoudriereBulk

## obj metadata

"ObjectMeta is metadata that all persisted resources must have, which includes all objects users must create."

### fn metadata.withAnnotations

```ts
withAnnotations(annotations)
```

"Annotations is an unstructured key value map stored with a resource that may be set by external tools to store and retrieve arbitrary metadata. They are not queryable and should be preserved when modifying objects. More info: http://kubernetes.io/docs/user-guide/annotations"

### fn metadata.withAnnotationsMixin

```ts
withAnnotationsMixin(annotations)
```

"Annotations is an unstructured key value map stored with a resource that may be set by external tools to store and retrieve arbitrary metadata. They are not queryable and should be preserved when modifying objects. More info: http://kubernetes.io/docs/user-guide/annotations"

**Note:** This function appends passed data to existing values

### fn metadata.withClusterName

```ts
withClusterName(clusterName)
```

"The name of the cluster which the object belongs to. This is used to distinguish resources with same name and namespace in different clusters. This field is not set anywhere right now and apiserver is going to ignore it if set in create or update request."

### fn metadata.withCreationTimestamp

```ts
withCreationTimestamp(creationTimestamp)
```

"Time is a wrapper around time.Time which supports correct marshaling to YAML and JSON.  Wrappers are provided for many of the factory methods that the time package offers."

### fn metadata.withDeletionGracePeriodSeconds

```ts
withDeletionGracePeriodSeconds(deletionGracePeriodSeconds)
```

"Number of seconds allowed for this object to gracefully terminate before it will be removed from the system. Only set when deletionTimestamp is also set. May only be shortened. Read-only."

### fn metadata.withDeletionTimestamp

```ts
withDeletionTimestamp(deletionTimestamp)
```

"Time is a wrapper around time.Time which supports correct marshaling to YAML and JSON.  Wrappers are provided for many of the factory methods that the time package offers."

### fn metadata.withFinalizers

```ts
withFinalizers(finalizers)
```

"Must be empty before the object is deleted from the registry. Each entry is an identifier for the responsible component that will remove the entry from the list. If the deletionTimestamp of the object is non-nil, entries in this list can only be removed. Finalizers may be processed and removed in any order.  Order is NOT enforced because it introduces significant risk of stuck finalizers. finalizers is a shared field, any actor with permission can reorder it. If the finalizer list is processed in order, then this can lead to a situation in which the component responsible for the first finalizer in the list is waiting for a signal (field value, external system, or other) produced by a component responsible for a finalizer later in the list, resulting in a deadlock. Without enforced ordering finalizers are free to order amongst themselves and are not vulnerable to ordering changes in the list."

### fn metadata.withFinalizersMixin

```ts
withFinalizersMixin(finalizers)
```

"Must be empty before the object is deleted from the registry. Each entry is an identifier for the responsible component that will remove the entry from the list. If the deletionTimestamp of the object is non-nil, entries in this list can only be removed. Finalizers may be processed and removed in any order.  Order is NOT enforced because it introduces significant risk of stuck finalizers. finalizers is a shared field, any actor with permission can reorder it. If the finalizer list is processed in order, then this can lead to a situation in which the component responsible for the first finalizer in the list is waiting for a signal (field value, external system, or other) produced by a component responsible for a finalizer later in the list, resulting in a deadlock. Without enforced ordering finalizers are free to order amongst themselves and are not vulnerable to ordering changes in the list."

**Note:** This function appends passed data to existing values

### fn metadata.withGenerateName

```ts
withGenerateName(generateName)
```

"GenerateName is an optional prefix, used by the server, to generate a unique name ONLY IF the Name field has not been provided. If this field is used, the name returned to the client will be different than the name passed. This value will also be combined with a unique suffix. The provided value has the same validation rules as the Name field, and may be truncated by the length of the suffix required to make the value unique on the server.\n\nIf this field is specified and the generated name exists, the server will NOT return a 409 - instead, it will either return 201 Created or 500 with Reason ServerTimeout indicating a unique name could not be found in the time allotted, and the client should retry (optionally after the time indicated in the Retry-After header).\n\nApplied only if Name is not specified. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#idempotency"

### fn metadata.withGeneration

```ts
withGeneration(generation)
```

"A sequence number representing a specific generation of the desired state. Populated by the system. Read-only."

### fn metadata.withLabels

```ts
withLabels(labels)
```

"Map of string keys and values that can be used to organize and categorize (scope and select) objects. May match selectors of replication controllers and services. More info: http://kubernetes.io/docs/user-guide/labels"

### fn metadata.withLabelsMixin

```ts
withLabelsMixin(labels)
```

"Map of string keys and values that can be used to organize and categorize (scope and select) objects. May match selectors of replication controllers and services. More info: http://kubernetes.io/docs/user-guide/labels"

**Note:** This function appends passed data to existing values

### fn metadata.withName

```ts
withName(name)
```

"Name must be unique within a namespace. Is required when creating resources, although some resources may allow a client to request the generation of an appropriate name automatically. Name is primarily intended for creation idempotence and configuration definition. Cannot be updated. More info: http://kubernetes.io/docs/user-guide/identifiers#names"

### fn metadata.withNamespace

```ts
withNamespace(namespace)
```

"Namespace defines the space within which each name must be unique. An empty namespace is equivalent to the \"default\" namespace, but \"default\" is the canonical representation. Not all objects are required to be scoped to a namespace - the value of this field for those objects will be empty.\n\nMust be a DNS_LABEL. Cannot be updated. More info: http://kubernetes.io/docs/user-guide/namespaces"

### fn metadata.withOwnerReferences

```ts
withOwnerReferences(ownerReferences)
```

"List of objects depended by this object. If ALL objects in the list have been deleted, this object will be garbage collected. If this object is managed by a controller, then an entry in this list will point to this controller, with the controller field set to true. There cannot be more than one managing controller."

### fn metadata.withOwnerReferencesMixin

```ts
withOwnerReferencesMixin(ownerReferences)
```

"List of objects depended by this object. If ALL objects in the list have been deleted, this object will be garbage collected. If this object is managed by a controller, then an entry in this list will point to this controller, with the controller field set to true. There cannot be more than one managing controller."

**Note:** This function appends passed data to existing values

### fn metadata.withResourceVersion

```ts
withResourceVersion(resourceVersion)
```

"An opaque value that represents the internal version of this object that can be used by clients to determine when objects have changed. May be used for optimistic concurrency, change detection, and the watch operation on a resource or set of resources. Clients must treat these values as opaque and passed unmodified back to the server. They may only be valid for a particular resource or set of resources.\n\nPopulated by the system. Read-only. Value must be treated as opaque by clients and . More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#concurrency-control-and-consistency"

### fn metadata.withSelfLink

```ts
withSelfLink(selfLink)
```

"SelfLink is a URL representing this object. Populated by the system. Read-only.\n\nDEPRECATED Kubernetes will stop propagating this field in 1.20 release and the field is planned to be removed in 1.21 release."

### fn metadata.withUid

```ts
withUid(uid)
```

"UID is the unique in time and space value for this object. It is typically generated by the server on successful creation of a resource and is not allowed to change on PUT operations.\n\nPopulated by the system. Read-only. More info: http://kubernetes.io/docs/user-guide/identifiers#uids"

## obj spec

"PoudriereBulkSpec defines the desired state of PoudriereBulk."

### fn spec.withJail

```ts
withJail(jail)
```

"Jail is the poudriere build jail name (the -j argument). Must match\nthe metadata.name of a PoudriereJail in the same namespace."

### fn spec.withPorts

```ts
withPorts(ports)
```

"Ports is the list of port origins (e.g. \"net/curl\", \"shells/zsh\") to\nbuild. Each entry is passed as a separate argument to `poudriere bulk`."

### fn spec.withPortsMixin

```ts
withPortsMixin(ports)
```

"Ports is the list of port origins (e.g. \"net/curl\", \"shells/zsh\") to\nbuild. Each entry is passed as a separate argument to `poudriere bulk`."

**Note:** This function appends passed data to existing values

### fn spec.withReconcilePeriod

```ts
withReconcilePeriod(reconcilePeriod)
```

"ReconcilePeriod controls how often the controller re-runs portshaker\nand `poudriere bulk` even without a Kubernetes event.  Use this to\nturn the controller into a scheduled build loop.  Examples: \"1h\",\n\"6h\", \"24h\".  Empty or zero means event-driven only — a build runs\nonly when the spec changes or an external trigger fires (such as a\nForgejo push annotation, see Phase 4)."

### fn spec.withTree

```ts
withTree(tree)
```

"Tree is the poudriere ports tree name (the -p argument). Must match\nthe metadata.name of a PoudrierePorts in the same namespace."

## obj spec.executor

"Executor selects how the build is performed.  When unset the bulk\nruns in-process on the reconciler's host (backward-compatible with\nv0.14.x).  Set Executor.Type=Command to dispatch the build to a\nseparate build system via an external program; see CommandExecutor\nand docs/poudriere/command-contract.md."

### fn spec.executor.withType

```ts
withType(type)
```

"Type selects the executor.  See the BulkExecutorType constants."

## obj spec.executor.command

"Command configures the external program when Type=Command.  Ignored\nfor other Types.  See CommandExecutor for the contract."

### fn spec.executor.command.withDispatch

```ts
withDispatch(dispatch)
```

"Dispatch is the executable + arguments invoked when starting a\nbuild.  argv[0] must be an absolute path (no $PATH lookup at the\nCR level — operators put the program where they want and reference\nit explicitly).  See docs/poudriere/command-contract.md."

### fn spec.executor.command.withDispatchMixin

```ts
withDispatchMixin(dispatch)
```

"Dispatch is the executable + arguments invoked when starting a\nbuild.  argv[0] must be an absolute path (no $PATH lookup at the\nCR level — operators put the program where they want and reference\nit explicitly).  See docs/poudriere/command-contract.md."

**Note:** This function appends passed data to existing values

### fn spec.executor.command.withDispatchTimeout

```ts
withDispatchTimeout(dispatchTimeout)
```

"DispatchTimeout caps the dispatch invocation.  Parsed by\ntime.ParseDuration; defaults to 60s when empty."

### fn spec.executor.command.withEnv

```ts
withEnv(env)
```

"Env is explicit environment passed to Dispatch and Status.  Layers\nover (and replaces matching keys from) the allowlisted host\nenvironment.  Use SecretEnv for credentials."

### fn spec.executor.command.withEnvMixin

```ts
withEnvMixin(env)
```

"Env is explicit environment passed to Dispatch and Status.  Layers\nover (and replaces matching keys from) the allowlisted host\nenvironment.  Use SecretEnv for credentials."

**Note:** This function appends passed data to existing values

### fn spec.executor.command.withSecretEnv

```ts
withSecretEnv(secretEnv)
```

"SecretEnv exposes Secret keys as environment variables to the\nexecutor program.  Resolved at every reconcile (so Secret rotation\nis automatic) and never written to disk or logged by name.  This\nis where credentials such as a Forgejo personal access token live."

### fn spec.executor.command.withSecretEnvMixin

```ts
withSecretEnvMixin(secretEnv)
```

"SecretEnv exposes Secret keys as environment variables to the\nexecutor program.  Resolved at every reconcile (so Secret rotation\nis automatic) and never written to disk or logged by name.  This\nis where credentials such as a Forgejo personal access token live."

**Note:** This function appends passed data to existing values

### fn spec.executor.command.withStatusTimeout

```ts
withStatusTimeout(statusTimeout)
```

"StatusTimeout caps the status invocation.  Parsed by\ntime.ParseDuration; defaults to 30s when empty."

## obj spec.executor.command.env

"Env is explicit environment passed to Dispatch and Status.  Layers\nover (and replaces matching keys from) the allowlisted host\nenvironment.  Use SecretEnv for credentials."

### fn spec.executor.command.env.withName

```ts
withName(name)
```

"Name of the environment variable.\nMay consist of any printable ASCII characters except '='."

### fn spec.executor.command.env.withValue

```ts
withValue(value)
```

"Variable references $(VAR_NAME) are expanded\nusing the previously defined environment variables in the container and\nany service environment variables. If a variable cannot be resolved,\nthe reference in the input string will be unchanged. Double $$ are reduced\nto a single $, which allows for escaping the $(VAR_NAME) syntax: i.e.\n\"$$(VAR_NAME)\" will produce the string literal \"$(VAR_NAME)\".\nEscaped references will never be expanded, regardless of whether the variable\nexists or not.\nDefaults to \"\"."

## obj spec.executor.command.env.valueFrom

"Source for the environment variable's value. Cannot be used if value is not empty."

## obj spec.executor.command.env.valueFrom.configMapKeyRef

"Selects a key of a ConfigMap."

### fn spec.executor.command.env.valueFrom.configMapKeyRef.withKey

```ts
withKey(key)
```

"The key to select."

### fn spec.executor.command.env.valueFrom.configMapKeyRef.withName

```ts
withName(name)
```

"Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names"

### fn spec.executor.command.env.valueFrom.configMapKeyRef.withOptional

```ts
withOptional(optional)
```

"Specify whether the ConfigMap or its key must be defined"

## obj spec.executor.command.env.valueFrom.fieldRef

"Selects a field of the pod: supports metadata.name, metadata.namespace, `metadata.labels['<KEY>']`, `metadata.annotations['<KEY>']`,\nspec.nodeName, spec.serviceAccountName, status.hostIP, status.podIP, status.podIPs."

### fn spec.executor.command.env.valueFrom.fieldRef.withApiVersion

```ts
withApiVersion(apiVersion)
```

"Version of the schema the FieldPath is written in terms of, defaults to \"v1\"."

### fn spec.executor.command.env.valueFrom.fieldRef.withFieldPath

```ts
withFieldPath(fieldPath)
```

"Path of the field to select in the specified API version."

## obj spec.executor.command.env.valueFrom.fileKeyRef

"FileKeyRef selects a key of the env file.\nRequires the EnvFiles feature gate to be enabled."

### fn spec.executor.command.env.valueFrom.fileKeyRef.withKey

```ts
withKey(key)
```

"The key within the env file. An invalid key will prevent the pod from starting.\nThe keys defined within a source may consist of any printable ASCII characters except '='.\nDuring Alpha stage of the EnvFiles feature gate, the key size is limited to 128 characters."

### fn spec.executor.command.env.valueFrom.fileKeyRef.withOptional

```ts
withOptional(optional)
```

"Specify whether the file or its key must be defined. If the file or key\ndoes not exist, then the env var is not published.\nIf optional is set to true and the specified key does not exist,\nthe environment variable will not be set in the Pod's containers.\n\nIf optional is set to false and the specified key does not exist,\nan error will be returned during Pod creation."

### fn spec.executor.command.env.valueFrom.fileKeyRef.withPath

```ts
withPath(path)
```

"The path within the volume from which to select the file.\nMust be relative and may not contain the '..' path or start with '..'."

### fn spec.executor.command.env.valueFrom.fileKeyRef.withVolumeName

```ts
withVolumeName(volumeName)
```

"The name of the volume mount containing the env file."

## obj spec.executor.command.env.valueFrom.resourceFieldRef

"Selects a resource of the container: only resources limits and requests\n(limits.cpu, limits.memory, limits.ephemeral-storage, requests.cpu, requests.memory and requests.ephemeral-storage) are currently supported."

### fn spec.executor.command.env.valueFrom.resourceFieldRef.withContainerName

```ts
withContainerName(containerName)
```

"Container name: required for volumes, optional for env vars"

### fn spec.executor.command.env.valueFrom.resourceFieldRef.withDivisor

```ts
withDivisor(divisor)
```

"Specifies the output format of the exposed resources, defaults to \"1\

### fn spec.executor.command.env.valueFrom.resourceFieldRef.withResource

```ts
withResource(resource)
```

"Required: resource to select"

## obj spec.executor.command.env.valueFrom.secretKeyRef

"Selects a key of a secret in the pod's namespace"

### fn spec.executor.command.env.valueFrom.secretKeyRef.withKey

```ts
withKey(key)
```

"The key of the secret to select from.  Must be a valid secret key."

### fn spec.executor.command.env.valueFrom.secretKeyRef.withName

```ts
withName(name)
```

"Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names"

### fn spec.executor.command.env.valueFrom.secretKeyRef.withOptional

```ts
withOptional(optional)
```

"Specify whether the Secret or its key must be defined"

## obj spec.executor.command.secretEnv

"SecretEnv exposes Secret keys as environment variables to the\nexecutor program.  Resolved at every reconcile (so Secret rotation\nis automatic) and never written to disk or logged by name.  This\nis where credentials such as a Forgejo personal access token live."

### fn spec.executor.command.secretEnv.withName

```ts
withName(name)
```

"Name is the environment variable name set in the executor's\nprocess environment (e.g. \"FORGEJO_TOKEN\").  Must be a valid\nPOSIX env var identifier."

## obj spec.executor.command.secretEnv.secretRef

"SecretRef points to the Secret + key whose value populates Name.\nThe Secret must exist in the same namespace as the PoudriereBulk."

### fn spec.executor.command.secretEnv.secretRef.withKey

```ts
withKey(key)
```

"The key of the secret to select from.  Must be a valid secret key."

### fn spec.executor.command.secretEnv.secretRef.withName

```ts
withName(name)
```

"Name of the referent.\nThis field is effectively required, but due to backwards compatibility is\nallowed to be empty. Instances of this type with an empty value here are\nalmost certainly wrong.\nMore info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names"

### fn spec.executor.command.secretEnv.secretRef.withOptional

```ts
withOptional(optional)
```

"Specify whether the Secret or its key must be defined"