# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

## 2024-06-02

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`fl_query` - `v1.1.0`](#fl_query---v110)
 - [`fl_query_connectivity_plus_adapter` - `v0.1.0+1`](#fl_query_connectivity_plus_adapter---v0101)
 - [`fl_query_devtools` - `v0.1.0+1`](#fl_query_devtools---v0101)
 - [`fl_query_hooks` - `v1.1.0`](#fl_query_hooks---v110)

---

#### `fl_query` - `v1.1.0`

 - **FIX**: infinite query did not load pages in the correct order (#64).
 - **FIX**: infinite query hasErrors always true for dynamic error types.
 - **FIX**: schedule to queue doesn't work and stale queries cause infinite loop.
 - **FIX**: error not resetting after successful query/mutation (#43).
 - **FEAT**: add is fetching getter (#65).

#### `fl_query_connectivity_plus_adapter` - `v0.1.0+1`

 - **FIX**: schedule to queue doesn't work and stale queries cause infinite loop.

#### `fl_query_devtools` - `v0.1.0+1`

 - **FIX**: schedule to queue doesn't work and stale queries cause infinite loop.

#### `fl_query_hooks` - `v1.1.0`

 - **FIX**: schedule to queue doesn't work and stale queries cause infinite loop.
 - **FEAT**: add is fetching getter (#65).


## 2023-10-20

### Changes

---

Packages with breaking changes:

 - [`fl_query` - `v1.0.0`](#fl_query---v100)
 - [`fl_query_hooks` - `v1.0.0`](#fl_query_hooks---v100)

Packages with other changes:

 - [`fl_query_connectivity_plus_adapter` - `v0.1.0`](#fl_query_connectivity_plus_adapter---v010)
 - [`fl_query_devtools` - `v0.1.0`](#fl_query_devtools---v010)

Packages graduated to a stable release (see pre-releases prior to the stable version for changelog entries):

 - `fl_query` - `v1.0.0`
 - `fl_query_connectivity_plus_adapter` - `v0.1.0`
 - `fl_query_devtools` - `v0.1.0`
 - `fl_query_hooks` - `v1.0.0`

---

#### `fl_query` - `v1.0.0`

#### `fl_query_hooks` - `v1.0.0`

#### `fl_query_connectivity_plus_adapter` - `v0.1.0`

#### `fl_query_devtools` - `v0.1.0`


## 2023-10-18

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`fl_query` - `v1.0.0-alpha.6`](#fl_query---v100-alpha6)
 - [`fl_query_connectivity_plus_adapter` - `v0.1.0-alpha.5`](#fl_query_connectivity_plus_adapter---v010-alpha5)
 - [`fl_query_hooks` - `v1.0.0-alpha.6`](#fl_query_hooks---v100-alpha6)
 - [`fl_query_devtools` - `v0.1.0-alpha.4`](#fl_query_devtools---v010-alpha4)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `fl_query_hooks` - `v1.0.0-alpha.6`
 - `fl_query_devtools` - `v0.1.0-alpha.4`

---

#### `fl_query` - `v1.0.0-alpha.6`

 - **FIX**(fl_query): use sync connection checker instead of async in every operation.
 - **FEAT**(fl_query_connectivity_plus_adapter): lookup based offline detection.

#### `fl_query_connectivity_plus_adapter` - `v0.1.0-alpha.5`

 - **FEAT**(fl_query_connectivity_plus_adapter): only poll to check online when connection is false.
 - **FEAT**(fl_query_connectivity_plus_adapter): lookup based offline detection.


## 2023-10-06

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`fl_query` - `v1.0.0-alpha.5`](#fl_query---v100-alpha5)
 - [`fl_query_devtools` - `v0.1.0-alpha.3`](#fl_query_devtools---v010-alpha3)
 - [`fl_query_hooks` - `v1.0.0-alpha.5`](#fl_query_hooks---v100-alpha5)
 - [`fl_query_connectivity_plus_adapter` - `v0.1.0-alpha.4`](#fl_query_connectivity_plus_adapter---v010-alpha4)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `fl_query_connectivity_plus_adapter` - `v0.1.0-alpha.4`

---

#### `fl_query` - `v1.0.0-alpha.5`

 - **FIX**(query): isLoading & isRefreshing not working as expected.
 - **FIX**(mutation): isMutating not working.
 - **FEAT**(infinite_query): add isLoadingNextPage & remove isLoadingPage.

#### `fl_query_devtools` - `v0.1.0-alpha.3`

 - **FEAT**(infinite_query): add isLoadingNextPage & remove isLoadingPage.

#### `fl_query_hooks` - `v1.0.0-alpha.5`

 - **FIX**(mutation): isMutating not working.


## 2023-09-09

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`fl_query_hooks` - `v1.0.0-alpha.4+1`](#fl_query_hooks---v100-alpha41)

---

#### `fl_query_hooks` - `v1.0.0-alpha.4+1`

 - **FIX**(fl_query_hooks): upgrade flutter_hooks version & dart sdk constrain.


## 2023-09-09

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`fl_query` - `v1.0.0-alpha.4`](#fl_query---v100-alpha4)
 - [`fl_query_devtools` - `v0.1.0-alpha.2`](#fl_query_devtools---v010-alpha2)
 - [`fl_query_hooks` - `v1.0.0-alpha.4`](#fl_query_hooks---v100-alpha4)
 - [`fl_query_connectivity_plus_adapter` - `v0.1.0-alpha.3`](#fl_query_connectivity_plus_adapter---v010-alpha3)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `fl_query_connectivity_plus_adapter` - `v0.1.0-alpha.3`

---

#### `fl_query` - `v1.0.0-alpha.4`

 - **FIX**: mutation onSuccess doesn't refresh all pages of infinite queries.
 - **FIX**: no refreshing stale queries with error.

#### `fl_query_devtools` - `v0.1.0-alpha.2`

 - **FIX**(devtools): no wrapping child inside SizedBox.shrink.

#### `fl_query_hooks` - `v1.0.0-alpha.4`

 - **FIX**: mutation onSuccess doesn't refresh all pages of infinite queries.


## 2023-06-28

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`fl_query_connectivity_plus_adapter` - `v0.1.0-alpha.2`](#fl_query_connectivity_plus_adapter---v010-alpha2)

---

#### `fl_query_connectivity_plus_adapter` - `v0.1.0-alpha.2`

 - **FIX**(fl_query_connectivity_plus_adapter): lower the sdk constrains.


## 2023-06-24

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`fl_query` - `v1.0.0-alpha.3`](#fl_query---v100-alpha3)
 - [`fl_query_hooks` - `v1.0.0-alpha.3`](#fl_query_hooks---v100-alpha3)
 - [`fl_query_devtools` - `v0.1.0-alpha.1`](#fl_query_devtools---v010-alpha1)
 - [`fl_query_connectivity_plus_adapter` - `v0.1.0-alpha.1`](#fl_query_connectivity_plus_adapter---v010-alpha1)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `fl_query_devtools` - `v0.1.0-alpha.1`
 - `fl_query_connectivity_plus_adapter` - `v0.1.0-alpha.1`

---

#### `fl_query` - `v1.0.0-alpha.3`

 - **REFACTOR**: directory restructure revamp.
 - **REFACTOR**: more convenient ways customizing config.
 - **REFACTOR**: stale logic to separate mixin.
 - **REFACTOR**: remove KyeType and use String for queryKey and mutationKey.
 - **REFACTOR**(example): package specific examples instead of a single example.
 - **REFACTOR**(QueryBowl): query bowl logic as a separate class instead of a stateful widget.
 - **REFACTOR**: move devtools to separate library.
 - **FIX**(fl_query_hooks): unneeded empty instances of query/mutation.
 - **FIX**(base_query): onData callback getting called with null #17.
 - **FIX**(fl_query_hooks): newest query/mutation/infinite-query instance not getting returned.
 - **FIX**: fetch query and infinite query resolving immediately without proper result.
 - **FIX**: refetchOnExternalDataChange isn't working #18.
 - **FIX**: mutation context param clashing with BuildContext.
 - **FIX**: query, infinite_query fetching/refetching when offline.
 - **FIX**: state update on unmounted hook and infinite query cache refetch not working.
 - **FIX**(client): check for error out put in fetch query and infinite query and mutateMutation immediate resolve.
 - **FIX**: not updating queryFn on create query's old query and checking stale status after updating queryFn instead of storing the status before.
 - **FIX**(InfiniteQueryJob): remove unneeded `keepPreviousData` property.
 - **FEAT**: add mutation and mutation builder with example.
 - **FEAT**: infinite query listenable add and cache event stream.
 - **FEAT**: add infinite query builder with example.
 - **FEAT**: new widget query listable builder.
 - **FEAT**: safe setState for builders, separate cache box for query and infinite query and update state before _operate to indicate loading state.
 - **FEAT**: working query builder, remove timeout from retryConfig.
 - **FEAT**: cache, client, query builder add and refreshOnQueryFnChange option.
 - **FEAT**: infinite query implementation.
 - **FEAT**: safe cancellation of running operation on reset.
 - **FEAT**: initial query and retryer implementation.
 - **FEAT**: clean old junk.
 - **FEAT**: useQuery hook with working example.
 - **FEAT**: useInfiniteQuery hook add.
 - **FEAT**: add query and infinite query disk caching support.
 - **FEAT**: use function hooks instead of class hooks.
 - **FEAT**: new next_page signature, query/mutation fn in notifier and safe update in use_updater.
 - **FEAT**(QueryClientProvider): add config parameters and override-able client parameter.
 - **FEAT**: add devtools (WIP).
 - **FEAT**: add ability to get, refresh query and infinite queries using prefix.
 - **FEAT**: connectivity adapter package for connectivity_plus.
 - **FEAT**: refresh on network state change and cancel retry when offline.
 - **FEAT**: add support for keepPreviousData & examples regarding this.
 - **FEAT**: resolve and resolveWith helper support.
 - **FEAT**: add initial support for `InfiniteQuery`.
 - **FEAT**(infinite-query): onData and onError listener support.
 - **FEAT**(infinite-query): add `useInfiniteQuery` hook with example.
 - **FEAT**(infinite-query): add setInfiniteQueryData support.
 - **FEAT**(infinite-query): add refetchPages, refetchOnStale, refetchOnMount support.
 - **FEAT**(infinite-query): add all the features of query in infinite query.
 - **FEAT**: implement refetchOnApplicationResume and refetchOnWindowFocus.
 - **DOCS**: add dynamic query & mutation section.
 - **DOCS**: add paginated-query section and update optimistc update section.
 - **DOCS**: update according to the new query bowl refactor.
 - **DOCS**: Front page Images added.
 - **DOCS**: add infinite query page.

#### `fl_query_hooks` - `v1.0.0-alpha.3`

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

