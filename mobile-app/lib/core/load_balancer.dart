import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiNode {
  final String id;
  final String name;
  final String baseUrl;
  final String region;
  int latencyMs;
  bool isHealthy;
  int consecutiveFailures;
  DateTime? quarantinedUntil;

  ApiNode({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.region,
    this.latencyMs = 999,
    this.isHealthy = true,
    this.consecutiveFailures = 0,
    this.quarantinedUntil,
  });
}

class LoadBalancer {
  LoadBalancer._();
  static final LoadBalancer instance = LoadBalancer._();

  final List<ApiNode> _nodes = [
    ApiNode(
      id: 'node-vercel-edge',
      name: 'Vercel Global Edge API',
      baseUrl: 'https://project-chi-six-62.vercel.app',
      region: 'Global Edge (Anycast)',
    ),
    ApiNode(
      id: 'node-render-primary',
      name: 'Render Dedicated API Node',
      baseUrl: 'https://project-9zrh.onrender.com',
      region: 'Frankfurt (eu-central)',
    ),
    ApiNode(
      id: 'node-backup-edge',
      name: 'MyVault Cloud Secondary Node',
      baseUrl: 'https://myvault-api-direct.vercel.app',
      region: 'Stockholm (eu-north)',
    ),
  ];

  int _roundRobinIndex = 0;
  Timer? _healthCheckTimer;

  List<ApiNode> get nodes => List.unmodifiable(_nodes);

  void startHealthChecks() {
    _healthCheckTimer?.cancel();
    benchmarkAllNodes();
    _healthCheckTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      benchmarkAllNodes();
    });
  }

  Future<void> benchmarkAllNodes() async {
    final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 4), receiveTimeout: const Duration(seconds: 4)));

    for (final node in _nodes) {
      if (node.quarantinedUntil != null && DateTime.now().isBefore(node.quarantinedUntil!)) {
        continue;
      }

      final sw = Stopwatch()..start();
      try {
        final res = await dio.get('${node.baseUrl}/subjects');
        sw.stop();
        if (res.statusCode == 200) {
          node.latencyMs = sw.elapsedMilliseconds;
          node.isHealthy = true;
          node.consecutiveFailures = 0;
          node.quarantinedUntil = null;
        } else {
          _recordFailure(node);
        }
      } catch (_) {
        _recordFailure(node);
      }
    }
  }

  void _recordFailure(ApiNode node) {
    node.consecutiveFailures++;
    if (node.consecutiveFailures >= 2) {
      node.isHealthy = false;
      node.quarantinedUntil = DateTime.now().add(const Duration(seconds: 60));
      debugPrint('[LoadBalancer] Quarantined ${node.name} for 60s due to consecutive timeouts');
    }
  }

  void recordRequestSuccess(String url, int elapsedMs) {
    final node = _nodes.firstWhere((n) => url.startsWith(n.baseUrl), orElse: () => _nodes.first);
    node.isHealthy = true;
    node.latencyMs = elapsedMs;
    node.consecutiveFailures = 0;
  }

  void recordRequestFailure(String url) {
    final node = _nodes.firstWhere((n) => url.startsWith(n.baseUrl), orElse: () => _nodes.first);
    _recordFailure(node);
  }

  String getOptimalBaseUrl() {
    // 1. Filter healthy non-quarantined nodes
    final healthy = _nodes.where((n) {
      if (n.quarantinedUntil != null && DateTime.now().isBefore(n.quarantinedUntil!)) {
        return false;
      }
      return n.isHealthy;
    }).toList();

    if (healthy.isEmpty) {
      return _nodes.first.baseUrl;
    }

    // 2. Sort by lowest latency
    healthy.sort((a, b) => a.latencyMs.compareTo(b.latencyMs));
    return healthy.first.baseUrl;
  }

  String getRoundRobinBaseUrl() {
    final healthy = _nodes.where((n) => n.isHealthy).toList();
    if (healthy.isEmpty) return _nodes.first.baseUrl;

    _roundRobinIndex = (_roundRobinIndex + 1) % healthy.length;
    return healthy[_roundRobinIndex].baseUrl;
  }

  ApiNode get activeNode {
    final url = getOptimalBaseUrl();
    return _nodes.firstWhere((n) => n.baseUrl == url, orElse: () => _nodes.first);
  }
}
