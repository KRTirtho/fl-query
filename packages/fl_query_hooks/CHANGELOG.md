## 1.1.0

 - **FIX**: schedule to queue doesn't work and stale queries cause infinite loop.
 - **FEAT**: add is fetching getter (#65).

## 1.0.0

 - Graduate package to a stable release. See pre-releases prior to this version for changelog entries.

## 1.0.0-alpha.6

 - Update a dependency to the latest release.

## 1.0.0-alpha.5

 - **FIX**(mutation): isMutating not working.

## 1.0.0-alpha.4+1

 - **FIX**(fl_query_hooks): upgrade flutter_hooks version & dart sdk constrain.

## 1.0.0-alpha.4

 - **FIX**: mutation onSuccess doesn't refresh all pages of infinite queries.

## 1.0.0-alpha.3

 - **REFACTOR**: move devtools to separate library.
 - **REFACTOR**: more convenient ways customizing config.
 - **REFACTOR**(QueryBowl): query bowl logic as a separate class instead of a stateful widget.
 - **REFACTOR**(example): package specific examples instead of a single example.
 - **FIX**(fl_query_hooks): fetch query when queryKey changes.
 - **FIX**(fl_query_hooks): query/mutation reset to initial memoized values on hot reload.
 - **FIX**: state update on unmounted hook and infinite query cache refetch not working.
 - **FIX**: refetchOnExternalDataChange isn't working #18.
 - **FIX**(base_query): onData callback getting called with null #17.
 - **FIX**(fl_query_hooks): unneeded empty instances of query/mutation.
 - **FIX**(fl_query_hooks): newest query/mutation/infinite-query instance not getting returned.
 - **FEAT**: connectivity adapter package for connectivity_plus.
 - **FEAT**: add devtools (WIP).
 - **FEAT**: new next_page signature, query/mutation fn in notifier and safe update in use_updater.
 - **FEAT**: use function hooks instead of class hooks.
 - **FEAT**: use mutation hook add.
 - **FEAT**: useInfiniteQuery hook add.
 - **FEAT**: useQuery hook with working example.
 - **FEAT**: safe cancellation of running operation on reset.
 - **FEAT**: add infinite query builder with example.
 - **FEAT**: cache, client, query builder add and refreshOnQueryFnChange option.
 - **FEAT**: initial query and retryer implementation.
 - **FEAT**: clean old junk.
 - **FEAT**: add query and infinite query disk caching support.
 - **FEAT**(infinite-query): onData and onError listener support.
 - **FEAT**(infinite-query): add `useInfiniteQuery` hook with example.
 - **FEAT**(infinite-query): add refetchPages, refetchOnStale, refetchOnMount support.
 - **FEAT**: add initial support for `InfiniteQuery`.
 - **FEAT**: add support for keepPreviousData & examples regarding this.
 - **DOCS**: add infinite query page.
 - **DOCS**: add paginated-query section and update optimistc update section.

# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

## [1.0.0-alpha.2](https://github.com/KRTirtho/fl-query/compare/v1.0.0-alpha.1...v1.0.0-alpha.2) (2023-03-12)


### Features

* **QueryClientProvider:** add config parameters and override-able client parameter ([f8895e3](https://github.com/KRTirtho/fl-query/commit/f8895e338141488e5bce4401c80b491688932085))

### [1.0.0-alpha.1](https://github.com/KRTirtho/fl-query/compare/v0.3.0...v1.0.0-alpha.1) (2023-03-05)

> **BREAKING**
> - The Jobs API has been disabled. So there's no `QueryJob`, `MutationJob` and `InfiniteQueryJob` anymore. Instead, you can use the `useQuery`, `useMutation` and `useInfiniteQuery`  directly
> - Some of classes were renamed to more mature names
>   - `QueryBowlProvider` -> `QueryClientProvider`
>   - `QueryBowl` -> `QueryClient`
> - The unnecessary `getPreviousPageParam` is now removed from `InfiniteQuery`
> - `getNextPageParam` has been renamed to `nextPage`
> - Also, `fetchNextPage` has been renamed to `fetchNext`
> - `Query` and `InfiniteQuery`'s `setQueryData` has been renamed to `setData` and it now accepts data directly instead of a call back function
> - Finally, `QueryClient`'s unneeded `prefetchQuery` method was eradicated
> - useForceUpdate hook is now removed from the package


### Features

* new useQueryClient hook
* useQuery hook implementation hook based on new fl_query ([7fabf44](https://github.com/KRTirtho/fl-query/commit/7fabf44756ed36aaa4481583167735bc18f97ad1))
* useInfiniteQuery hook implementation hook based on new fl_query ([f9a5207](https://github.com/KRTirtho/fl-query/commit/f9a520740321ababa3974e232562b32364062a35))
* usMutation implementation hook based on new fl_query ([383d0e0](https://github.com/KRTirtho/fl-query/commit/383d0e0a85d7db6ee30bc336cb849f4ea401a8f1))

### [0.3.1](https://github.com/KRTirtho/fl-query/compare/v0.3.0...v0.3.1) (2022-10-03)

### Bug Fixes
* **infinite_query**: `getNextPageParam` & `getPreviousPageParam` cannot return null ([e9c8b79](https://github.com/KRTirtho/fl-query/commit/e9c8b7903b430187c802ad46b51447c0760f5e0d))
* **fl_query_hooks:** unneeded empty instances of query/mutation ([e9c8b79](https://github.com/KRTirtho/fl-query/commit/e9c8b7903b430187c802ad46b51447c0760f5e0d))
* **base_query**: `onData` callback getting called with null #17 ([664e90e](https://github.com/KRTirtho/fl-query/commit/664e90e60488e408bb76fa8681d6557528731259))

### [0.3.0](https://github.com/KRTirtho/fl-query/compare/v0.2.0...v0.3.0) (2022-09-23)


### New

* `InfiniteQuery` support

### Improvement

* More efficient `QueryBowl` because it's now a class instead of a StatefulWidget
* Listeners are updated lazily now


## 0.2.0

### New
- Support Paginated/Lagged Query using `keepPreviousData`

### Improvements
- Only one Query & Mutation instance in `useQuery` & `useMutation` reducing memory usage

## 0.1.0

Initial Release

- `useQuery` for binding the `Query` & `QueryJob` data to the UI layer of the application
- `useMutation` for binding the `Mutation` & `MutationJob` operations to the UI layer of the application
