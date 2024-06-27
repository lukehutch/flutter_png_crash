import 'dart:io';
import 'dart:ui' as ui;

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import './photo_cropper_widget.dart';

void main() {
  runApp(
    MaterialApp(
      home: const MyApp(),
      navigatorKey: navigatorKey,
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text('Show'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showImage,
        child: const Icon(Icons.image),
      ),
    );
  }

  Future<ui.Image> loadImageFromAsset(String assetName) async {
    var buffer = await ImmutableBuffer.fromAsset(assetName);
    var codec = await ui.instantiateImageCodecFromBuffer(buffer);
    var frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<void> _showImage() async {
    final ByteData bytes =
        await rootBundle.load('assets/pexels-olly-842811.jpg');
    final Uint8List photoBytes = bytes.buffer.asUint8List();

    showPhotoCropper(
      rawImageBytes: photoBytes,
      onCropped: (croppedImage) async {
        final imageTempPngFile = await writeImageToTempPngFile(croppedImage);
        print('Succeeded');
      },
    );
  }

  Future<XFile?> downloadUrlToFile(String url) async {
    return XFile((await DefaultCacheManager().getSingleFile(url)).path);
  }

  Future<File> writeImageToTempPngFile(ui.Image image) async {
    final Directory tempDir = await getTemporaryDirectory();
    final bytes =
        await image.toByteData(format: ui.ImageByteFormat.png); // CRASHES HERE
    if (bytes == null) {
      throw 'Could not convert image format';
    }
    final tempFile = File('${tempDir.path}/abc.png');
    await tempFile.writeAsBytes(bytes.buffer.asUint8List());
    return tempFile;
  }
}
