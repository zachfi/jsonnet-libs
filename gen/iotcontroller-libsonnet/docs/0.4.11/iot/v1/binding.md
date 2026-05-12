---
permalink: /0.4.11/iot/v1/binding/
---

# iot.v1.binding

"Binding maps a normalized device event to a Condition. When the event fires from a device matching the selector, the named Condition's remediations are applied to its zones. This replaces hardcoded action strings in the router."

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
  * [`fn withCondition(condition)`](#fn-specwithcondition)
  * [`obj spec.event`](#obj-specevent)
    * [`fn withProperty(property)`](#fn-speceventwithproperty)
    * [`fn withValue(value)`](#fn-speceventwithvalue)
    * [`fn withValues(values)`](#fn-speceventwithvalues)
    * [`fn withValuesMixin(values)`](#fn-speceventwithvaluesmixin)
    * [`obj spec.event.selector`](#obj-speceventselector)
      * [`fn withDevice(device)`](#fn-speceventselectorwithdevice)
      * [`fn withDevice_type(device_type)`](#fn-speceventselectorwithdevice_type)
      * [`fn withIeee(ieee)`](#fn-speceventselectorwithieee)
      * [`fn withLabels(labels)`](#fn-speceventselectorwithlabels)
      * [`fn withLabelsMixin(labels)`](#fn-speceventselectorwithlabelsmixin)
      * [`fn withZone(zone)`](#fn-speceventselectorwithzone)

## Fields

### fn new

```ts
new(name)
```

new returns an instance of Binding

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

"BindingSpec defines an event → condition mapping. When the trigger event fires from a device matching the selector, the named Condition is activated."

### fn spec.withCondition

```ts
withCondition(condition)
```

"Condition is the name of the Condition resource to activate when this binding fires. The Condition must exist in the same namespace."

## obj spec.event

"Event matches a normalized device-emitted event by property and value. Both zigbee2mqtt and the native zigbee router normalize their incoming messages into the same Event shape so a single Binding works regardless of transport."

### fn spec.event.withProperty

```ts
withProperty(property)
```

"Property is the normalized expose name. Examples: \"action\", \"occupancy\", \"water_leak\", \"state\", \"contact\", \"tamper\"."

### fn spec.event.withValue

```ts
withValue(value)
```

"Value is the expected value rendered as a string. For booleans use \"true\" / \"false\". For action enums use the action name (e.g. \"single\", \"double\", \"on\"). May be empty to match any value of the property. Ignored when Values is non-empty."

### fn spec.event.withValues

```ts
withValues(values)
```

"Values is the list of accepted values for this trigger. Use this when a single Binding should match multiple device-specific action vocabularies for the same intent — e.g. [\"single\", \"1_single\", \"button_1_press\"] all meaning \"primary press.\" When Values is non-empty it takes precedence over Value. Multi-value matching is for *aliases of the same intent*; if you want different actions to trigger different Conditions, write separate Bindings."

### fn spec.event.withValuesMixin

```ts
withValuesMixin(values)
```

"Values is the list of accepted values for this trigger. Use this when a single Binding should match multiple device-specific action vocabularies for the same intent — e.g. [\"single\", \"1_single\", \"button_1_press\"] all meaning \"primary press.\" When Values is non-empty it takes precedence over Value. Multi-value matching is for *aliases of the same intent*; if you want different actions to trigger different Conditions, write separate Bindings."

**Note:** This function appends passed data to existing values

## obj spec.event.selector

"Selector restricts which devices can fire this binding. All non-empty fields must match the device. An empty selector matches every device that emitted the property."

### fn spec.event.selector.withDevice

```ts
withDevice(device)
```

"Device matches the device's CR name."

### fn spec.event.selector.withDevice_type

```ts
withDevice_type(device_type)
```

"DeviceType matches Spec.Type (e.g. \"DEVICE_TYPE_BUTTON\")."

### fn spec.event.selector.withIeee

```ts
withIeee(ieee)
```

"IEEE matches the device's 64-bit IEEE address (e.g. \"0xffffb40e06036411\")."

### fn spec.event.selector.withLabels

```ts
withLabels(labels)
```

"LabelSelector is an exact-match label set. Every key/value here must be present on the Device for the binding to fire."

### fn spec.event.selector.withLabelsMixin

```ts
withLabelsMixin(labels)
```

"LabelSelector is an exact-match label set. Every key/value here must be present on the Device for the binding to fire."

**Note:** This function appends passed data to existing values

### fn spec.event.selector.withZone

```ts
withZone(zone)
```

"Zone matches the device's `iot/zone` label."