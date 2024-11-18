import 'dart:io';

import 'package:face_recognition_app/core/base/result.dart';
import 'package:face_recognition_app/data/data_source/auth_ml_data_source.dart';
import 'package:face_recognition_app/data/data_source/auth_remote_data_source.dart';
import 'package:face_recognition_app/domain/data/auth_repository.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _authRemoteDataSource;
  final AuthMlDataSource _authMlDataSource;

  AuthRepositoryImpl(this._authRemoteDataSource, this._authMlDataSource);

  @override
  Future<Result<void>> addAuthFace(String name, File image) async {
    try {
      final input = await _cameraImageToInputImage(image);
      final face = await _authMlDataSource.getFace(input);
      final preProc = await _authMlDataSource.getPreProcess(image, face);
      await _authRemoteDataSource.addUser(name, face, preProc);
      return Success(value: null);
    } catch (e, s) {
      return Failed.fromException(e, stacktrace: s);
    }
  }

  @override
  Future<Result<void>> authFace(String name, File image) async {
    try {
      final input = await _cameraImageToInputImage(image);
      final facePred = await _authMlDataSource.getFace(input);
      final prePropPred =
          await _authMlDataSource.getPreProcess(image, facePred);
      final prePropTarget = await _authRemoteDataSource.getUserPreProcess(name);
      await _authMlDataSource.compareFace(prePropPred, prePropTarget);
      return Success(value: null);
    } catch (e, s) {
      return Failed.fromException(e, stacktrace: s);
    }
  }

  @override
  Future<Result<void>> deleteAuthFace(String name) async {
    try {
      await _authRemoteDataSource.deleteUser(name);
      return Success(value: null);
    } catch (e) {
      return Failed.fromException(e);
    }
  }

  @override
  Future<Result<List<String>>> getAuthNames() async {
    try {
      final data = await _authRemoteDataSource.getUsers();
      return Success(value: data);
    } catch (e) {
      return Failed.fromException(e);
    }
  }

  Future<InputImage> _cameraImageToInputImage(File image) async {
    final inputImage = InputImage.fromFile(image);
    return inputImage;
  }
}
