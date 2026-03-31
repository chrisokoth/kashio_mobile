import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../features/sms/data/sms_model.dart';
import '../features/sms/data/sms_repository.dart';
import '../features/sync/api_service.dart';
import '../features/auth/auth_service.dart';

enum LoadState { idle, loading, loaded, error }

class TransactionProvider extends ChangeNotifier {
  final SmsRepository smsRepository;
  final ApiService apiService;
  final AuthService authService;

  List<Transaction> _all = [];
  List<Transaction> _filtered = [];
  LoadState _loadState = LoadState.idle;
  bool _isSyncing = false;
  String? _error;
  String? _syncMessage;
  String _filter = 'ALL';
  String? _deviceId;

  List<Transaction> get transactions => _filtered;
  LoadState get loadState => _loadState;
  bool get isSyncing => _isSyncing;
  String? get error => _error;
  String? get syncMessage => _syncMessage;
  String get filter => _filter;

  double get totalIncome => _all
      .where((t) => t.isIncome)
      .fold(0, (sum, t) => sum + t.amount);

  double get totalExpenses => _all
      .where((t) => t.isExpense)
      .fold(0, (sum, t) => sum + t.amount);

  double get netBalance => totalIncome - totalExpenses;

  TransactionProvider({
    required this.smsRepository,
    required this.apiService,
    required this.authService,
  }) {
    _initDeviceId();
  }

  Future<void> _initDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('kashio_device_id');
    if (_deviceId == null) {
      _deviceId = const Uuid().v4();
      await prefs.setString('kashio_device_id', _deviceId!);
    }
  }

  Future<void> loadTransactions() async {
    _loadState = LoadState.loading;
    _error = null;
    notifyListeners();

    try {
      final granted = await smsRepository.requestPermission();
      if (!granted) {
        _loadState = LoadState.error;
        _error = 'SMS permission denied. Please grant SMS access in Settings.';
        notifyListeners();
        return;
      }

      _all = await smsRepository.getTransactions();
      _applyFilter();
      _loadState = LoadState.loaded;
    } catch (e) {
      _loadState = LoadState.error;
      _error = 'Failed to load messages: ${e.toString()}';
    }
    notifyListeners();
  }

  void setFilter(String f) {
    _filter = f;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    switch (_filter) {
      case 'INCOME':
        _filtered = _all.where((t) => t.isIncome).toList();
        break;
      case 'EXPENSE':
        _filtered = _all.where((t) => t.isExpense).toList();
        break;
      default:
        _filtered = List.from(_all);
    }
  }

  Future<void> syncToBackend() async {
    if (_all.isEmpty) return;
    final isLoggedIn = await authService.isLoggedIn();
    if (!isLoggedIn) {
      _syncMessage = 'Please log in to sync transactions.';
      notifyListeners();
      return;
    }

    _isSyncing = true;
    _syncMessage = null;
    notifyListeners();

    await _initDeviceId();

    final result = await apiService.syncTransactions(
      deviceId: _deviceId!,
      transactions: _all,
    );

    _isSyncing = false;
    _syncMessage = result.success
        ? '✓ Synced ${result.queued} messages to Kashio'
        : '✗ Sync failed: ${result.error}';
    notifyListeners();

    // Clear message after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      _syncMessage = null;
      notifyListeners();
    });
  }

  void clearSyncMessage() {
    _syncMessage = null;
    notifyListeners();
  }
}