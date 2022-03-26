import 'package:fl_query/src/core/models.dart';
import 'package:fl_query/src/core/query.dart';
import 'package:fl_query/src/core/query_key.dart';
import 'package:collection/collection.dart';

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

bool matchQuery(
  QueryFilters filters,
  Query query, [

  /// multiple queryKeys to find the query
  QueryKey? queryKeys,
]) {
  if (queryKeys != null) {
    if (filters.exact == true &&
        query.queryHash != hashQueryKeyByOptions(queryKeys, query.options))
      return false;
    else if (query.queryKey.key != queryKeys.key &&
        !queryKeys.keyAsList.contains(query.queryKey.key) &&
        !query.queryKey.keyAsList.contains(queryKeys.key)) return false;
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

  for (final item in a!.entries) {
    if (a[item.key] != b?[item.key]) return false;
  }

  return true;
}

/// This function returns `a` if `b` is deeply equal\
/// If not, it will replace any deeply equal children of `b` with those
/// of `a`\
/// This can be used for structural sharing between JSON values for example.
/// `a` & `b` can only be Type of [List] or [Map]
replaceEqualDeep(a, b) {
  if (a == b) {
    return a;
  }

  int aSize;
  List bItems;
  int bSize;
  int equalItems = 0;
  onEqual() => equalItems++;
  var copy;
  if (a is List && b is List) {
    aSize = a.length;
    bItems = b;
    bSize = bItems.length;
    copy = replaceEqualDeepList(a, b, onEqual);
  } else if (a is Map && b is Map) {
    aSize = a.keys.length;
    bItems = b.keys.toList();
    bSize = bItems.length;
    copy = replaceEqualDeepMap(a, b, onEqual);
  } else {
    return b;
  }
  return aSize == bSize && equalItems == aSize ? a : copy;
}

Map replaceEqualDeepMap(Map a, Map b, void Function() onEqual) {
  final copy = Map.from(a);
  copy.clear();
  for (final bEntry in b.entries) {
    final aItem = a[bEntry.key];
    copy[bEntry.key] =
        aItem != null ? replaceEqualDeep(aItem, bEntry.value) : bEntry.value;
    if (copy[bEntry.key] == aItem) {
      onEqual();
    }
  }
  return copy;
}

List replaceEqualDeepList(List a, List b, void Function() onEqual) {
  final copy = List.of(a, growable: true);
  copy.clear();
  for (final bEntry in b.asMap().entries) {
    final aItem = a.firstWhereIndexedOrNull((i, _) => i == bEntry.key);
    final result =
        aItem != null ? replaceEqualDeep(aItem, bEntry.value) : bEntry.value;
    copy.add(result);
    if (copy.last == aItem) {
      onEqual();
    }
  }
  return copy;
}

Duration timeUntilStale(DateTime updatedAt, [Duration? staleTime]) =>
    updatedAt.add(staleTime ?? Duration.zero).difference(DateTime.now());

typedef DataUpdateFunction<TInput, TOutput> = TOutput Function(TInput input);
