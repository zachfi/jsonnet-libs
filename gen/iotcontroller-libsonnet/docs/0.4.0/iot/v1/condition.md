---
permalink: /0.4.0/iot/v1/condition/
---

# iot.v1.condition

"Condition is the Schema for the conditions API"

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
  * [`fn withEnabled(enabled)`](#fn-specwithenabled)
  * [`fn withMatches(matches)`](#fn-specwithmatches)
  * [`fn withMatchesMixin(matches)`](#fn-specwithmatchesmixin)
  * [`fn withName(name)`](#fn-specwithname)
  * [`fn withRemediations(remediations)`](#fn-specwithremediations)
  * [`fn withRemediationsMixin(remediations)`](#fn-specwithremediationsmixin)
  * [`fn withSchedule(schedule)`](#fn-specwithschedule)
  * [`obj spec.matches`](#obj-specmatches)
    * [`fn withLabels(labels)`](#fn-specmatcheswithlabels)
    * [`fn withLabelsMixin(labels)`](#fn-specmatcheswithlabelsmixin)
  * [`obj spec.remediations`](#obj-specremediations)
    * [`fn withActive_scene(active_scene)`](#fn-specremediationswithactive_scene)
    * [`fn withActive_state(active_state)`](#fn-specremediationswithactive_state)
    * [`fn withInactive_scene(inactive_scene)`](#fn-specremediationswithinactive_scene)
    * [`fn withInactive_state(inactive_state)`](#fn-specremediationswithinactive_state)
    * [`fn withTime_intervals(time_intervals)`](#fn-specremediationswithtime_intervals)
    * [`fn withTime_intervalsMixin(time_intervals)`](#fn-specremediationswithtime_intervalsmixin)
    * [`fn withZone(zone)`](#fn-specremediationswithzone)
    * [`obj spec.remediations.time_intervals`](#obj-specremediationstime_intervals)
      * [`fn withDaysOfMonth(daysOfMonth)`](#fn-specremediationstime_intervalswithdaysofmonth)
      * [`fn withDaysOfMonthMixin(daysOfMonth)`](#fn-specremediationstime_intervalswithdaysofmonthmixin)
      * [`fn withLocation(location)`](#fn-specremediationstime_intervalswithlocation)
      * [`fn withMonths(months)`](#fn-specremediationstime_intervalswithmonths)
      * [`fn withMonthsMixin(months)`](#fn-specremediationstime_intervalswithmonthsmixin)
      * [`fn withTimes(times)`](#fn-specremediationstime_intervalswithtimes)
      * [`fn withTimesMixin(times)`](#fn-specremediationstime_intervalswithtimesmixin)
      * [`fn withWeekdays(weekdays)`](#fn-specremediationstime_intervalswithweekdays)
      * [`fn withWeekdaysMixin(weekdays)`](#fn-specremediationstime_intervalswithweekdaysmixin)
      * [`fn withYears(years)`](#fn-specremediationstime_intervalswithyears)
      * [`fn withYearsMixin(years)`](#fn-specremediationstime_intervalswithyearsmixin)
      * [`obj spec.remediations.time_intervals.times`](#obj-specremediationstime_intervalstimes)
        * [`fn withEnd_time(end_time)`](#fn-specremediationstime_intervalstimeswithend_time)
        * [`fn withStart_time(start_time)`](#fn-specremediationstime_intervalstimeswithstart_time)
    * [`obj spec.remediations.when_gate`](#obj-specremediationswhen_gate)
      * [`fn withStart(start)`](#fn-specremediationswhen_gatewithstart)
      * [`fn withStop(stop)`](#fn-specremediationswhen_gatewithstop)

## Fields

### fn new

```ts
new(name)
```

new returns an instance of Condition

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

"ConditionSpec defines the desired state of Condition"

### fn spec.withEnabled

```ts
withEnabled(enabled)
```



### fn spec.withMatches

```ts
withMatches(matches)
```



### fn spec.withMatchesMixin

```ts
withMatchesMixin(matches)
```



**Note:** This function appends passed data to existing values

### fn spec.withName

```ts
withName(name)
```



### fn spec.withRemediations

```ts
withRemediations(remediations)
```



### fn spec.withRemediationsMixin

```ts
withRemediationsMixin(remediations)
```



**Note:** This function appends passed data to existing values

### fn spec.withSchedule

```ts
withSchedule(schedule)
```

"A cron string: * * * * *"

## obj spec.matches



### fn spec.matches.withLabels

```ts
withLabels(labels)
```



### fn spec.matches.withLabelsMixin

```ts
withLabelsMixin(labels)
```



**Note:** This function appends passed data to existing values

## obj spec.remediations



### fn spec.remediations.withActive_scene

```ts
withActive_scene(active_scene)
```



### fn spec.remediations.withActive_state

```ts
withActive_state(active_state)
```



### fn spec.remediations.withInactive_scene

```ts
withInactive_scene(inactive_scene)
```



### fn spec.remediations.withInactive_state

```ts
withInactive_state(inactive_state)
```



### fn spec.remediations.withTime_intervals

```ts
withTime_intervals(time_intervals)
```

"TimeIntervals define the windows during which this remediation is applicable for Alerts.  If the conditioner receives an event outside of this range, the zone will be set to the inactive state, if defined in the condition spec."

### fn spec.remediations.withTime_intervalsMixin

```ts
withTime_intervalsMixin(time_intervals)
```

"TimeIntervals define the windows during which this remediation is applicable for Alerts.  If the conditioner receives an event outside of this range, the zone will be set to the inactive state, if defined in the condition spec."

**Note:** This function appends passed data to existing values

### fn spec.remediations.withZone

```ts
withZone(zone)
```



## obj spec.remediations.time_intervals

"TimeIntervals define the windows during which this remediation is applicable for Alerts.  If the conditioner receives an event outside of this range, the zone will be set to the inactive state, if defined in the condition spec."

### fn spec.remediations.time_intervals.withDaysOfMonth

```ts
withDaysOfMonth(daysOfMonth)
```

"DaysOfMonth accepts strings like \"1\", \"-1\" (last day), \"1:5\"."

### fn spec.remediations.time_intervals.withDaysOfMonthMixin

```ts
withDaysOfMonthMixin(daysOfMonth)
```

"DaysOfMonth accepts strings like \"1\", \"-1\" (last day), \"1:5\"."

**Note:** This function appends passed data to existing values

### fn spec.remediations.time_intervals.withLocation

```ts
withLocation(location)
```

"Location is the IANA Timezone string (e.g. \"America/New_York\")."

### fn spec.remediations.time_intervals.withMonths

```ts
withMonths(months)
```

"Months accepts strings like \"january\", \"march:may\"."

### fn spec.remediations.time_intervals.withMonthsMixin

```ts
withMonthsMixin(months)
```

"Months accepts strings like \"january\", \"march:may\"."

**Note:** This function appends passed data to existing values

### fn spec.remediations.time_intervals.withTimes

```ts
withTimes(times)
```

"Times is a list of start/end times. We use a local struct here to ensure deepcopy generation works."

### fn spec.remediations.time_intervals.withTimesMixin

```ts
withTimesMixin(times)
```

"Times is a list of start/end times. We use a local struct here to ensure deepcopy generation works."

**Note:** This function appends passed data to existing values

### fn spec.remediations.time_intervals.withWeekdays

```ts
withWeekdays(weekdays)
```

"Weekdays accepts strings like \"monday\", \"saturday\", \"monday:wednesday\"."

### fn spec.remediations.time_intervals.withWeekdaysMixin

```ts
withWeekdaysMixin(weekdays)
```

"Weekdays accepts strings like \"monday\", \"saturday\", \"monday:wednesday\"."

**Note:** This function appends passed data to existing values

### fn spec.remediations.time_intervals.withYears

```ts
withYears(years)
```

"Years accepts strings like \"2023\", \"2023:2025\"."

### fn spec.remediations.time_intervals.withYearsMixin

```ts
withYearsMixin(years)
```

"Years accepts strings like \"2023\", \"2023:2025\"."

**Note:** This function appends passed data to existing values

## obj spec.remediations.time_intervals.times

"Times is a list of start/end times. We use a local struct here to ensure deepcopy generation works."

### fn spec.remediations.time_intervals.times.withEnd_time

```ts
withEnd_time(end_time)
```



### fn spec.remediations.time_intervals.times.withStart_time

```ts
withStart_time(start_time)
```



## obj spec.remediations.when_gate

"WhenGate is relative to the Epoch event and is used to create an activation window. When the window opens, the zone is activated; when the window closes, the zone is deactivated."

### fn spec.remediations.when_gate.withStart

```ts
withStart(start)
```



### fn spec.remediations.when_gate.withStop

```ts
withStop(stop)
```

