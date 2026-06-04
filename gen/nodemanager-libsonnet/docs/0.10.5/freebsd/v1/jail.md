---
permalink: /0.10.5/freebsd/v1/jail/
---

# freebsd.v1.jail

"Jail is the Schema for the jails API."

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
  * [`fn withDeletionProtection(deletionProtection)`](#fn-specwithdeletionprotection)
  * [`fn withHostname(hostname)`](#fn-specwithhostname)
  * [`fn withInet(inet)`](#fn-specwithinet)
  * [`fn withInet6(inet6)`](#fn-specwithinet6)
  * [`fn withInterface(interface)`](#fn-specwithinterface)
  * [`fn withMounts(mounts)`](#fn-specwithmounts)
  * [`fn withMountsMixin(mounts)`](#fn-specwithmountsmixin)
  * [`fn withNodeName(nodeName)`](#fn-specwithnodename)
  * [`fn withParameters(parameters)`](#fn-specwithparameters)
  * [`fn withParametersMixin(parameters)`](#fn-specwithparametersmixin)
  * [`fn withRelease(release)`](#fn-specwithrelease)
  * [`fn withTemplateRef(templateRef)`](#fn-specwithtemplateref)
  * [`obj spec.mounts`](#obj-specmounts)
    * [`fn withHostPath(hostPath)`](#fn-specmountswithhostpath)
    * [`fn withJailPath(jailPath)`](#fn-specmountswithjailpath)
    * [`fn withReadOnly(readOnly)`](#fn-specmountswithreadonly)
    * [`fn withType(type)`](#fn-specmountswithtype)
  * [`obj spec.pf`](#obj-specpf)
    * [`fn withAnchorName(anchorName)`](#fn-specpfwithanchorname)
    * [`fn withRules(rules)`](#fn-specpfwithrules)
    * [`fn withRulesMixin(rules)`](#fn-specpfwithrulesmixin)
  * [`obj spec.update`](#obj-specupdate)
    * [`fn withDelay(delay)`](#fn-specupdatewithdelay)
    * [`fn withGroup(group)`](#fn-specupdatewithgroup)
    * [`fn withSchedule(schedule)`](#fn-specupdatewithschedule)

## Fields

### fn new

```ts
new(name)
```

new returns an instance of Jail

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

"JailSpec defines the desired state of Jail."

### fn spec.withDeletionProtection

```ts
withDeletionProtection(deletionProtection)
```

"DeletionProtection prevents the jail from being deleted when set to true.\nThe controller will block deletion by holding the finalizer until this\nfield is explicitly set to false.  Use this to guard important jails\nagainst accidental kubectl delete."

### fn spec.withHostname

```ts
withHostname(hostname)
```

"Hostname is the jail's internal hostname. Defaults to the resource name."

### fn spec.withInet

```ts
withInet(inet)
```

"Inet is the IPv4 address assigned to the jail (CIDR or bare IP)."

### fn spec.withInet6

```ts
withInet6(inet6)
```

"Inet6 is the IPv6 address assigned to the jail (CIDR or bare IP)."

### fn spec.withInterface

```ts
withInterface(interface)
```

"Interface is the network interface to attach to the jail."

### fn spec.withMounts

```ts
withMounts(mounts)
```

"Mounts defines additional filesystem mounts made available inside the jail\nvia a per-jail fstab file."

### fn spec.withMountsMixin

```ts
withMountsMixin(mounts)
```

"Mounts defines additional filesystem mounts made available inside the jail\nvia a per-jail fstab file."

**Note:** This function appends passed data to existing values

### fn spec.withNodeName

```ts
withNodeName(nodeName)
```

"NodeName restricts reconciliation to the nodemanager instance running on\nthe named host. If empty the jail is ignored by all nodes."

### fn spec.withParameters

```ts
withParameters(parameters)
```

"Parameters holds additional jail(8) parameters written into the\njail.conf fragment. An empty string value emits a bare flag (e.g.\nallow.mount.zfs;); a non-empty value emits key = value; (e.g.\nchildren.max = 5;)."

### fn spec.withParametersMixin

```ts
withParametersMixin(parameters)
```

"Parameters holds additional jail(8) parameters written into the\njail.conf fragment. An empty string value emits a bare flag (e.g.\nallow.mount.zfs;); a non-empty value emits key = value; (e.g.\nchildren.max = 5;)."

**Note:** This function appends passed data to existing values

### fn spec.withRelease

```ts
withRelease(release)
```

"Release is the FreeBSD release version to use (e.g. \"14.2-RELEASE\")."

### fn spec.withTemplateRef

```ts
withTemplateRef(templateRef)
```

"TemplateRef is the name of a JailTemplate in the same namespace.\nWhen set, the template's defaults are merged under this spec's values\n(jail-level fields take precedence over template defaults)."

## obj spec.mounts

"Mounts defines additional filesystem mounts made available inside the jail\nvia a per-jail fstab file."

### fn spec.mounts.withHostPath

```ts
withHostPath(hostPath)
```

"HostPath is the absolute path on the host to expose inside the jail."

### fn spec.mounts.withJailPath

```ts
withJailPath(jailPath)
```

"JailPath is the absolute path inside the jail root where HostPath is mounted."

### fn spec.mounts.withReadOnly

```ts
withReadOnly(readOnly)
```

"ReadOnly mounts the filesystem read-only."

### fn spec.mounts.withType

```ts
withType(type)
```

"Type is the filesystem type. Defaults to \"nullfs\"."

## obj spec.pf

"PF configures a PF anchor for this jail. When set, the controller loads\nthe declared rules into a per-jail anchor on every reconcile and flushes\nthe anchor when the jail is deleted."

### fn spec.pf.withAnchorName

```ts
withAnchorName(anchorName)
```

"AnchorName is the PF anchor to manage. Defaults to \"jails/<jailname>\"."

### fn spec.pf.withRules

```ts
withRules(rules)
```

"Rules is the ordered list of PF rule strings loaded into the anchor.\nRules are passed verbatim to pfctl; the anchor is fully replaced on each\nreconcile. An empty list flushes the anchor."

### fn spec.pf.withRulesMixin

```ts
withRulesMixin(rules)
```

"Rules is the ordered list of PF rule strings loaded into the anchor.\nRules are passed verbatim to pfctl; the anchor is fully replaced on each\nreconcile. An empty list flushes the anchor."

**Note:** This function appends passed data to existing values

## obj spec.update

"Update controls periodic freebsd-update(8) runs for this jail."

### fn spec.update.withDelay

```ts
withDelay(delay)
```

"Delay is the minimum time between updates (e.g. \"24h\")."

### fn spec.update.withGroup

```ts
withGroup(group)
```

"Group is a lease group name.  Only one jail in the group will run\nfreebsd-update at a time, preventing concurrent disruption across hosts."

### fn spec.update.withSchedule

```ts
withSchedule(schedule)
```

"Schedule is a cron expression for when updates should run."