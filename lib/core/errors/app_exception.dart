import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

/// The kind of failure that happened, so the UI can pick the right
/// icon / wording / call-to-action instead of dumping a raw exception.
enum AppErrorType {
  /// Device is offline or the host could not be reached at all.
  noConnection,

  /// Reached the network but it took too long.
  timeout,

  /// Reached the server, but it answered with an error.
  server,

  /// Signed-out / permission denied.
  unauthorized,

  /// Anything we could not classify.
  unknown,
}

/// A failure with a message that is safe to show to a user.
///
/// Repositories throw this instead of a raw [DioException] or a bare
/// `String`, so pages never have to call `e.toString()` on screen.
class AppException implements Exception {
  final AppErrorType type;
  final String message;
  final Object? cause;

  const AppException(
    this.type,
    this.message, {
    this.cause,
  });

  const AppException.noConnection([
    this.message = 'No internet connection. Check your network and try again.',
    this.cause,
  ]) : type = AppErrorType.noConnection;

  /// Maps any thrown object onto a user-presentable failure.
  factory AppException.from(Object? error) {
    if (error is AppException) return error;

    if (error is DioException) return AppException._fromDio(error);

    if (error is SocketException) {
      return AppException.noConnection(
        'No internet connection. Check your network and try again.',
        error,
      );
    }

    if (error is TimeoutException) {
      return AppException(
        AppErrorType.timeout,
        'The request took too long. Please try again.',
        cause: error,
      );
    }

    final text = error?.toString() ?? '';
    if (_looksOffline(text)) {
      return AppException.noConnection(
        'No internet connection. Check your network and try again.',
        error,
      );
    }
    if (text.contains('permission-denied') || text.contains('unauthenticated')) {
      return AppException(
        AppErrorType.unauthorized,
        'You do not have access to this. Try signing in again.',
        cause: error,
      );
    }

    return AppException(
      AppErrorType.unknown,
      'Something went wrong. Please try again.',
      cause: error,
    );
  }

  factory AppException._fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppException(
          AppErrorType.timeout,
          'The connection timed out. Please try again.',
          cause: error,
        );
      case DioExceptionType.connectionError:
        return AppException.noConnection(
          'No internet connection. Check your network and try again.',
          error,
        );
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        if (status == 401 || status == 403) {
          return AppException(
            AppErrorType.unauthorized,
            'You do not have access to this. Try signing in again.',
            cause: error,
          );
        }
        return AppException(
          AppErrorType.server,
          'Our kitchen is having trouble right now. Please try again shortly.',
          cause: error,
        );
      case DioExceptionType.cancel:
        return AppException(
          AppErrorType.unknown,
          'The request was cancelled.',
          cause: error,
        );
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        if (error.error is SocketException || _looksOffline(error.toString())) {
          return AppException.noConnection(
            'No internet connection. Check your network and try again.',
            error,
          );
        }
        return AppException(
          AppErrorType.unknown,
          'Something went wrong. Please try again.',
          cause: error,
        );
    }
  }

  static bool _looksOffline(String text) {
    final lower = text.toLowerCase();
    return lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable') ||
        lower.contains('no address associated') ||
        lower.contains('connection refused') ||
        lower.contains('connection closed') ||
        lower.contains('unavailable');
  }

  /// True when retrying once the device is back online is likely to help.
  bool get isConnectivityIssue =>
      type == AppErrorType.noConnection || type == AppErrorType.timeout;

  /// Short headline for an error screen.
  String get title {
    switch (type) {
      case AppErrorType.noConnection:
        return "You're offline";
      case AppErrorType.timeout:
        return 'Connection timed out';
      case AppErrorType.server:
        return 'Something went wrong';
      case AppErrorType.unauthorized:
        return 'Access denied';
      case AppErrorType.unknown:
        return 'Something went wrong';
    }
  }

  @override
  String toString() => message;
}

