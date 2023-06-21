import 'package:fl_query/src/collections/default_configs.dart';
import 'package:fl_query/src/core/client.dart';
import 'package:flutter/material.dart';

class RetryConfig {
  final int maxRetries;
  final Duration retryDelay;
  final bool cancelWhenOffline;

  const RetryConfig({
    required this.maxRetries,
    required this.retryDelay,
    required this.cancelWhenOffline,
  });

  factory RetryConfig.withDefaults(
    BuildContext context, {
    int? maxRetries,
    Duration? retryDelay,
  }) {
    return QueryClient.of(context).retryConfig.copyWith(
          maxRetries: maxRetries,
          retryDelay: retryDelay,
        );
  }

  factory RetryConfig.withConstantDefaults({
    int? maxRetries,
    Duration? retryDelay,
  }) {
    return DefaultConstants.retryConfig.copyWith(
      maxRetries: maxRetries,
      retryDelay: retryDelay,
    );
  }

  RetryConfig copyWith({
    int? maxRetries,
    Duration? retryDelay,
    bool? cancelWhenOffline,
  }) {
    return RetryConfig(
      maxRetries: maxRetries ?? this.maxRetries,
      retryDelay: retryDelay ?? this.retryDelay,
      cancelWhenOffline: cancelWhenOffline ?? this.cancelWhenOffline,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxRetries': maxRetries,
      'retryDelay': retryDelay.toString(),
    };
  }
}
