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

typedef InfiniteQueryListeners<T, PageParam extends Object> = FutureOr<void>
    Function(T page, PageParam pageParam, List<T?> pages);

typedef InfiniteQueryPageParamFunction<T extends Object,
        PageParam extends Object>
    = FutureOr<PageParam?> Function(T lastPage, PageParam lastParam);

class InfiniteQuery<T extends Object, Outside, PageParam extends Object>
    extends BaseQuery<Map<PageParam, T?>, Outside, Map<PageParam, dynamic>> {
  InfiniteQueryTaskFunction<T, Outside, PageParam> task;

  InfiniteQueryPageParamFunction<T, PageParam>? getNextPageParam;
  InfiniteQueryPageParamFunction<T, PageParam>? getPreviousPageParam;

  bool _hasNextPage = true;
  bool _hasPreviousPage = true;

  bool _isFetchingNextPage = false;
  bool _isFetchingPreviousPage = false;

  bool get isFetchingNextPage => _isFetchingNextPage;
  bool get isFetchingPreviousPage => _isFetchingPreviousPage;
  bool get hasNextPage => _hasNextPage;
  bool get hasPreviousPage => _hasPreviousPage;

  PageParam _currentParam;

  final Set<InfiniteQueryListeners<T, PageParam>> onDataListeners = Set();
  final Set<InfiniteQueryListeners<dynamic, PageParam>> onErrorListeners =
      Set();

  InfiniteQuery({
    required super.queryKey,
    required this.task,
    required super.staleTime,
    required super.cacheTime,
    required super.externalData,
    required super.retries,
    required super.retryDelay,
    required super.status,
    required PageParam initialParam,
    super.refetchOnMount,
    super.refetchOnReconnect,
    super.refetchInterval,
    super.enabled,
    super.previousData,
    super.connectivity,
    super.refetchOnApplicationResume,
    InfiniteQueryListeners<T, PageParam>? super.onData,
    InfiniteQueryListeners<dynamic, PageParam>? super.onError,
    required T? initialPage,
    this.getNextPageParam,
    this.getPreviousPageParam,
  })  : _currentParam = initialParam,
        super(initialData: {initialParam: initialPage});

  InfiniteQuery.fromOptions(
    InfiniteQueryJob<T, Outside, PageParam> options, {
    required Outside externalData,
    InfiniteQueryListeners<T, PageParam>? onData,
    InfiniteQueryListeners<dynamic, PageParam>? onError,
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
          refetchOnApplicationResume: options.refetchOnApplicationResume,
          onData: onData,
          onError: onError,
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
      final page = data?[_currentParam];
      if (data == null || page == null) await execute();
      _isFetchingNextPage = true;
      _isFetchingPreviousPage = false;
      final nextParam = page != null
          ? await (getNextPageParam ?? this.getNextPageParam)?.call(
              page,
              _currentParam,
            )
          : null;
      if (nextParam == null) {
        _hasNextPage = false;
        notifyListeners();
        return null;
      } else {
        _hasNextPage = true;
        _currentParam = nextParam;
        return await fetch().then((_) => data?[_currentParam]);
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
      final page = data?[_currentParam];
      if (page == null) await execute();
      final prevParam = page != null
          ? await (getPreviousPageParam ?? this.getPreviousPageParam)?.call(
              page,
              _currentParam,
            )
          : null;
      if (prevParam == null) {
        _hasPreviousPage = false;
        notifyListeners();
        return null;
      }
      _hasPreviousPage = true;
      _currentParam = prevParam;
      return await fetch().then((_) => data?[_currentParam]);
    } catch (e) {
      print("[InfiniteQuery.fetchPreviousPage]: $e");
      rethrow;
    } finally {
      _isFetchingPreviousPage = false;
      notifyListeners();
    }
  }

  Future<List<T>> refetchPages([
    bool Function(T? page, PageParam pageParam, List<T?> allPages)? selector,
  ]) async {
    if (isFetchingNextPage ||
        isFetchingPreviousPage ||
        isLoading ||
        isRefetching) return [];
    final refetchedPages = <T>[];
    final queue = Queue();
    for (final entry in data?.entries.toList() ?? <MapEntry<PageParam, T?>>[]) {
      final page = entry.value;
      final selected = selector?.call(page, entry.key, pages) ?? true;
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
  @protected
  FutureOr<void> notifyDataListeners() async {
    for (var onData in onDataListeners) {
      if (data?[_currentParam] == null) continue;
      onData.call(data![_currentParam]!, _currentParam, pages);
    }
  }

  @override
  @protected
  FutureOr<void> notifyErrorListeners() async {
    for (var onError in onErrorListeners) {
      onError.call(error?[_currentParam], _currentParam, errors);
    }
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
