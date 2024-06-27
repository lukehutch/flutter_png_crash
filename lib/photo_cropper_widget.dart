import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_crop/image_crop.dart';

const maxRawImageWidth = 3240;
const maxRawImageHeight = 3240;

void showPhotoCropper({
  required Uint8List rawImageBytes,
  required FutureOr<void> Function(ui.Image cropResult) onCropped,
}) {
  showFullScreenModal(
    showStackedBackButton: true,
    backButtonColor: Colors.black,
    child: PhotoCropperWidget(
      rawImageBytes: rawImageBytes,
      onCropped: (cropResult) async {
        // Call onCropped handler
        await onCropped(cropResult);
      },
      onError: (e) {
        print(e);
      },
    ),
  ).ignore();
}

class PhotoCropperWidget extends StatefulWidget {
  final Uint8List rawImageBytes;
  final FutureOr<void> Function(ui.Image cropResult) onCropped;
  final void Function(Object error) onError;

  const PhotoCropperWidget({
    super.key,
    required this.rawImageBytes,
    required this.onCropped,
    required this.onError,
  });

  @override
  State<PhotoCropperWidget> createState() => _PhotoCropperWidgetState();
}

class _PhotoCropperWidgetState extends State<PhotoCropperWidget> {
  CropController? cropController;
  NavigatorState? navigator;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (cropController == null) {
      final devicePixelRatio = View.of(context).devicePixelRatio;
      cropController = CropController(
        // Load, decompress, and scale down the input image if necessary
        // to a max size, in case a really large image is provided.
        imageProvider: ResizeImage(
          MemoryImage(widget.rawImageBytes),
          width: maxRawImageWidth,
          height: maxRawImageHeight,
          allowUpscaling: false,
          policy: ResizeImagePolicy.fit,
        ),
        target: TargetSize(
          (1080 / devicePixelRatio).round(),
          (1920 / devicePixelRatio).round(),
        ),
        maximumScale: 2.5,
        onDone: widget.onCropped,
        onError: widget.onError,
      );
    }
  }

  @override
  void dispose() {
    cropController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ImageCropper(
      cropController!,
      devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
    );
  }
}

/// Full-screen modal
Future<T?> showFullScreenModal<T>({
  required Widget child,
  bool translucent = false,
  bool showStackedBackButton = false,
  double? backButtonSize,
  Color? backButtonColor,
  Color? backButtonBackgroundColor,
  EdgeInsetsGeometry? backButtonPadding,
}) async {
  final content = Container(color: Colors.white, child: child);
  return navigator.push<T>(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (BuildContext pageContext, _, __) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: content,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 500),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.ease));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    ),
  );
}

/// Used for obtaining a global [NavigatorState].
final navigatorKey = GlobalKey<NavigatorState>();

/// Get the global [NavigatorState] (for opening modals).
NavigatorState get navigator {
  final navigatorState = navigatorKey.currentState;
  if (navigatorState == null) {
    // Should not happen as long as there is a Navigator in the router
    throw 'navigatorKey.currentState is null';
  }
  return navigatorState;
}

/// Pop the current route if possible.
bool navigatorPop<T>([T? result]) {
  if (navigatorKey.currentState?.canPop() ?? false) {
    navigatorKey.currentState?.pop(result);
    return true;
  }
  return false;
}
