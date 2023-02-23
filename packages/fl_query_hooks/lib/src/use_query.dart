import 'dart:async';

import 'package:fl_query/fl_query.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

Query<DataType, ErrorType> useQuery<DataType, ErrorType>(
  final String queryKey,
  final QueryFn<DataType> queryFn, {
  final DataType? initial,
  final RetryConfig retryConfig = DefaultConstants.retryConfig,
  final RefreshConfig refreshConfig = DefaultConstants.refreshConfig,
  final JsonConfig<DataType>? jsonConfig,
  final ValueChanged<DataType>? onData,
  final ValueChanged<ErrorType>? onError,

  // widget specific
  final bool enabled = true,
}) {
  return use(
    UseQuery<DataType, ErrorType>(
      queryKey,
      queryFn,
      initial: initial,
      retryConfig: retryConfig,
      refreshConfig: refreshConfig,
      jsonConfig: jsonConfig,
      onData: onData,
      onError: onError,
      enabled: enabled,
    ),
  );
}

class UseQuery<DataType, ErrorType> extends Hook<Query<DataType, ErrorType>> {
  final QueryFn<DataType> queryFn;
  final String queryKey;

  final DataType? initial;

  final RetryConfig retryConfig;
  final RefreshConfig refreshConfig;
  final JsonConfig<DataType>? jsonConfig;

  final ValueChanged<DataType>? onData;
  final ValueChanged<ErrorType>? onError;

  // hook specific
  final bool enabled;

  const UseQuery(
    this.queryKey,
    this.queryFn, {
    this.initial,
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
  HookState<Query<DataType, ErrorType>, UseQuery<DataType, ErrorType>>
      createState() => _UseQueryState<DataType, ErrorType>();
}

class _UseQueryState<DataType, ErrorType> extends HookState<
    Query<DataType, ErrorType>, UseQuery<DataType, ErrorType>> {
  Query<DataType, ErrorType>? query;

  VoidCallback? removeListener;

  StreamSubscription<DataType>? dataSubscription;
  StreamSubscription<ErrorType>? errorSubscription;

  void rebuild([_]) {
    setState(() {});
  }

  Future<void> initialize() async {
    setState(() {
      query = QueryClient.of(context).createQuery(
        hook.queryKey,
        hook.queryFn,
        initial: hook.initial,
        retryConfig: hook.retryConfig,
        refreshConfig: hook.refreshConfig,
        jsonConfig: hook.jsonConfig,
      );

      if (hook.onData != null)
        dataSubscription = query!.dataStream.listen(hook.onData);
      if (hook.onData != null)
        errorSubscription = query!.errorStream.listen(hook.onError);

      removeListener = query!.addListener(rebuild);
    });
    if (hook.enabled) {
      await query!.fetch();
    }
  }

  @override
  void initHook() {
    super.initHook();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await initialize();
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
  void didUpdateHook(
    UseQuery<DataType, ErrorType> oldHook,
  ) {
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
  Query<DataType, ErrorType> build(BuildContext context) {
    if (query == null) {
      query = QueryClient.of(context).createQuery(
        hook.queryKey,
        hook.queryFn,
        initial: hook.initial,
        retryConfig: hook.retryConfig,
        refreshConfig: hook.refreshConfig,
        jsonConfig: hook.jsonConfig,
      );
    }
    return query!;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<Query<DataType, ErrorType>>('query', query),
    );
    properties.add(
      DiagnosticsProperty<String>('queryKey', hook.queryKey),
    );
    properties.add(DiagnosticsProperty<DataType>('initial', hook.initial));
    properties.add(
      DiagnosticsProperty<RetryConfig>('retryConfig', hook.retryConfig),
    );
    properties.add(
      DiagnosticsProperty<RefreshConfig>(
        'refreshConfig',
        hook.refreshConfig,
      ),
    );
    properties.add(
      DiagnosticsProperty<JsonConfig<DataType>>(
        'jsonConfig',
        hook.jsonConfig,
      ),
    );
    properties.add(
      DiagnosticsProperty<ValueChanged<DataType>>('onData', hook.onData),
    );
    properties.add(
      DiagnosticsProperty<ValueChanged<ErrorType>>('onError', hook.onError),
    );
    properties.add(DiagnosticsProperty<bool>('enabled', hook.enabled));
  }
}
