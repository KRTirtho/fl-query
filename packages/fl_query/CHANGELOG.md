# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

### [1.0.0-alpha.1](https://github.com/KRTirtho/fl-query/compare/v0.3.0...v1.0.0-alpha.1) (2023-03-05)

> **BREAKING**
> - The Jobs API has been disabled. So there's no `QueryJob`, `MutationJob` and `InfiniteQueryJob` anymore. Instead, you can use the `QueryBuilder`, `MutationBuilder` and `InfiniteQueryBuilder`  directly
> - Some of classes were renamed to more mature names
>   - `QueryBowlProvider` -> `QueryClientProvider`
>   - `QueryBowl` -> `QueryClient`
> - The unnecessary `getPreviousPageParam` is now removed from `InfiniteQuery`
> - `getNextPageParam` has been renamed to `nextPage`
> - Also, `fetchNextPage` has been renamed to `fetchNext`
> - `Query` and `InfiniteQuery`'s `setQueryData` has been renamed to `setData` and it now accepts data directly instead of a call back function
> - Finally, `QueryClient`'s unneeded `prefetchQuery` method was eradicated


### Features

* add infinite query builder ([efa2c81](https://github.com/KRTirtho/fl-query/commit/efa2c81505385eba0ba45f50c0debb9e4708804b))
* add mutation and mutation builder ([6a90f84](https://github.com/KRTirtho/fl-query/commit/6a90f847c90c242ec089ab85f9ec7201a9aacd06))
* add query and infinite query disk caching support ([074175e](https://github.com/KRTirtho/fl-query/commit/074175ed392370d5165d0573977af8d83422ac31))
* add Cache, Client, QueryBuilder widget and refreshOnQueryFnChange support for queries ([18584a3](https://github.com/KRTirtho/fl-query/commit/18584a3c57dbb1538fc18a48b41be11fbc11d094))
* InfiniteQuery implementation ([45b6f92](https://github.com/KRTirtho/fl-query/commit/45b6f92316ca1496e47462eb67aea64f43f8d9c1))
* add InfiniteQueryListenable widget and cache event stream ([783a273](https://github.com/KRTirtho/fl-query/commit/783a2737b18283478d65082e236629188c124e6b))
* add Query and Retryer ([b304466](https://github.com/KRTirtho/fl-query/commit/b304466d73654a89c9582b8211b063ae8c661454))
* infinite query's nextPage method ([f2a23b0](https://github.com/KRTirtho/fl-query/commit/f2a23b085cd657a1612d87749f6592b4d67814c5))
* new QueryListableBuilder widget ([975f9ea](https://github.com/KRTirtho/fl-query/commit/975f9eafe14d2ae235a67c173622f16ef850e8e7))
* safe cancellation of running operation on reset ([5dde200](https://github.com/KRTirtho/fl-query/commit/5dde200c84836aba676708c2dd2682a861edb289))
* safe setState for builders, separate cache box for query and infinite query ([68e60c1](https://github.com/KRTirtho/fl-query/commit/68e60c1914d321bb8e23516966bafc990ea2bc31))
* add usMutation hook ([383d0e0](https://github.com/KRTirtho/fl-query/commit/383d0e0a85d7db6ee30bc336cb849f4ea401a8f1))
* add useInfiniteQuery hook ([f9a5207](https://github.com/KRTirtho/fl-query/commit/f9a520740321ababa3974e232562b32364062a35))
* add useQuery hook ([7fabf44](https://github.com/KRTirtho/fl-query/commit/7fabf44756ed36aaa4481583167735bc18f97ad1))


### [0.3.1](https://github.com/KRTirtho/fl-query/compare/v0.3.0...v0.3.1) (2022-10-03)

### Bug Fixes
* **infinite_query**: `getNextPageParam` & `getPreviousPageParam` cannot return null ([e9c8b79](https://github.com/KRTirtho/fl-query/commit/e9c8b7903b430187c802ad46b51447c0760f5e0d))
* **base_query**: `onData` callback getting called with null #17 ([664e90e](https://github.com/KRTirtho/fl-query/commit/664e90e60488e408bb76fa8681d6557528731259))



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