import 'package:fl_query/src/collections/default_configs.dart';
import 'package:fl_query/src/core/cache.dart';
import 'package:fl_query/src/core/client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class QueryClientProvider extends InheritedWidget {
  final QueryClient client;
  QueryClientProvider({
    super.key,
    required super.child,
    QueryClient? client,
    QueryCache? cache,
    Duration cacheDuration = DefaultConstants.cacheDuration,
    int? maxRetries,
    Duration? retryDelay,
    Duration? staleDuration,
    Duration? refreshInterval,
    bool? refreshOnMount,
    bool? refreshOnQueryFnChange,
  })  : assert(
          (client == null && cache != null) || cache == null,
          '[QueryClientProvider] no `client` must be provided when supplying `cache`',
        ),
        assert(
          (client == null && maxRetries != null) || maxRetries == null,
          '[QueryClientProvider] no `client` must be provided when supplying `maxRetries`',
        ),
        assert(
          (client == null && retryDelay != null) || retryDelay == null,
          '[QueryClientProvider] no `client` must be provided when supplying `retryDelay`',
        ),
        assert(
          (client == null && staleDuration != null) || staleDuration == null,
          '[QueryClientProvider] no `client` must be provided when supplying `staleDuration`',
        ),
        assert(
          (client == null && refreshInterval != null) ||
              refreshInterval == null,
          '[QueryClientProvider] no `client` must be provided when supplying `refreshInterval`',
        ),
        assert(
          (client == null && refreshOnMount != null) || refreshOnMount == null,
          '[QueryClientProvider] no `client` must be provided when supplying `refreshOnMount`',
        ),
        assert(
          (client == null && refreshOnQueryFnChange != null) ||
              refreshOnQueryFnChange == null,
          '[QueryClientProvider] no `client` must be provided when supplying `refreshOnQueryFnChange`',
        ),
        assert(
          (client == null && cacheDuration != DefaultConstants.cacheDuration) ||
              cacheDuration == DefaultConstants.cacheDuration,
          '[QueryClientProvider] no `client` must be provided when supplying `cacheDuration`',
        ),
        client = client ??
            QueryClient(
              cache: cache,
              cacheDuration: cacheDuration,
              maxRetries: maxRetries,
              retryDelay: retryDelay,
              staleDuration: staleDuration,
              refreshInterval: refreshInterval,
              refreshOnMount: refreshOnMount,
              refreshOnQueryFnChange: refreshOnQueryFnChange,
            );

  @override
  bool updateShouldNotify(covariant QueryClientProvider oldWidget) {
    return client != oldWidget.client;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<QueryClient>('client', client));
  }
}
