import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service to monitor internet connectivity in real-time.
/// Used by repositories and sync engine to determine online/offline status.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  final StreamController<bool> _onlineController =
      StreamController<bool>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;

  /// Whether the device currently has internet connectivity.
  bool get isOnline => _isOnline;

  /// Stream of connectivity status changes.
  Stream<bool> get onlineStream => _onlineController.stream;

  /// Initialize the connectivity monitoring.
  Future<void> init() async {
    // Check initial status
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = results.any((r) => r != ConnectivityResult.none);

    if (wasOnline != _isOnline) {
      _onlineController.add(_isOnline);
    }
  }

  /// Manually check the current connectivity status.
  Future<bool> checkConnection() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = results.any((r) => r != ConnectivityResult.none);
    return _isOnline;
  }

  void dispose() {
    _subscription?.cancel();
    _onlineController.close();
  }
}
