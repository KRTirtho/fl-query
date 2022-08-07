---
title: Dynamic Mutations
sidebar_position: 9
---

Just like [Dynamic Queries](/docs/basics/DynamicQueries), `MutationJob.withVariableKey` makes the mutation dynamic. Both of them are completely same

```dart
final mutationVariableKeyJob = MutationJob.withVariableKey<String, double>(
  preMutationKey: "mutation-example",
  task: (mutationKey, variables) {
    return MyAPI.submit({...variables, id: getVariable(mutationKey)});
  },
);
```

In the case of Mutation, we've `preMutationKey` instead of `preQueryKey`

You can use the dynamic Mutation Job just like any other `MutationJob` except you've to invoke the defined dynamic mutation & pass the `variable-mutation-key` as the first argument.


```dart
MutationBuilder<String, double>(
  job: mutationVariableKeyJob(id),
  builder: (context, mutation) {...},
)
```