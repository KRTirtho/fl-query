---
title: Optimistic Updates
sidebar_position: 10
---

### What is Optimistic UI Update?

> <em>In an optimistic update the UI behaves as though a change was successfully completed before receiving confirmation from the server that it actually was - it is being optimistic that it will eventually get the confirmation rather than an error. This allows for a more responsive user experience.</em>
>
> Source: https://stackoverflow.com/a/33009713/13292290

# Update from Mutation Response

When dealing with mutations that **update** documents/tables on the server, it's common for the new data to be automatically returned in the response of the `mutation`. Instead of refetching any queries for that item and wasting a network call for data we already have, we can take advantage of the object returned by the mutation function and update the existing query with the new data immediately using the `QueryBowl`'s `setQueryData` method:

```dart
return MutationBuilder(
  job: mutationJob,
  onSuccess: (data) {
    QueryBowl.of(context)
        .setQueryData<String, void>(successJob.queryKey, (_oldData) {
      return data;
    });
  }
);
```

# onMutate Event Callback

`onMutate` callback of `MutationBuilder` runs before the mutation task defined in the `MutationJob` is executed. It gives access to mutation variables in the Callback too thus queries or any other source of data can be updated with predicted data to make user experience a lot smoother


```dart
return MutationBuilder(
  job: mutationJob,
  onMutate: (variable) {
    final data = QueryBowl.of(context).getQuery(successJob.queryKey)?.data;
    QueryBowl.of(context)
        .setQueryData<Map<String, dynamic>, void>(successJob.queryKey, (oldData) {
      // replacing the soon to be expired data with updated data
      return {...oldData, ...variable};
    });

    // here we should be able to return a previous snapshot 
    // of the intended query data which can be used when 
    // an error occurs in mutation & we can rollback to a previous
    // data set
    return data;
  },
  onData: (data, variables, context) {
    print("Passed Variable: $variables");
    print("Safe Previous Value: $context");
  },
  onError: (data, variables, context) {
    print("Passed Variable: $variables");
    print("Safe Previous Value: $context");
  }
);
```