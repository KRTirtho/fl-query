import 'dart:async';

import 'package:fl_query/src/mixins/autocast.dart';
import 'package:fl_query/src/models/infinite_query_job.dart';
import 'package:flutter/widgets.dart';

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
    with ChangeNotifier, AutoCast {
  String queryKey;

  Map<PageParam, T?> _data;
  Map<PageParam, dynamic> _error;

  InfiniteQueryTaskFunction<T, Outside, PageParam> task;

  InfiniteQueryPageParamFunction<T, PageParam>? getNextPageParam;
  InfiniteQueryPageParamFunction<T, PageParam>? getPreviousPageParam;

  List<PageParam> get pageParams => _data.keys.toList();
  List<dynamic> get errors => _error.values.toList();
  List<T?> get pages => _data.values.toList();

  PageParam currentParam;

  Outside _externalData;

  bool _hasNextPage = false;
  bool _hasPreviousPage = false;

  bool get hasNextPage => _hasNextPage;
  bool get hasPreviousPage => _hasPreviousPage;

  InfiniteQuery({
    required this.queryKey,
    required this.task,
    required PageParam initialParam,
    required Outside externalData,
    this.getNextPageParam,
    this.getPreviousPageParam,
    T? initialPage,
  })  : currentParam = initialParam,
        _externalData = externalData,
        _error = {},
        _data = {
          if (initialPage != null) initialParam: initialPage,
        };

  InfiniteQuery.fromOptions(
    InfiniteQueryJob<T, Outside, PageParam> options, {
    required Outside externalData,
  })  : queryKey = options.queryKey,
        task = options.task,
        currentParam = options.initialParam,
        _externalData = externalData,
        _error = {},
        getNextPageParam = options.getNextPageParam,
        getPreviousPageParam = options.getPreviousPageParam,
        _data = {
          if (options.initialPage != null)
            options.initialParam: options.initialPage,
        };

  Future<void> _execute() async {
    final page = await task(
      queryKey,
      currentParam,
      _externalData,
    );
    _data[currentParam] = page;
    notifyListeners();
  }

  Future<List<T?>> fetch() async {
    if (_data.isEmpty) await _execute();
    return pages;
  }

  Future<T?> fetchNextPage([
    InfiniteQueryPageParamFunction<T, PageParam>? getNextPageParam,
  ]) async {
    try {
      if (_data[currentParam] == null) await _execute();
      final nextParam = await (getNextPageParam ?? this.getNextPageParam)?.call(
        _data[currentParam]!,
        currentParam,
      );
      if (nextParam == null) {
        _hasNextPage = false;
        notifyListeners();
        return null;
      }
      _hasNextPage = true;
      currentParam = nextParam;
      return await _execute().then((_) => _data[currentParam]);
    } catch (e) {
      print("[InfiniteQuery.fetchNextPage]: $e");
      rethrow;
    }
  }

  Future<T?> fetchPreviousPage([
    InfiniteQueryPageParamFunction<T, PageParam>? getPreviousPageParam,
  ]) async {
    try {
      if (_data[currentParam] == null) await _execute();
      final prevParam =
          await (getNextPageParam ?? this.getPreviousPageParam)?.call(
        _data[currentParam]!,
        currentParam,
      );
      if (prevParam == null) {
        _hasPreviousPage = false;
        notifyListeners();
        return null;
      }
      _hasPreviousPage = true;
      currentParam = prevParam;
      return await _execute().then((_) => _data[currentParam]);
    } catch (e) {
      print("[InfiniteQuery.fetchPreviousPage]: $e");
      rethrow;
    }
  }
}
