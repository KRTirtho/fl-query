# FL-Query

Asynchronous data caching, refetching & invalidation library for Flutter. FL-Query lets you manage & distribute your data async data without touching any global state

# Examples
All examples of fl-query can be found in the [packages/example/lib](https://github.com/KRTirtho/fl-query/tree/main/packages/example/lib) directory

Here's a basic example:
```dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return QueryBowlScope(
      child: MaterialApp(
        title: 'FL-Query Demo',
        theme: ThemeData(
          useMaterial3: true,
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(),
      ),
    );
  }
}


// defining jobs that'll return results

// this query resolve successfully with expected Data
final successJob = QueryJob<String, void>(
  queryKey: "success",
  task: (queryKey, externalData) => Future.delayed(const Duration(seconds: 2),
      () => "Welcome ($queryKey) ${Random.secure().nextInt(100)}"),
);

// this query can fail or can be successful
final failedJob = QueryJob<String, void>(
  queryKey: "failure",
  task: (queryKey, externalData) => Random().nextBool()
      ? Future.error("[$queryKey] Failed for unknown reason")
      : Future.value(
          "Success, you'll get slowly ${Random().nextInt(100)}!",
        ),
);

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fl Query Example"),
      ),
      body: Column(
        children: [
          Row(
            children: [
              QueryBuilder<String, void>(
                job: successJob,
                // if you want to pass any external data or variable to the
                // query/task function or just pass null
                externalData: null,
                builder: (context, query) {
                  // returning based on the status of the query
                  if (query.isLoading || query.isRefetching) {
                    return const CircularProgressIndicator();
                  }
                  return TextButton(
                    child: Text(query.data!),
                    onPressed: () async {
                      // refetching data forcibly
                      await query.refetch();
                    },
                  );
                },
              ),
              QueryBuilder<String, void>(
                job: failedJob,
                externalData: null,
                builder: (context, query) {
                  return Row(
                    children: [
                      if (query.hasError)
                        Text(
                          "${query.error}. Retrying: ${query.retryAttempts}",
                        ),
                      if (query.hasData)
                        Text(
                            "Success after ${query.retryAttempts}. Data: ${query.data}"),
                      ElevatedButton(
                        child: Text("Refetch ${query.queryKey}"),
                        onPressed: () => query.refetch(),
                      )
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

```

# TODO

- Invalidate Queries when Window Focus Lost
- Invalidate Queries when Connection Lose based configure network behavior