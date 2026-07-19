import 'package:flutter/material.dart';

class ImageSourceButtons extends StatelessWidget {
  const ImageSourceButtons({
    super.key,
    required this.onCamera,
    required this.onGallery,
  });

  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _sourceButton(
            icon: Icons.photo_camera_outlined,
            label: 'Camera',
            onPressed: onCamera,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _sourceButton(
            icon: Icons.photo_library_outlined,
            label: 'Gallery',
            onPressed: onGallery,
          ),
        ),
      ],
    );
  }

  Widget _sourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
