import 'package:fl_query/src/collections/default_configs.dart';
import 'package:fl_query/src/core/client.dart';
import 'package:flutter/material.dart';

class RefreshConfig {
  final Duration staleDuration;
  final Duration refreshInterval;
  final bool refreshOnMount;
  final bool refreshOnQueryFnChange;

  const RefreshConfig({
    required this.staleDuration,
    required this.refreshInterval,
    required this.refreshOnMount,
    required this.refreshOnQueryFnChange,
  });

  factory RefreshConfig.withDefaults(
    BuildContext context, {
    Duration? staleDuration,
    Duration? refreshInterval,
    bool? refreshOnMount,
    bool? refreshOnQueryFnChange,
  }) {
    return QueryClient.of(context).refreshConfig.copyWith(
          staleDuration: staleDuration,
          refreshInterval: refreshInterval,
          refreshOnMount: refreshOnMount,
          refreshOnQueryFnChange: refreshOnQueryFnChange,
        );
  }

  factory RefreshConfig.withConstantDefaults({
    Duration? staleDuration,
    Duration? refreshInterval,
    bool? refreshOnMount,
    bool? refreshOnQueryFnChange,
  }) {
    return DefaultConstants.refreshConfig.copyWith(
      staleDuration: staleDuration,
      refreshInterval: refreshInterval,
      refreshOnMount: refreshOnMount,
      refreshOnQueryFnChange: refreshOnQueryFnChange,
    );
  }

  RefreshConfig copyWith({
    Duration? staleDuration,
    Duration? refreshInterval,
    bool? refreshOnMount,
    bool? refreshOnQueryFnChange,
  }) {
    return RefreshConfig(
      staleDuration: staleDuration ?? this.staleDuration,
      refreshInterval: refreshInterval ?? this.refreshInterval,
      refreshOnMount: refreshOnMount ?? this.refreshOnMount,
      refreshOnQueryFnChange:
          refreshOnQueryFnChange ?? this.refreshOnQueryFnChange,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'staleDuration': staleDuration.toString(),
      'refreshInterval': refreshInterval.toString(),
      'refreshOnMount': refreshOnMount,
      'refreshOnQueryFnChange': refreshOnQueryFnChange,
    };
  }
}
