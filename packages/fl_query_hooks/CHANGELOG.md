# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

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
