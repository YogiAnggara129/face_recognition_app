import 'dart:io';

import 'package:face_recognition_app/core/base/result.dart';

abstract class AuthRepository {
  Future<Result<void>> authFace(String name, File image);
  Future<Result<void>> addAuthFace(String name, File image);
  Future<Result<void>> deleteAuthFace(String name);
  Future<Result<List<String>>> getAuthNames();
}
