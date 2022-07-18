---
slug: fl-query-for-flutter
title: Fl-Query⚡ for Flutter
authors: krtirtho
tags: [flutter, fl-query]
---

### Managing async data & mutations in Flutter is like a breeze now🌬️

![Banner](https://github.com/KRTirtho/fl-query/blob/main/assets/fl-query-banner.png?raw=true)

If you’re familiar with [Flutter](http://flutter.dev), you’re definitely familiar with `FutureBuilder`. After all this is the only way you can fetch data in Flutter with proper state, or is it? But you might’ve noticed every time the Widget gets rebuild the Future is run along too unless you declare your `Future` in `initState`

But even if you declare your future in `initState` to avoid reruns across rebuilds it will still rerun when the Widget gets disposed & mounted again. So what’s the solution? Ans: `FutureProvider` from [riverpod](http://riverpod.dev) or [provider](https://pub.dev/packages/provider)

Hold on a sec, but it’s not another riverpod/provider article? No, it's not.

Yeah, to cache your future results or server response in you can use `FutureProvider`. It can store & distribute the result all across the application without multiple reruns of the same operation. But what happens when the Data becomes expired or stale? What if your app won’t need that data after some time but the data still wasting RAM?

This is where **Fl-Query** comes to play. It’s an *Async Data + Mutation Manager for Flutter that caches, fetches, automatically refetches stale data.* Similar to [Tanstack Query](http://tanstack.com/query) in the World of web development, but only the concept is implemented & The API is very similar to what Flutter Developers are used to & so it makes everyone feel like home

Enough talk let’s jump to the big part.

## What does it offer?

- Async data caching & invalidation
- Smart & highly configurable refetch mechanism that smartly updates stale/expired data in the background when needed
- Declarative way to define asynchronous operations
- Garbage Collects Query & Mutation. That means unused queries sitting in the Cache for long time gets automatically removed
- Code & **data** reusability because of persisted data & Query/Mutation **Job** API
- Optimistic updates
- Lazy Loading Queries.  Run you defined asynchronous task or operation when needed
- Zero Configuration out of the box Global Store that no one ever have to touch
- Supports both Vanilla Flutter & [Flutter Hooks](https://pub.dev/packages/flutter_hooks)

## Let’s see some Code

```dart
// A QueryJob is where the Logic of how the data should be 
// fetched can defined. The task callback is a PURE Function 
// & have access to external resources through the second 
// parameter where the first parameter is the queryKey
final successJob = QueryJob<String, void>(
  queryKey: "query-example",
  task: (queryKey, externalData) => Future.delayed(
    const Duration(seconds: 2),
    () =>
        "The work successfully executed. Data: key=($queryKey) value=${
          Random.secure().nextInt(100)
        }",
  ),
);

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // QueryBowlScope creates a Bowl (metaphor for Collection/Store)
    // for all the Queries & Mutations
    return QueryBowlScope(
      child: MaterialApp(
        title: 'Fl-Query Quick Start',
        theme: ThemeData(
          useMaterial3: true,
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class BasicExample extends StatelessWidget {
  const BasicExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "# Basic Query Example",
          style: Theme.of(context).textTheme.headline5,
        ),
        // QueryBuilder Widget provides the expected query 
        // instances through the builder callback based on 
        // the passed job & externalData argument
        QueryBuilder<String, void>(
          job: successJob,
          externalData: null,
          builder: (context, query) {
            if (!query.hasData || query.isLoading || query.isRefetching) {
              return const CircularProgressIndicator();
            }
            return Row(
              children: [
                Text(query.data!),
                ElevatedButton(
                  child: const Text("Refetch"),
                  onPressed: () async {
                    await query.refetch();
                  },
                ), // Text
              ],
            ); // Row
          },
        ), // QueryBuilder
      ],
    );
  }
}
```

Here’s three key important part in the code

- [`QueryBowlScope`](https://fl-query.vercel.app/docs/basics/QueryBowlScope): It's the store where all queries & mutations are stored and distributed throughout the application
- [`QueryJob`](https://fl-query.vercel.app/docs/basics/QueryJob): This what one can use to declare and define the asynchronous operations that retrieves data from server or any other place
- [`QueryBuilder`](https://fl-query.vercel.app/docs/basics/Queries#querybuilder): It creates appropriate `Query` by using the provided `job` & provides the `Query` in the builder method. It is the way the data & the UI connects

`QueryBowlScope` & `QueryJob` has many properties that can be configured & changed in a way that best suits your application. Most of their properties are some. But properties defined in `QueryBowlScope` are global configuration where `QueryJob` is specific to that very `Query`

## Query External Data

One thing you might’ve notice or have been thinking that the task function is separated from the Widget so how would you use other services, classes, methods or data in it. Simply, how will give inputs to a Query Task or the asynchronous operation? This is where the second parameter of `QueryJob`’s task callback comes to play. You can use the `QueryBuilder`’s `externalData` named argument to pass data to the task callback. You can literally use anything as externalData. Just pass the Type as Type Parameter to `QueryJob` & `QueryBuilder`

QueryJob with externalData example:

```dart
// This job requires a pre-configured HTTP Client from the http package
// as externalData
// The first Type Parameter is the Type of returned Data & 2nd one is the Type
// of externalData
final anotherJob = QueryJob<String, Client>(
  queryKey: "another-unique-key",
  task: (queryKey, httpClient){
    return httpClient
			.get("https://jsonplaceholder.typicode.com/todos/1")
			.then((response) => response.body);
  }
);
```

Now let’s use this job inside a Widget

```dart
Widget build(BuildContext context) {
    // getting the instance of Client provided by the [provider] package
    final client = Provider.of<Client>(context);
    
    return QueryBuilder<String, void>(
      job: anotherJob,
      // passing the client as externalData
      externalData: client,
      builder: (context, query) {
        if (!query.hasData || query.isLoading) {
          return const CircularProgressIndicator();
        }
        // remember to always show a fallback widget/screen for errors too. 
        // It keeps the user aware of status of the application their using
        // & saves their time
        else if(query.hasError && query.isError){
          return Text(
            "My disappointment is immeasurable & my day is ruined for this stupid error: $error",
          );
        }
        return Row(
          children: [
						// accessing the returned data & showing it
            Text(query.data["title"]),
            ElevatedButton(
              child: const Text("Refetch"),
              onPressed: () async {
                await query.refetch();
              },
            ),
          ],
        );
      },
    );
  }
```

That’s it. It is that easy to provide `externalData` to a Query task

> By default, when `externalData` changes the Query is not refetched. But you can change this behavior if you want the query to refetch everytime `externalData` changes. Just set `refetchOnExternalDataChange` to true in `QueryJob` for that specific Query or in `QueryBowlScope` for all Queries
> 

## Query Refetch & Stale Time

Every query is updated when needed. But you can trigger a refetch for a Query or multiple queries manually. This can be useful after a mutation or the application data has changed for sure. The `Query.refetch` allows to refetch a single query where `QueryBowl.of(context).refetchQueries` allows refetching multiple queries at the same time

Here’s an example of single query refetch:

```dart
ElevatedButton(
 onPressed: () async {
   await query.refetch();
 }
 child: Text("Refetch")
);
```

Now for refetching multiple queries:

```dart
TextField(
	controller: controller,
	onSubmitted: (value){
		QueryBowl.of(context).refetchQueries(
			[exampleJob1.queryKey, exampleJob2.queryKey]
		);
	}
);
```

> The `QueryBowl.of` method gives access to many methods used internally in Fl-Query. Its just an imperative way to do some things when it's necessary. It provides access to many useful methods & properties e.g. `refetchQueries`, `invalidateQueries`, `resetQueries`, `isFetching` etc
> 

Stale Time means the amount of time when after a Query or multiple Query’s data should be considered as outdated

By default, Queries become stale as soon as fetch/refetch completes. But this can be configured using the `staleTime` property of `QueryBowlScope` for global configuration or per Query basis using the `QueryJob`'s property

```dart
final job = QueryJob<String, Client>(
  queryKey: "another-unique-key",
  // now the data of the query will become stale after 30 seconds when the
  // fetch/refetch executes
	staleTime: Duration(seconds: 30),
  task: (queryKey, httpClient){
    return httpClient
			.get("https://jsonplaceholder.typicode.com/todos/1")
			.then((response) => response.body);
  }
);
```

## Query status

A Query can be in following statuses

- `isSuccess`: When the task function returned data successfully
- `isError`: When the task function returned an error
- `isLoading`: When the task function is running
- `isRefetching`: When new data is being fetched or simply the `refetch` method is executing
- `isIdle`: When there's no data & `Query`'s task has not been yet run

These are Query Progress Status there’s another type of status of Query too. They’re called Data availability status. Following are:

- `hasData`: When query contains data no matters what's happening Basically, `query.data != null`
- `hasError`: When the query contains error. Basically, `query.error != null`

> Remember, don’t use `isLoading` only for Loading Indicators as even if the Query `isSucessful` the `data` can still be null. So use `!query.hasData` || `query.isLoading` to ensure there’s no null exceptions
> 

That is all about queries. It has so much more useful functionalities & features that it can’t be covered in a single article. Please visit the [docs](https://fl-query.vercel.app/) for more info ([https://fl-query.vercel.app](https://fl-query.vercel.app/))

## Mutations

Queries are used for retrieving Data or for GET requests where Mutation are, Unlike queries, typically used to create/update/delete data or perform server side effects

Basically, a mutation is a type of asynchronous operation that modifies already available data or adds data in a store or remote server

Just like QueryJob Mutation has `MutationJob` that can be used to define the mutation operation or configuring different stuff

Here’s a MutationJob example:

```dart
final basicMutationJob = MutationJob<Map, Map<String, dynamic>>(
  // instead of queryKey mutation has mutationKey
  mutationKey: "unique-mutation-key",
  task: (key, data) async {
    final response = await http.post(
      Uri.parse(
        // to simulate a failing response environment
        Random().nextBool()
            ? "https://jsonplaceholder.typicode.com/posts"
            : "https://google.com",
      ),
      headers: {'Content-type': 'application/json; charset=UTF-8'},
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  },
);
```

The `task` callback of MutationJob has a variable parameter. It might seem like externalData from QueryJob, but it's a little different. Instead of passing data through externalData argument of QueryBuider, you’ve to pass it through `mutate` or `mutateAsync` method of Mutation

Now let’s use this `MutationJob` with our `MutationBuilder`

```dart
Widget build(context){
	return MutationBuilder<Map, Map<String, dynamic>>(
     job: basicMutationJob,
     builder: (context, mutation) {
       return Padding(
          padding: const EdgeInsets.all(8.0),
	        // Its just basic Form
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
                    // calling the mutate of the mutation
										mutation.mutate({
                       "title": title,
                       "body": body,
                       "id": 42069, // the holy number as ID
                      }, onData: (data) {
                        // resetting the form
                        titleController.text = "";
                        bodyController.text = "";
                    });
                  },
                  child: const Text("Post"),
               ),
                const SizedBox(height: 20),
                // accessing the mutation result
                if (mutation.hasData) Text("Response\n${mutation.data}"),
                if (mutation.hasError) Text(mutation.error.toString()),
             ],
           ),
         );
      });
}
```

Above, there are 2 text fields that provide title and body of a Post & we’re running the mutation whenever the submit button is pressed. The `mutate` method accepts 3 arguments

- 1st parameter/Variables
- `onData`: A callback that runs when result is available & Mutation is successful
- `onError`: A callback that runs when result is available & Mutation is successful

### Optimistic Updates

The most interesting part of `Mutation`s are the `onMutate` callback of `MutationBuilder`. It’s a callback that runs just before executing the `MutationJob.task`. Here you can do all sort of crazy stuff. Such as adding predicted data to different queries before data being returned from the server or deleting an entire Query or anything you want. But in combination with `onData` you can update your application’s data Optimistically, so the user doesn’t have to wait

> Optimistic update means, updating Query data with predictable data before actually getting back any result. Then, when the real data arrives, replace the predicted data with the real data without letting the user even know
> 

Here’s a simple example of Optimistic Updates:

```dart
MutationBuilder<Map, String>(
	job: newUsernameMutation,
	onMutate: (value) {
	  // getting the query that needs to be updated optimistically
	  QueryBowl.of(context)
	      .setQueryData<UserData, void>(job.queryKey, (oldData) {
			oldData.name = value;
			// you've to return a new instance of the oldData else fl-query
      // will assume data hasn't been updated thus won't trigger any changes
			return UserData.from(oldData);
	  });
	},
	onData: (data){
		// replacing the predicted fake data with real data
		QueryBowl.of(context)
	      .setQueryData<UserData, void>(job.queryKey, (oldData) {
			oldData.name = data["name"];
			// you've to return a new instance of the oldData else fl-query
      // will assume data hasn't been updated thus won't trigger any changes
			return UserData.from(oldData);
	  });
  }
	builder: (context, mutation){
		....
    ....
    ....
	}
);
```

This is all for Mutations. To learn more about Mutation [read the docs](https://fl-query.vercel.app/docs/basics/MutationJob)

## Hooks

Fl-Query supports both Vanilla Flutter & flutter_hooks. Both aren’t much different everything is same but in fl_query_hooks you additionally get 2 hooks `useQuery` & `useMutation` which you can use in place of `QueryBuilder` & `MutationBuilder`.

### useQuery

It is basically `QueryBuilder` without all the typical Builder boilerplate. So when I write the 1st example with hooks it’ll look like this:

```dart
class BasicHookExample extends HookWidget {
  const BasicHookExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
		final query = useQuery(job: successJob, externalData: null);

    if(!query.hasData || query.isLoading || query.isRefetching)
			return const CircularProgressIndicator();

    return Row(
      children: [
        Text(query.data!),
        ElevatedButton(
          child: const Text("Refetch"),
          onPressed: () async {
            await query.refetch();
          },
         ), // Text
       ],
     ); // Row
  }
}
```

### useMutation

I guess, you know what `useMutation` does. It’s a replacement for `MutationBuilder` for flutter_hooks which makes code more clean & easier to read

Here’s a `useMutation` example:

```dart
Widget build(context){
	// the mutation object is the same passed as 
  // parameter in the builder method of MutationBuilder
	final mutation = useMutation(job);

	return /* .... (Imaginary Form) */;
}

```

This article only covers simple & most used features of Fl-Query. There are tons of more things that we can do with Fl-Query. Everything is available in the [official docs](https://fl-query.vercel.app/) which is a WIP. So you can contribute to that if you want. It’ll really help the project to move forward

> Fl-Query is still under heavy development & it is expected to have bugs + unintended behavior. So if you find any please [create an Issue](https://github.com/KRTirtho/fl-query/issues) with proper details. Also, we’re open for any suggestions. Suggest what you like or not or want Fl-Query to have. Probably contribute to the project with your own code & feature. It will be much appreciated


> Since the project is in a very early stage it needs appropriate tests & I’m the worst excuse for Tester so Fl-Query needs some good testers who’re willing to contribute to the project with tests. If you want to contribute with tests. Please [join the discussion](https://github.com/KRTirtho/fl-query/discussions/categories/testing) by creating one

Give Fl-Query a ⭐Star⭐ in [Github](https://github.com/KRTirtho/fl-query)

## Social

Follow me on:

- [Twitter](http://twitter.com/@KrTirtho)
- [LinkedIn](https://www.linkedin.com/in/kingkor-roy-tirtho-810b951b4/)
- [Github](https://github.com/KRTirtho)
- [DEVCommunity](http://dev.to/KRTirtho)
- [Medium](http://medium.com/@krtirtho)