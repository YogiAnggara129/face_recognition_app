import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:face_recognition_app/core/base/exception.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

abstract class AuthRemoteDataSource {
  Future<void> addUser(String name, Face face, List preProcess);
  Future<void> deleteUser(String name);
  Future<List<String>> getUsers();
  Future<Face> getUserFace(String name);
  Future<List> getUserPreProcess(String name);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl(this._firestore);

  @override
  Future<Face> getUserFace(String name) async {
    try {
      final CollectionReference users = _firestore.collection('users');
      final data = await users.doc(name).get();
      return Face.fromJson((data.data()! as Map)['face']);
    } catch (e) {
      throw const DatabaseException('Gagal dapatkan user');
    }
  }

  @override
  Future<List> getUserPreProcess(String name) async {
    try {
      final CollectionReference users = _firestore.collection('users');
      // final snapshot = await users.get();
      final data = await users.doc(name).get();
      return (data.data()! as Map)['pre_process'] as List;
    } catch (e) {
      throw const DatabaseException('Gagal dapatkan user');
    }
  }

  @override
  Future<List<String>> getUsers() async {
    try {
      final CollectionReference users = _firestore.collection('users');
      final snapshot = await users.get();
      return snapshot.docs
          .map((e) => (e.data() as Map?)?['name'] as String)
          .toList();
    } catch (e) {
      throw const DatabaseException('Gagal simpan user');
    }
  }

  @override
  Future<void> addUser(String name, Face face, List preProcess) async {
    try {
      final CollectionReference users = _firestore.collection('users');
      await users.doc(name).set({
        'name': name,
        'face': _faceToJson(face),
        'pre_process': preProcess,
      });
    } catch (e) {
      throw const DatabaseException('Gagal simpan user');
    }
  }

  @override
  Future<void> deleteUser(String name) async {
    try {
      final CollectionReference users = _firestore.collection('users');
      await users.doc(name).delete();
    } catch (e) {
      throw const DatabaseException('Gagal simpan user');
    }
  }

  Map<String, dynamic> _faceToJson(Face face) {
    return {
      'rect': {
        'left': face.boundingBox.left,
        'top': face.boundingBox.top,
        'right': face.boundingBox.right,
        'bottom': face.boundingBox.bottom,
      },
      'headEulerAngleX': face.headEulerAngleX,
      'headEulerAngleY': face.headEulerAngleY,
      'headEulerAngleZ': face.headEulerAngleZ,
      'leftEyeOpenProbability': face.leftEyeOpenProbability,
      'rightEyeOpenProbability': face.rightEyeOpenProbability,
      'smilingProbability': face.smilingProbability,
      'trackingId': face.trackingId,
      'landmarks': Map<String, dynamic>.fromEntries(
        face.landmarks.entries.map((entry) {
          return MapEntry(
            entry.key.name, // menggunakan nama enum untuk key
            entry.value != null
                ? [entry.value!.position.x, entry.value!.position.y]
                : null, // jika null, return null
          );
        }),
      ),
      'contours': Map<String, dynamic>.fromEntries(
        face.contours.entries.map((entry) {
          return MapEntry(
            entry.key.name, // menggunakan nama enum untuk key
            entry.value?.points
                .map((point) => [point.x, point.y])
                .toList(), // jika null, return null
          );
        }),
      ),
    };
  }
}
