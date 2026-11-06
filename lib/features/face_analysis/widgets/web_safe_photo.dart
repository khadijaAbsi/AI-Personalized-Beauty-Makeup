import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';

/// Android/desktop keep Image.file; browser reads XFile bytes.
class WebSafePhoto extends StatefulWidget {
  const WebSafePhoto({
    super.key,
    required this.path,
    this.fit = BoxFit.contain,
  });
  final String path;
  final BoxFit fit;
  @override
  State<WebSafePhoto> createState() => _WebSafePhotoState();
}

class _WebSafePhotoState extends State<WebSafePhoto> {
  late Future<Uint8List> _bytes;
  @override
  void initState() {
    super.initState();
    _bytes = XFile(widget.path).readAsBytes();
  }

  @override
  void didUpdateWidget(covariant WebSafePhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _bytes = XFile(widget.path).readAsBytes();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return Image.file(
        File(widget.path),
        fit: widget.fit,
        gaplessPlayback: true,
      );
    }
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Icon(Icons.broken_image_outlined));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return Image.memory(
          snapshot.data!,
          fit: widget.fit,
          gaplessPlayback: true,
        );
      },
    );
  }
}
