# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

### [0.3.0](https://github.com/KRTirtho/fl-query/compare/v0.2.0...v0.3.0) (2022-09-23)


### Features

* add initial support for `InfiniteQuery` ([1452d7d](https://github.com/KRTirtho/fl-query/commit/1452d7d79e14ef933391221f245c8bff1e869af6))
* **infinite-query:** add `useInfiniteQuery` hook with example ([2a3ac29](https://github.com/KRTirtho/fl-query/commit/2a3ac29f64971fe534fa70600e8be4490429304e))
* **infinite-query:** add all the features of query in infinite query ([61958c7](https://github.com/KRTirtho/fl-query/commit/61958c7d9499921387c646cc27ab9d6202694804))
* **infinite-query:** add refetchPages, refetchOnStale, refetchOnMount support ([95b1837](https://github.com/KRTirtho/fl-query/commit/95b183762021b51df7225adb66f3330e8d84bd96))
* **infinite-query:** add setInfiniteQueryData support ([6eb7b2a](https://github.com/KRTirtho/fl-query/commit/6eb7b2a4293b64243e36307a70720601a76878a3))
* **infinite-query:** onData and onError listener support ([f47ca98](https://github.com/KRTirtho/fl-query/commit/f47ca98472ccd3eecf49ae348225332c8a2f61ea))
* **query_bowl:** `QueryBowl` as separate class
* **performance:** lazily update ListenerWidgets or listeners instead of triggering an update for whole widget tree


### Bug Fixes

* **InfiniteQueryJob:** remove unneeded `keepPreviousData` property ([8df1fc5](https://github.com/KRTirtho/fl-query/commit/8df1fc54c326b62ea1f4df0b4b472ef88198ef4d))

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