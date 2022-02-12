import 'package:fl_query/src/core/models.dart';
import 'package:fl_query/src/core/query.dart';
import 'package:fl_query/src/core/query_key.dart';

/// Default query keys hash function.
/// Dummy function just to fill the gaps for original react-query like
/// function body signatures
/// It is not required as a Standardized [QueryKey] data-class is used to
/// create the queryKey
String hashQueryKeyByOptions(
  QueryKey queryKey,
  QueryOptions? options,
) {
  return options?.queryKeyHashFn?.call(queryKey) ?? queryKey.key;
}

enum QueryStatusFilter {
  all,
  active,
  inactive,
  none,
}

QueryStatusFilter mapQueryStatusFilter(
  bool? active,
  bool? inactive,
) {
  if ((active == true && inactive == true) ||
      (active == null && inactive == null)) {
    return QueryStatusFilter.all;
  } else if (active == false && inactive == false) {
    return QueryStatusFilter.none;
  } else {
    // At this point, active|inactive can only be true|false or false|true
    // so, when only one value is provided, the missing one has to be the negated value
    bool isActive = active ?? !(inactive ?? false);
    return isActive ? QueryStatusFilter.active : QueryStatusFilter.inactive;
  }
}

bool matchQuery(QueryFilters filters, Query query, [QueryKey? queryKey]) {
  if (queryKey != null) {
    if (filters.exact! &&
        query.queryHash != hashQueryKeyByOptions(queryKey, query.options))
      return false;
    else if (query.queryKey.key != queryKey) return false;
  }
  QueryStatusFilter queryStatusFilter =
      mapQueryStatusFilter(filters.active, filters.inactive);

  if (queryStatusFilter == QueryStatusFilter.none) {
    return false;
  } else if (queryStatusFilter != QueryStatusFilter.all) {
    bool isActive = query.isActive();
    if (queryStatusFilter == QueryStatusFilter.active && !isActive) {
      return false;
    }
    if (queryStatusFilter == QueryStatusFilter.inactive && isActive) {
      return false;
    }
  }

  if (filters.stale != null && query.isStale() != filters.stale) {
    return false;
  }

  if (filters.fetching != null && query.isFetching() != filters.fetching) {
    return false;
  }

  if (filters.predicate != null && !filters.predicate!(query)) {
    return false;
  }

  return true;
}

void noop([e]) => null;

bool shallowEqualMap(Map? a, Map? b) {
  if ((a != null && b == null) || (b != null && a == null)) {
    return false;
  }

  for (var item in a!.entries) {
    var aVal = item.value;
    var bVal = b?[item.key];
    if (aVal != bVal) return false;
  }

  return true;
}

/// This function returns `a` if `b` is deeply equal\
/// If not, it will replace any deeply equal children of `b` with those
/// of `a`\
/// This can be used for structural sharing between JSON values for example.
/// `a` & `b` can only be Type of [Iterable] or [Map]
T replaceEqualDeep<T>(T a, T b) {
  if (a == b) {
    return a;
  }

  bool isList = (a is Iterable && b is Iterable);
  if (isList || (a is Map && b is Map)) {
    int aSize = isList ? a.length : (a as Map).keys.length;
    List bItems = (isList ? b : (b as Map).keys).toList();
    int bSize = bItems.length;
    var copy;

    int equalItems = 0;

    for (int i = 0; i < bSize; i++) {
      var key = isList ? i : bItems[i];
      if (isList) {
        copy ??= [];
        copy[key] = replaceEqualDeep((a as List)[key], (b as List)[key]);
        if (copy[key] == a[key]) {
          equalItems++;
        }
      } else {
        copy ??= {};
        copy[key] = replaceEqualDeep((a as Map)[key], (b as Map)[key]);
        if (copy[key] == a[key]) {
          equalItems++;
        }
      }
    }

    return aSize == bSize && equalItems == aSize ? a : copy as T;
  }
  return b;
}

Duration timeUntilStale(DateTime updatedAt, [Duration? staleTime]) =>
    updatedAt.add(staleTime ?? Duration.zero).difference(DateTime.now());

typedef DataUpdateFunction<TInput, TOutput> = TOutput Function(TInput input);
