import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_query/src/base_query.dart';
import 'package:fl_query/src/models/infinite_query_job.dart';
import 'package:fl_query/src/query.dart';
import 'package:flutter/cupertino.dart';
import 'package:queue/queue.dart';

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

  @override
  @protected
  Timer createRefetchTimer() {
    return Timer.periodic(
      refetchInterval!,
      (_) async {
        // only refetch if its connected to the internet or refetch will
        // always result in error while there's no internet
        if (isStale && await isInternetConnected()) await refetchPages();
      },
    );
  }

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
      } else {
        _hasNextPage = true;
        _currentParam = nextParam;
        return await refetch().then((data) => data?[_currentParam]);
      }
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

  Future<List<T>> refetchPages([
    bool Function(T? page, int index, List<T?> allPages)? selector,
  ]) async {
    if (isFetchingNextPage ||
        isFetchingPreviousPage ||
        isLoading ||
        isRefetching) return [];
    final refetchedPages = <T>[];
    final queue = Queue();
    for (final entry in data?.entries.toList() ?? <MapEntry<PageParam, T?>>[]) {
      final page = entry.value;
      final selected = selector?.call(page, pages.indexOf(page), pages) ?? true;
      if (!selected) continue;
      _currentParam = entry.key;
      queue.add<void>(
        () async {
          final s = await refetch();
          if (s?[_currentParam] != null) {
            refetchedPages.add(s![_currentParam]!);
          }
        },
      );
    }
    await queue.onComplete;
    return refetchedPages;
  }

  @override
  // TODO: implement debugLabel
  String get debugLabel => "InfiniteQuery($queryKey)";

  @override
  void mount(ValueKey<String> uKey) {
    super.mount(uKey);

    /// refetching on mount if it's set to true
    /// also checking if the is stale or not
    /// no need to refetch a valid query for no reason
    if (refetchOnMount == true && isStale) {
      this.isInternetConnected().then((isConnected) async {
        if (isConnected) await refetchPages();
      });
    }
  }

  @override
  @protected
  void setData() async {
    if (data == null) data = Map();
    data?[_currentParam] = await task(
      queryKey,
      _currentParam,
      externalData,
    );
  }

  @override
  @protected
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