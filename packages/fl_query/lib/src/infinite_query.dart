import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_query/src/base_query.dart';
import 'package:fl_query/src/models/infinite_query_job.dart';
import 'package:fl_query/src/query.dart';

typedef InfiniteQueryTaskFunction<T extends Object, Outside,
        PageParam extends Object>
    = FutureOr<T> Function(
  String queryKey,
  PageParam pageParam,
  Outside externalData,
);
typedef InfiniteQueryPageParamFunction<T extends Object,
        PageParam extends Object>
    = FutureOr<PageParam> Function(T lastPage, PageParam lastParam);

class InfiniteQuery<T extends Object, Outside, PageParam extends Object>
    extends BaseQuery<Map<PageParam, T?>, Outside, Map<PageParam, dynamic>> {
  InfiniteQueryTaskFunction<T, Outside, PageParam> task;

  InfiniteQueryPageParamFunction<T, PageParam>? getNextPageParam;
  InfiniteQueryPageParamFunction<T, PageParam>? getPreviousPageParam;

  bool _hasNextPage = false;
  bool _hasPreviousPage = false;

  bool _isFetchingNextPage = false;
  bool _isFetchingPreviousPage = false;

  bool get isFetchingNextPage => _isFetchingNextPage;
  bool get isFetchingPreviousPage => _isFetchingPreviousPage;
  bool get hasNextPage => _hasNextPage;
  bool get hasPreviousPage => _hasPreviousPage;

  PageParam _currentParam;

  InfiniteQuery({
    required super.queryKey,
    required this.task,
    required super.staleTime,
    required super.cacheTime,
    required super.externalData,
    required super.retries,
    required super.retryDelay,
    required super.queryBowl,
    required super.status,
    required PageParam initialParam,
    super.refetchOnMount,
    super.refetchOnReconnect,
    super.refetchInterval,
    super.enabled,
    super.previousData,
    super.connectivity,
    super.onData,
    super.onError,
    required T? initialPage,
    this.getNextPageParam,
    this.getPreviousPageParam,
  })  : _currentParam = initialParam,
        super(initialData: {initialParam: initialPage});

  InfiniteQuery.fromOptions(
    InfiniteQueryJob<T, Outside, PageParam> options, {
    required super.queryBowl,
    required Outside externalData,
    QueryListener<T>? onData,
    QueryListener<dynamic>? onError,
  })  : task = options.task,
        _currentParam = options.initialParam,
        getNextPageParam = options.getNextPageParam,
        getPreviousPageParam = options.getPreviousPageParam,
        super(
          cacheTime: options.cacheTime ?? const Duration(minutes: 5),
          retries: options.retries ?? 3,
          retryDelay: options.retryDelay ?? const Duration(milliseconds: 200),
          externalData: externalData,
          enabled: options.enabled ?? true,
          staleTime: options.staleTime ?? const Duration(milliseconds: 500),
          refetchInterval: options.refetchInterval,
          refetchOnMount: options.refetchOnMount,
          refetchOnReconnect: options.refetchOnReconnect,
          status: QueryStatus.idle,
          connectivity: options.connectivity ?? Connectivity(),
          queryKey: options.queryKey,
          initialData: {options.initialParam: options.initialPage},
        );

  List<PageParam> get pageParams => data?.keys.toList() ?? [];
  List<dynamic> get errors => error?.values.toList() ?? [];
  List<T?> get pages => data?.values.toList() ?? [];

  Future<T?> fetchNextPage([
    InfiniteQueryPageParamFunction<T, PageParam>? getNextPageParam,
  ]) async {
    try {
      if (isFetchingNextPage ||
          isFetchingPreviousPage ||
          isLoading ||
          isRefetching) return null;
      if (data == null || data?[_currentParam] == null) execute();
      _isFetchingNextPage = true;
      _isFetchingPreviousPage = false;
      final nextParam = await (getNextPageParam ?? this.getNextPageParam)?.call(
        data![_currentParam]!,
        _currentParam,
      );
      if (nextParam == null) {
        _hasNextPage = false;
        notifyListeners();
        return null;
      }
      _hasNextPage = true;
      _currentParam = nextParam;
      return await refetch().then((data) => data?[_currentParam]);
    } finally {
      _isFetchingNextPage = false;
      notifyListeners();
    }
  }

  Future<T?> fetchPreviousPage([
    InfiniteQueryPageParamFunction<T, PageParam>? getPreviousPageParam,
  ]) async {
    try {
      if (isFetchingNextPage ||
          isFetchingPreviousPage ||
          isLoading ||
          isRefetching) return null;
      _isFetchingPreviousPage = true;
      _isFetchingNextPage = false;
      notifyListeners();
      if (data?[_currentParam] == null) execute();
      final prevParam =
          await (getPreviousPageParam ?? this.getPreviousPageParam)?.call(
        data![_currentParam]!,
        _currentParam,
      );
      if (prevParam == null) {
        _hasPreviousPage = false;
        notifyListeners();
        return null;
      }
      _hasPreviousPage = true;
      _currentParam = prevParam;
      return await refetch().then((_) => data?[_currentParam]);
    } catch (e) {
      print("[InfiniteQuery.fetchPreviousPage]: $e");
      rethrow;
    } finally {
      _isFetchingPreviousPage = false;
      notifyListeners();
    }
  }

  @override
  // TODO: implement debugLabel
  String get debugLabel => "InfiniteQuery($queryKey)";

  @override
  void setData() async {
    if (data == null) data = Map();
    data?[_currentParam] = await task(
      queryKey,
      _currentParam,
      externalData,
    );
  }

  @override
  void setError(specError) {
    if (error is! Map) error = Map();
    error?[_currentParam] = specError;
  }

  @override
  bool operator ==(other) {
    return (other is InfiniteQuery<T, Outside, PageParam> &&
            other.queryKey == queryKey) ||
        identical(other, this);
  }

  @override
  bool get hasData => data?[_currentParam] != null;
}
