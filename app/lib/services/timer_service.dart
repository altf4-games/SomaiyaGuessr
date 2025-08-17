import 'dart:async';
import 'package:flutter/foundation.dart';

class TimerService {
  Timer? _timer;
  int _timeLeft = 0;
  int _totalTime = 30;
  bool _isActive = false;
  
  // Stream controllers
  final StreamController<int> _timeController = StreamController.broadcast();
  final StreamController<bool> _activeController = StreamController.broadcast();
  final StreamController<void> _timeUpController = StreamController.broadcast();
  
  // Getters for streams
  Stream<int> get timeStream => _timeController.stream;
  Stream<bool> get activeStream => _activeController.stream;
  Stream<void> get timeUpStream => _timeUpController.stream;
  
  // Getters for current state
  int get timeLeft => _timeLeft;
  int get totalTime => _totalTime;
  bool get isActive => _isActive;
  double get progress => _totalTime > 0 ? (_totalTime - _timeLeft) / _totalTime : 1.0;
  
  // Singleton pattern
  static final TimerService _instance = TimerService._internal();
  factory TimerService() => _instance;
  TimerService._internal();

  void startTimer({int duration = 30}) {
    stopTimer();
    
    _totalTime = duration;
    _timeLeft = duration;
    _isActive = true;
    
    _timeController.add(_timeLeft);
    _activeController.add(_isActive);
    
    if (kDebugMode) {
      print('⏰ Timer started: ${duration}s');
    }
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _timeLeft--;
      _timeController.add(_timeLeft);
      
      if (kDebugMode) {
        print('⏰ Timer: ${_timeLeft}s remaining');
      }
      
      if (_timeLeft <= 0) {
        _onTimeUp();
      }
    });
  }
  
  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    _isActive = false;
    _activeController.add(_isActive);
    
    if (kDebugMode) {
      print('⏰ Timer stopped');
    }
  }
  
  void pauseTimer() {
    _timer?.cancel();
    _timer = null;
    _isActive = false;
    _activeController.add(_isActive);
    
    if (kDebugMode) {
      print('⏰ Timer paused at ${_timeLeft}s');
    }
  }
  
  void resumeTimer() {
    if (_timeLeft > 0) {
      _isActive = true;
      _activeController.add(_isActive);
      
      if (kDebugMode) {
        print('⏰ Timer resumed at ${_timeLeft}s');
      }
      
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _timeLeft--;
        _timeController.add(_timeLeft);
        
        if (kDebugMode) {
          print('⏰ Timer: ${_timeLeft}s remaining');
        }
        
        if (_timeLeft <= 0) {
          _onTimeUp();
        }
      });
    }
  }
  
  void addTime(int seconds) {
    _timeLeft += seconds;
    _totalTime += seconds;
    _timeController.add(_timeLeft);
    
    if (kDebugMode) {
      print('⏰ Added ${seconds}s to timer. New time: ${_timeLeft}s');
    }
  }
  
  void setTime(int seconds) {
    _timeLeft = seconds;
    _timeController.add(_timeLeft);
    
    if (kDebugMode) {
      print('⏰ Timer set to ${_timeLeft}s');
    }
  }
  
  void _onTimeUp() {
    stopTimer();
    _timeUpController.add(null);
    
    if (kDebugMode) {
      print('⏰ Time up!');
    }
  }
  
  void reset({int? duration}) {
    stopTimer();
    _totalTime = duration ?? _totalTime;
    _timeLeft = _totalTime;
    _timeController.add(_timeLeft);
    
    if (kDebugMode) {
      print('⏰ Timer reset to ${_totalTime}s');
    }
  }
  
  void dispose() {
    stopTimer();
    _timeController.close();
    _activeController.close();
    _timeUpController.close();
  }
}

// Extension for easier time formatting
extension TimeFormatting on int {
  String get formattedTime {
    final minutes = this ~/ 60;
    final seconds = this % 60;
    if (minutes > 0) {
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${seconds}s';
    }
  }
}

// Timer state enum
enum TimerState {
  idle,
  running,
  paused,
  finished,
}

// Timer configuration class
class TimerConfig {
  final int duration;
  final bool autoStart;
  final bool showWarningAt;
  final int warningThreshold;
  final bool vibrate;
  final bool playSound;
  
  const TimerConfig({
    this.duration = 30,
    this.autoStart = false,
    this.showWarningAt = true,
    this.warningThreshold = 10,
    this.vibrate = false,
    this.playSound = false,
  });
}

// Advanced timer service with more features
class AdvancedTimerService {
  final TimerService _timerService = TimerService();
  TimerConfig _config = const TimerConfig();
  TimerState _state = TimerState.idle;

  TimerState get state => _state;
  TimerConfig get config => _config;

  // Delegate to TimerService
  Stream<int> get timeStream => _timerService.timeStream;
  Stream<bool> get activeStream => _timerService.activeStream;
  Stream<void> get timeUpStream => _timerService.timeUpStream;
  int get timeLeft => _timerService.timeLeft;
  int get totalTime => _timerService.totalTime;
  bool get isActive => _timerService.isActive;
  double get progress => _timerService.progress;
  
  void configure(TimerConfig config) {
    _config = config;
  }

  void startTimer({int? duration}) {
    final timerDuration = duration ?? _config.duration;
    _timerService.startTimer(duration: timerDuration);
    _state = TimerState.running;
  }

  void stopTimer() {
    _timerService.stopTimer();
    _state = TimerState.idle;
  }

  void pauseTimer() {
    _timerService.pauseTimer();
    _state = TimerState.paused;
  }

  void resumeTimer() {
    _timerService.resumeTimer();
    _state = TimerState.running;
  }

  void dispose() {
    _timerService.dispose();
  }
}
