import 'package:fl_query/src/core/models.dart';
import 'package:fl_query/src/core/query_cache.dart';

class QueryClient {
  Object? options;
  QueryCache _queryCache;
  QueryCache _mutationCache;

  QueryClient({
    QueryCache? queryCache,
    QueryCache? mutationCache,
    this.options,
  })  : _queryCache = queryCache ?? QueryCache(),
        _mutationCache = mutationCache ?? QueryCache() {}

  QueryObserverOptions<TQueryFnData, TError, TData, TQueryData>
      defaultQueryOptions<TQueryFnData, TError, TData, TQueryData>(
          QueryObserverOptions<TQueryFnData, TError, TData, TQueryData>?
              options) {}

  QueryObserverOptions<TQueryFnData, TError, TData, TQueryData>
      defaultQueryObserverOptions<TQueryFnData, TError, TData, TQueryData>(
          QueryObserverOptions<TQueryFnData, TError, TData, TQueryData>?
              options) {
    return this.defaultQueryOptions(options);
  }

  fetchQuery() {}
  getQueryData() {}
  setQueryData() {}
  getQueryState() {}
  invalidateQueries() {}
  refetchQueries() {}
  cancelQueries() {}
  removeQueries() {}
  resetQueries() {}
  bool get isFetching => false;
  bool get isMutating => false;
  getDefaultOptions() {}
  setDefaultOptions() {}
  getQueryDefaults() {}
  setQueryDefaults() {}
  getMutationDefaults() {}
  setMutationDefaults() {}
  QueryCache getQueryCache() {}
  getMutationCache() {}
  clear() {}
}
