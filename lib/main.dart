import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:face_recognition_app/core/base/result.dart';
import 'package:face_recognition_app/data/auth_repository.dart';
import 'package:face_recognition_app/data/data_source/auth_ml_data_source.dart';
import 'package:face_recognition_app/data/data_source/auth_remote_data_source.dart';
import 'package:face_recognition_app/domain/data/auth_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

late final AuthRepository _authRepository;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  _authRepository = AuthRepositoryImpl(
    AuthRemoteDataSourceImpl(FirebaseFirestore.instance),
    AuthMlDataSourceImpl(
        FaceDetector(options: FaceDetectorOptions(enableLandmarks: true)),
        await Interpreter.fromAsset('assets/models/mobilefacenet.tflite')),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Recognitian App',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Face Recognitian App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final CameraController _cameraController;
  final _cameraCompleter = Completer<void>();
  String? _userSelected;
  final _users = <String>[];

  @override
  void initState() {
    _setUpCamera();
    _getUsers();
    super.initState();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _userSelected,
            items: _users
                .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) {},
          ),
          Expanded(
            child: FutureBuilder(
              future: _cameraCompleter.future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox();
                }
                return CameraPreview(
                  _cameraController,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: _onDeleteUser,
                          iconSize: 64,
                          color: Colors.white,
                          icon: const Icon(Icons.delete),
                        ),
                        IconButton(
                          onPressed: _onAuth,
                          iconSize: 64,
                          color: Colors.white,
                          icon: const Icon(Icons.camera),
                        ),
                        IconButton(
                          onPressed: _onAddUser,
                          iconSize: 64,
                          color: Colors.white,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setUpCamera() async {
    final avCams = await availableCameras();
    _cameraController = CameraController(avCams.last, ResolutionPreset.max);
    await _cameraController.initialize();
    _cameraCompleter.complete();
  }

  Future<void> _getUsers() async {
    final res = await _authRepository.getAuthNames();
    switch (res) {
      case Success(value: final value):
        setState(() {
          _users
            ..clear()
            ..addAll(value);
          _userSelected = _users.first;
        });
        break;
      case Failed(message: final message):
        if (!context.mounted) return;
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message),
        ));
        break;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  Future<void> _onAuth() async {
    if (_userSelected == null) {
      _showError('User tidak boleh kosong');
      return;
    }
    final pictRes = await _cameraController.takePicture();
    if (!context.mounted) return;
    final res =
        await _authRepository.authFace(_userSelected!, File(pictRes.path));
    if (!context.mounted) return;
    switch (res) {
      case Success _:
        showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Hi, ${_userSelected ?? '-'}!'),
              content: Image.file(File(pictRes.path)),
            );
          },
        );
        break;
      case Failed(message: final message):
        _showError(message);
        break;
    }
  }

  void _onDeleteUser() {
    if (_userSelected == null) {
      _showError('User tidak boleh kosong');
      return;
    }
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Hapus User'),
            content: Text(
                'Apakah anda yakin ingin menghapus user ${_userSelected ?? '-'}?'),
            actions: [
              // ignore: use_build_context_synchronously
              ElevatedButton(
                child: const Text('Hapus'),
                onPressed: () async {
                  final res =
                      await _authRepository.deleteAuthFace(_userSelected!);
                  if (!context.mounted) return;
                  switch (res) {
                    case Success _:
                      _getUsers();
                      Navigator.pop(context);
                      break;
                    case Failed(message: final message):
                      _showError(message);
                      break;
                  }
                },
              ),
              OutlinedButton(
                child: const Text('Batal'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
  }

  Future<void> _onAddUser() async {
    final pictRes = await _cameraController.takePicture();
    if (!context.mounted) return;
    final res =
        await _authRepository.authFace(_userSelected!, File(pictRes.path));
    if (!context.mounted) return;
    switch (res) {
      case Success _:
        showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (context) {
            String? addedUser;
            return AlertDialog(
              title: Text('Hi, ${_userSelected ?? '-'}!'),
              content: Column(
                children: [
                  Image.file(File(pictRes.path)),
                  TextField(
                    onChanged: (value) {
                      addedUser = value;
                    },
                    decoration: const InputDecoration(
                      labelText: 'User Baru',
                    ),
                  ),
                ],
              ),
              actions: [
                // ignore: use_build_context_synchronously
                ElevatedButton(
                  child: const Text('Tambah'),
                  onPressed: () async {
                    if (addedUser == null) {
                      _showError('User baru tidak boleh kosong');
                      return;
                    }
                    final res = await _authRepository.addAuthFace(
                        addedUser!, File(pictRes.path));
                    if (!context.mounted) return;
                    switch (res) {
                      case Success _:
                        _getUsers();
                        Navigator.pop(context);
                        break;
                      case Failed(message: final message):
                        _showError(message);
                        break;
                    }
                  },
                ),
                OutlinedButton(
                  child: const Text('Batal'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
        break;
      case Failed(message: final message):
        _showError(message);
        break;
    }
  }
}
