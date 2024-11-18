import 'dart:developer';

import 'package:face_recognition_app/core/base/exception.dart';

sealed class Result<T> {
  bool get isSuccess {
    switch (this) {
      case Success _:
        return true;
      default:
        return false;
    }
  }

  bool get isFailed {
    switch (this) {
      case Failed _:
        return true;
      default:
        return false;
    }
  }
}

class Success<T> extends Result<T> {
  final T value;
  Success({required this.value});
}

class Failed<T> extends Result<T> {
  final String message;
  final bool authError;
  Failed({required this.message, this.authError = false});

  factory Failed.auth() =>
      Failed(message: 'Sesi telah berakhir', authError: true);

  factory Failed.fromException(Object error, {Object? stacktrace}) {
    log('[Failed.fromException] ERROR: $error\n$stacktrace');
    if (error is AuthException) {
      return Failed.auth();
    } else if (error is ServerException) {
      return Failed<T>(message: error.message);
    } else if (error is DatabaseException) {
      return Failed<T>(message: error.message);
    } else if (error is DeviceException) {
      return Failed<T>(message: error.message);
    } else {
      return Failed<T>(message: 'Terjadi kesalahan');
    }
  }
}
