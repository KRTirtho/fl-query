---
title: Infinite Queries
sidebar_position: 11
---


Rendering lists that can additively "load more" data onto an existing set of data or "infinite scroll" is also a very common UI pattern. Fl Query supports a useful version of `Query` called `InfiniteQuery` for querying these types of lists.

When using `InfiniteQueryBuilder`, you'll notice a few things are different:

- `data` is now an object containing infinite query data as `Map<type of page parameter, type of page data>`
- `data.pages` List containing the fetched pages
- `data.pageParams` List containing the page params used to fetch the pages
- The `fetchNextPage` and `fetchPreviousPage` methods are now available
- The `getNextPageParam` and `getPreviousPageParam` options are available for both determining if there is more data to load and the information to fetch it. This information is supplied as an additional parameter in the query function (which can optionally be overridden when calling the `fetchNextPage` or `fetchPreviousPage` methods)
- A `hasNextPage` boolean is now available and is `true` if `getNextPageParam` returns a value other than `false`
- A `hasPreviousPage` boolean is now available and is `true` if `getPreviousPageParam` returns a value other than `false`
- The `isFetchingNextPage` and `isFetchingPreviousPage` booleans are now available to distinguish between a background refresh state and a loading more state


## Example

Let's assume we have an API that returns pages of `projects` 3 at a time based on a `cursor` index along with a cursor that can be used to fetch the next group of projects:

```dart
http.get('$hostUrl/api/projects?cursor=0');
// { data: [...], nextCursor: 3}
http.get('$hostUrl/api/projects?cursor=3');
// { data: [...], nextCursor: 6}
http.get('$hostUrl/api/projects?cursor=6');
// { data: [...], nextCursor: 9}
http.get('$hostUrl/api/projects?cursor=9');
// { data: [...] }
```

With this information, we can create a "Load More" UI by:

- Waiting for `InfiniteQuery` to request the first group of data by default
- Returning the information for the next query in `getNextPageParam`
- Calling `fetchNextPage` function

> Note: It's very important you do not call `fetchNextPage` with arguments unless you want them to override the `pageParam` data returned from the `getNextPageParam` function

```dart
import "packages:fl_query/fl_query.dart";
import "package:http/http.dart" as http;

final projectsJob = InfiniteQueryJob<Map<String, dynamic>, void, int>(
  queryKey: 'projects',
  initialParam: 0,
  getNextPageParam: (lastPage, pages) => lastPage['nextCursor'],
  getPreviousPageParam: (currentPage, pages) => currentPage['previousCursor'],
  task: (queryKey, pageParam, externalData){
    return http.get('$hostUrl/api/projects?cursor=$pageParam');
  },
);

class Projects extends StatelessWidget{
  Project({super.key});

  @override
  build(context){
    return InfiniteQueryBuilder(
      job: projectsJob,
      builder: (context, query){
        if(query.isLoading){
          return Center(child: CircularProgressIndicator());
        }

        if(query.isError){
          return Center(child: Text('Error: ${query.error}'));
        }

        return Stack(
          children: [
            ListView.builder(
              itemCount: query.pages.length,
              itemBuilder: (context, index){
                final project = query.pages[index];
                return ListTile(title: Text(project['name']));
              }
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: IconButton(
                icon: const Icon(Icons.get_app_rounded),
                onPressed: query.isFetchingNextPage || !query.hasNextPage
                            ? null 
                            : () => query.fetchNextPage(),
              ),
            ),
          ]
        );
      }
    );
  }
}
```

## What happens when an infinite query needs to be refetched?

When an infinite query becomes `stale` and needs to be refetched, each group is fetched `sequentially`, starting from the first one. This ensures that even if the underlying data is mutated, we're not using stale cursors and potentially getting duplicates or skipping records. If an infinite query's results are ever removed from the QueryBowl's Cache, the pagination restarts at the initial state with only the initial group being requested.

### refetchPage

If you only want to actively refetch a subset of all pages, you can use the `refetchPage` method of `InfiniteQuery`. It optionally takes a `selector callback` to programmatically choose which pages to refetch. If no selector is provided, all pages will be refetched sequentially.

```dart
// refetching all the pages
infiniteQuery.refetchPages();

// refetching custom selected pages
infiniteQuery.refetchPages((page, pageParam, allPages){
  // this will refetch all the pages that are fetched after the 10th page
  return pageParam > 10;
})
```

## What if I need to pass custom page parameter to my `fetchNextPage` function?

By default, the variable returned from `getNextPageParam` will be supplied to the task function, but in some cases, you may want to override this. You can pass custom `getNextPageParam` to the `fetchNextPage` method only for that very call which will override the default variable like so:

```dart
infiniteQuery.fetchNextPage((lastPage, lastParam)=> 20)
```


## Manually update the infinite query data

Manually removing first page:

```dart
QueryBowl.of(context)
  .setQueryData(exampleInfiniteQueryJob.queryKey, (oldData){
    oldData?.remove(0);
    return Map.from(oldData ?? {});
  })
```

Manually removing a single value from an individual page:

```dart
QueryBowl.of(context)
  .setQueryData(exampleInfiniteQueryJob.queryKey, (oldData){
    oldData?.removeWhere((key, value){
      return value["id"] != someOtherValue["id"];
    });
    return Map.from(oldData ?? {});
  })
```

## Infinite Query with Dynamic queryKey

Just like regular [`QueryJob`](/docs/basics/DynamicQueries), `InfiniteQueryJob` also supports dynamic queryKeys via the `InfiniteQuery.withVariableKey` static method. This is useful when your API/source of data returns the same structure of data for multiple endpoints e.g dynamic routes.

```dart
final projectsJob = InfiniteQueryJob.withVariableKey<Map<String, dynamic>, void, int>(
  queryKey: (queryKey) => 'projects-$queryKey',
  initialParam: 0,
  getNextPageParam: (lastPage, pages) => lastPage['nextCursor'],
  getPreviousPageParam: (currentPage, pages) => currentPage['previousCursor'],
  task: (queryKey, pageParam, externalData){
    final projectId = getVariable(queryKey);
    return http.get('$hostUrl/api/projects/$projectId/?cursor=$pageParam');
  },
);

// using the same query function for multiple queries
InfiniteQueryBuilder(
  job: projectsJob.withQueryKey('1'),
  builder: (context, query){
    // ...
  }
)

InfiniteQueryBuilder(
  job: projectsJob.withQueryKey('2'),
  builder: (context, query){
    // ...
  }
)
```