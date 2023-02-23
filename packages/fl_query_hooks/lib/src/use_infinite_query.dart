import 'dart:async';

import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/diagnostics.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

InfiniteQuery<DataType, ErrorType, PageType>
    useInfiniteQuery<DataType, ErrorType, PageType>(
  String queryKey,
  InfiniteQueryFn<DataType, PageType> queryFn, {
  required InfiniteQueryNextPage<DataType, PageType> nextPage,
  required PageType initialPage,
  RetryConfig retryConfig = DefaultConstants.retryConfig,
  RefreshConfig refreshConfig = DefaultConstants.refreshConfig,
  JsonConfig<DataType>? jsonConfig,
  ValueChanged<PageEvent<DataType, PageType>>? onData,
  ValueChanged<PageEvent<ErrorType, PageType>>? onError,
  bool enabled = true,
  List<Object?>? keys,
}) {
  return use(UseInfiniteQuery(
    queryKey,
    queryFn,
    nextPage: nextPage,
    initialPage: initialPage,
    retryConfig: retryConfig,
    refreshConfig: refreshConfig,
    jsonConfig: jsonConfig,
    onData: onData,
    onError: onError,
    enabled: enabled,
    keys: keys,
  ));
}

class UseInfiniteQuery<DataType, ErrorType, PageType>
    extends Hook<InfiniteQuery<DataType, ErrorType, PageType>> {
  final InfiniteQueryFn<DataType, PageType> queryFn;
  final String queryKey;

  final PageType initialPage;
  final InfiniteQueryNextPage<DataType, PageType> nextPage;

  final RetryConfig retryConfig;
  final RefreshConfig refreshConfig;
  final JsonConfig<DataType>? jsonConfig;

  final ValueChanged<PageEvent<DataType, PageType>>? onData;
  final ValueChanged<PageEvent<ErrorType, PageType>>? onError;

  // widget specific
  final bool enabled;

  const UseInfiniteQuery(
    this.queryKey,
    this.queryFn, {
    required this.nextPage,
    required this.initialPage,
    this.retryConfig = DefaultConstants.retryConfig,
    this.refreshConfig = DefaultConstants.refreshConfig,
    this.jsonConfig,
    this.onData,
    this.onError,
    this.enabled = true,
    super.keys,
  }) : assert(
          (jsonConfig != null && enabled) || jsonConfig == null,
          'jsonConfig is only supported when enabled is true',
        );

  @override
  createState() => _UseInfiniteQueryState<DataType, ErrorType, PageType>();
}

class _UseInfiniteQueryState<DataType, ErrorType, PageType> extends HookState<
    InfiniteQuery<DataType, ErrorType, PageType>,
    UseInfiniteQuery<DataType, ErrorType, PageType>> {
  InfiniteQuery<DataType, ErrorType, PageType>? query;

  VoidCallback? removeListener;

  StreamSubscription<PageEvent<DataType, PageType>>? dataSubscription;
  StreamSubscription<PageEvent<ErrorType, PageType>>? errorSubscription;

  void rebuild([_]) {
    setState(() {});
  }

  Future<void> initialize() async {
    setState(() {
      _createQuery();

      if (hook.onData != null)
        dataSubscription = query!.dataStream.listen(hook.onData);
      if (hook.onError != null)
        errorSubscription = query!.errorStream.listen(hook.onError);

      removeListener = query!.addListener(rebuild);
    });
    if (hook.enabled) {
      await query!.fetch();
    }
  }

  void _createQuery() {
    query = QueryClient.of(context).createInfiniteQuery(
      hook.queryKey,
      hook.queryFn,
      initialParam: hook.initialPage,
      nextPage: hook.nextPage,
      retryConfig: hook.retryConfig,
      refreshConfig: hook.refreshConfig,
      jsonConfig: hook.jsonConfig,
    );
  }

  @override
  void initHook() {
    super.initHook();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initialize();
    });
  }

  @override
  void dispose() {
    dataSubscription?.cancel();
    errorSubscription?.cancel();
    removeListener?.call();
    super.dispose();
  }

  @override
  void didUpdateHook(oldHook) {
    super.didUpdateHook(oldHook);

    if (oldHook.queryKey != hook.queryKey) {
      dataSubscription?.cancel();
      errorSubscription?.cancel();
      removeListener?.call();
      initialize();
      return;
    } else if (oldHook.enabled != hook.enabled && hook.enabled) {
      query!.fetch();
    }
    if (oldHook.queryFn != hook.queryFn) {
      query!.updateQueryFn(hook.queryFn);
    }
    if (oldHook.nextPage != hook.nextPage) {
      query!.updateNextPageFn(hook.nextPage);
    }
    if (oldHook.onData != hook.onData) {
      dataSubscription?.cancel();
      if (hook.onData != null)
        dataSubscription = query!.dataStream.listen(hook.onData);
    }
    if (oldHook.onError != hook.onError) {
      errorSubscription?.cancel();
      if (hook.onError != null)
        errorSubscription = query!.errorStream.listen(hook.onError);
    }
  }

  @override
  build(BuildContext context) {
    if (query == null) {
      _createQuery();
    }
    return query!;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<InfiniteQueryFn<DataType, PageType>>(
      'queryFn',
      hook.queryFn,
    ));
    properties
        .add(DiagnosticsProperty<InfiniteQueryNextPage<DataType, PageType>>(
      'nextPage',
      hook.nextPage,
    ));
    properties.add(DiagnosticsProperty<PageType>(
      'initialPage',
      hook.initialPage,
    ));
    properties.add(DiagnosticsProperty<RetryConfig>(
      'retryConfig',
      hook.retryConfig,
    ));
    properties.add(DiagnosticsProperty<RefreshConfig>(
      'refreshConfig',
      hook.refreshConfig,
    ));
    properties.add(DiagnosticsProperty<JsonConfig<DataType>>(
      'jsonConfig',
      hook.jsonConfig,
    ));
    properties
        .add(DiagnosticsProperty<ValueChanged<PageEvent<DataType, PageType>>>(
      'onData',
      hook.onData,
    ));
    properties
        .add(DiagnosticsProperty<ValueChanged<PageEvent<ErrorType, PageType>>>(
      'onError',
      hook.onError,
    ));
    properties.add(DiagnosticsProperty<bool>(
      'enabled',
      hook.enabled,
    ));
    properties.add(DiagnosticsProperty<String>(
      'queryKey',
      hook.queryKey,
    ));
  }
}
