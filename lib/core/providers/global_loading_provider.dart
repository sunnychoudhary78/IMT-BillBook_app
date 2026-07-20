import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum GlobalOverlayState { idle, loading, success, error, message }

class GlobalLoadingState {
  final GlobalOverlayState state;
  final String message;

  const GlobalLoadingState({required this.state, required this.message});

  const GlobalLoadingState.idle()
      : state = GlobalOverlayState.idle,
        message = '';

  bool get isLoading => state == GlobalOverlayState.loading;
  bool get isSuccess => state == GlobalOverlayState.success;
  bool get isError => state == GlobalOverlayState.error;
  bool get isMessage => state == GlobalOverlayState.message;

  GlobalLoadingState copyWith({GlobalOverlayState? state, String? message}) {
    return GlobalLoadingState(
      state: state ?? this.state,
      message: message ?? this.message,
    );
  }
}

class GlobalLoadingNotifier extends Notifier<GlobalLoadingState> {
  Timer? _timer;

  @override
  GlobalLoadingState build() => const GlobalLoadingState.idle();

  void showLoading([String message = 'Please wait...']) {
    _cancelTimer();
    state = GlobalLoadingState(
      state: GlobalOverlayState.loading,
      message: message,
    );
  }

  void showSuccess(
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _cancelTimer();
    state = GlobalLoadingState(
      state: GlobalOverlayState.success,
      message: message,
    );
    _timer = Timer(duration, _hideInternal);
  }

  void showError(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _cancelTimer();
    final msg = message
        .replaceFirst('Exception:', '')
        .replaceFirst('Exception: ', '')
        .trim();
    state = GlobalLoadingState(state: GlobalOverlayState.error, message: msg);
    _timer = Timer(duration, _hideInternal);
  }

  void showMessage(
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _cancelTimer();
    state = GlobalLoadingState(
      state: GlobalOverlayState.message,
      message: message,
    );
    _timer = Timer(duration, _hideInternal);
  }

  void showApiError(Object e) {
    final msg = e.toString().replaceFirst('Exception: ', '').trim();
    showError(msg.isEmpty ? 'Something went wrong' : msg);
  }

  void hide() {
    _cancelTimer();
    _hideInternal();
  }

  void reset() {
    _cancelTimer();
    state = const GlobalLoadingState.idle();
  }

  void _hideInternal() {
    state = const GlobalLoadingState.idle();
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }
}

final globalLoadingProvider =
    NotifierProvider<GlobalLoadingNotifier, GlobalLoadingState>(
  GlobalLoadingNotifier.new,
);
