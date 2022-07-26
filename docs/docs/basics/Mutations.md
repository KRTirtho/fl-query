---
title: Mutations
sidebar_position: 6
---

Unlike queries, mutations are typically used to create/update/delete data or perform server side-effects. For this purpose, Fl-Query exports a `MutationBuilder` builder Widget.

Now, let's see previously created [`MutationJob`](/docs/basics/MutationJob) in action with `MutationBuilder`:

```dart
  @override
  Widget build(BuildContext context) {
    return MutationBuilder<Map, Map<String, dynamic>>(
      job: basicMutationJob, // the MutationJob we have created previously
      // you've the to the access to all the data & methods of [Mutation]
      builder: (context, mutation) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(labelText: "Body"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final title = titleController.value.text;
                  final body = bodyController.value.text;
                  if (body.isEmpty || title.isEmpty) return;
                  // running the mutation on Submit
                  mutation.mutate({
                    "title": title,
                    "body": body,
                    "id": id,
                  }, onData: (data) {
                    // resetting the form
                    titleController.text = "";
                    bodyController.text = "";
                  });
                },
                child: const Text("Post"),
              ),
              const SizedBox(height: 20),
              if (mutation.hasData) Text("Response\n${mutation.data}"),
              if (mutation.hasError) Text(mutation.error.toString()),
            ],
          ),
        );
      });
  }
```

A mutation can only be in one of the following states at any given moment:

- `isIdle` or status === 'idle' - The mutation is currently idle or in a fresh/reset state
- `isLoading` or status === 'loading' - The mutation is currently running
- `isError` or status === 'error' - The mutation encountered an error
- `isSuccess` or status === 'success' - The mutation was successful and mutation data is available

Beyond those primary states, more information is available depending on the state of the mutation:

- `hasError` - If the mutation is in an error state, the error is available via the `error` property.
- `hasData` - If the mutation is in a success state, the data is available via the `data` property.

In the example above, you also saw that you can pass variables to your mutations function by calling the `mutate` method with a **single variable or object**.

Even with just variables, mutations aren't all that special, but when used with the onSuccess option, the QueryBowl's `invalidateQueries` method and the QueryBowls's `setQueryData` method, mutations become a very powerful tool.

# Resetting Mutation State

It's sometimes the case that you need to clear the `error` or `data` of a mutation request. To do this, you can use the `mutation.reset` method to achieve this

```dart
  @override
  Widget build(BuildContext context) {
    return MutationBuilder<Map, Map<String, dynamic>>(
      job: basicMutationJob, // the MutationJob we have created previously
      builder: (context, mutation) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(labelText: "Body"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final title = titleController.value.text;
                  final body = bodyController.value.text;
                  if (body.isEmpty || title.isEmpty) return;
                  // running the mutation on Submit
                  mutation.mutate({
                    "title": title,
                    "body": body,
                    "id": id,
                  }, onData: (data) {
                    // resetting the form
                    titleController.text = "";
                    bodyController.text = "";
                  });
                },
                child: const Text("Post"),
              ),
              const SizedBox(height: 20),
              if (mutation.hasData) Text("Response\n${mutation.data}"),
              // when ever an error occurs the error will be shown & alongside
              // a reset button
              if (mutation.hasError) Row(
                children: [
                  Text(mutation.error.toString()),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: ()=> mutation.reset(),
                    child: Text("Reset")
                  ),
                ]
              ),
            ],
          ),
        );
      });
  }
```

# Mutation Side Effects or Events

`MutationBuilder` comes with some helper parameters that allow quick and easy side-effects at any stage during the mutation lifecycle. These come in handy for both invalidating and refetching queries after mutations and even optimistic updates

```dart
@override
Widget build(context) {
  return MutationBuilder(
    job: mutationJob,
    onData: (data, variables){
      print(data);
    },
    onError: (error){
      print(error);
    },
  )
}
```

:::info
Mutation side effect or event callbacks are all assumed as Futures (basically `FutureOr`) so every event listener be fired asynchronously.
:::

You might find that you want to trigger additional callbacks than the ones defined on `MutationBuilder` when calling `mutate`. This can be used to trigger widget-specific side effects. To do that, you can provide any of the same callback options to the `mutate` function after your mutation variable. Supported overrides include: `onSuccess` and `onError`. 

> Please keep in mind that those additional callbacks won't run if your Widget gets disposed before the mutation finishes.

```dart
 mutate(todoPayload, 
   onSuccess: (data, variables) async {

   },
   onError: (error) async {

   },
 )
```


# Async Mutate

Use `mutateAsync` instead of `mutate` to get a `Future` which will resolve on success or throw on an error. This can for example be used to compose side effects.

```dart
 try {
    // works like onData
    final todo = await mutation.mutateAsync(todoPayload);
 } catch (error) {
    // works like onError
    print(error);
 }
```

