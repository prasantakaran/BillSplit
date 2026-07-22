import 'package:flutter/material.dart';

import '../../core/constants/app_images.dart';

/// Displays a BillSplit logo asset at a fixed square [size].
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.image = AppImagesConst.logo, this.size = 96});

  final String image;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(image, width: size, height: size, fit: BoxFit.contain);
  }
}
