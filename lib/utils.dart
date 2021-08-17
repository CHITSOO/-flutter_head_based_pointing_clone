import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/foundation.dart';

typedef HandleDetection = Future<List<Face>> Function(InputImage image);

Future<CameraDescription> getCamera(CameraLensDirection dir) async {
  return await availableCameras().then(
    (List<CameraDescription> cameras) => cameras.firstWhere(
      (CameraDescription camera) => camera.lensDirection == dir,
    ),
  );
}

Uint8List concatenatePlanes(List<Plane> planes) {
  final WriteBuffer allBytes = WriteBuffer();
  planes.forEach((Plane plane) => allBytes.putUint8List(plane.bytes));
  return allBytes.done().buffer.asUint8List();
}

InputImageData buildMetaData(
  CameraImage image,
  InputImageRotation rotation,
) {
  return InputImageData(
    inputImageFormat: image.format.raw,
    size: Size(image.width.toDouble(), image.height.toDouble()),
    imageRotation: rotation,
    planeData: image.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList(),
  );
}

Future<List<Face>> detect(
  CameraImage image,
  HandleDetection handleDetection,
  InputImageRotation rotation,
) async {
  return handleDetection(
    InputImage.fromBytes(
        bytes: concatenatePlanes(image.planes),
        inputImageData: buildMetaData(image, rotation)),
  );
}

InputImageRotation rotationIntToImageRotation(int rotation) {
  switch (rotation) {
    case 0:
      return InputImageRotation.Rotation_0deg;
    case 90:
      return InputImageRotation.Rotation_90deg;
    case 180:
      return InputImageRotation.Rotation_180deg;
    default:
      assert(rotation == 270);
      return InputImageRotation.Rotation_270deg;
  }
}

double flipXBasedOnCam(
  double x,
  CameraLensDirection direction,
  double width,
) {
  if (direction == CameraLensDirection.back) {
    return x;
  } else {
    return width - x;
  }
}

Offset flipOffsetBasedOnCam(
  Offset point,
  CameraLensDirection direction,
  double width,
) {
  double dx = flipXBasedOnCam(point.dx, direction, width);
  return Offset(dx, point.dy);
}

Rect flipRectBasedOnCam(
  Rect rect,
  CameraLensDirection direction,
  double width,
) {
  if (direction == CameraLensDirection.back) {
    return rect;
  } else {
    double left = width - rect.right;
    double right = width - rect.left;
    return Rect.fromLTRB(left, rect.top, right, rect.bottom);
  }
}
