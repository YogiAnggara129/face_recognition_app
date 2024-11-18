import 'package:equatable/equatable.dart';

class DatabaseException extends Equatable implements Exception {
  final String message;

  const DatabaseException(this.message);

  factory DatabaseException.generalError() =>
      const DatabaseException('Terjadi kesalahan');
  factory DatabaseException.dataEmpty() =>
      const DatabaseException('Data tidak tersedia');
  factory DatabaseException.saveError() =>
      const DatabaseException('Gagal menyimpan data');

  @override
  List<Object?> get props => [message];
}

class ServerException extends Equatable implements Exception {
  final String message;

  const ServerException(this.message);

  factory ServerException.generalError() =>
      const ServerException('Terjadi kesalahan pada server');
  factory ServerException.dataEmpty() => const ServerException('Data tidak tersedia');

  @override
  List<Object?> get props => [message];
}

class AuthException extends ServerException {
  const AuthException() : super('Sesi telah berakhir');
}

class DeviceException implements Exception {
  final String message;

  DeviceException(this.message);

  factory DeviceException.generalError() =>
      DeviceException('Terjadi kesalahan');
  factory DeviceException.notSupport() =>
      DeviceException('Ponsel tidak support');
}
