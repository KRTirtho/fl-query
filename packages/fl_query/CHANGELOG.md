## v0.2.0

### New
- Paginated/Lagged Query support using `QueryJob`'s `keepPreviousData`
- Mutation event context (returned data from `onMutate` available in `onData` & `onError`)
- Support for `refetchOnMount`. Now query will be refetched when a new widget is mounted.

### Improvements
- Only one Query & Mutation instance in `QueryBuilder` & `MutationBuilder` which reduces memory usage
- Optimistic updates are now context driven


## v0.1.0

Initial Release

- `QueryBowl` & `QueryBowlScope` for managing & caching all the query data.
- `Query` for advanced fetch, refetch & data management APIs
- `Mutation` for advanced mutate (a function that modifies data somewhere) & post-mutation management APIs
- `QueryJob` for defining the logic of how data should be fetched or refetched or invalidated
- `MutationJob` for defining the logic of how data should be mutated
- `QueryBuilder` for binding the `Query` & `QueryJob` to a Flutter Widget
- `MutationBuilder` for binding the `Mutation` & `MutationJob` to a Flutter Widget