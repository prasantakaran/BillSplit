import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../split/presentation/providers/bill_flow_state.dart';
import '../../data/services/ocr_service.dart';
import '../../domain/bill_parser.dart';
import '../widgets/image_source_buttons.dart';
import '../widgets/scan_placeholder.dart';
import 'edit_items_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, this.initialImagePath});

  /// Bill photo recovered after Android killed the app while the camera
  /// was open; shown immediately instead of the empty picker state.
  final String? initialImagePath;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();

  final ValueNotifier<String?> _imagePath = ValueNotifier<String?>(null);
  final ValueNotifier<bool> _isProcessing = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    if (widget.initialImagePath != null) {
      _imagePath.value = widget.initialImagePath;
    } else {
      _recoverLostImage();
    }
  }

  /// Android may destroy the Flutter activity while the system camera is open.
  /// image_picker stores that pending result so it can be recovered when this
  /// screen is created again.
  Future<void> _recoverLostImage() async {
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (!mounted || response.isEmpty) {
        return;
      }

      final List<XFile>? files = response.files;
      if (files != null && files.isNotEmpty) {
        _imagePath.value = files.first.path;
        _showMessage('Camera image recovered.');
        return;
      }

      final Exception? exception = response.exception;
      if (exception != null) {
        _showMessage('Could not recover the camera image: $exception');
      }
    } on Exception catch (e) {
      if (mounted) {
        _showMessage('Could not recover the camera image: $e');
      }
    }
  }

  @override
  void dispose() {
    _imagePath.dispose();
    _isProcessing.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 2000,
        imageQuality: 90,
      );
      if (picked == null) {
        return;
      }
      // Cropping to just the bill removes background clutter, which
      // noticeably improves OCR accuracy.
      _imagePath.value = await _cropImage(picked.path) ?? picked.path;
    } on Exception catch (e) {
      _showMessage(
        'Could not open '
        '${source == ImageSource.camera ? 'camera' : 'gallery'}: $e',
      );
    }
  }

  /// Opens the crop UI for the picked photo. Returns null when the user
  /// backs out, in which case the uncropped photo is used as-is.
  Future<String?> _cropImage(String sourcePath) async {
    try {
      final CroppedFile? cropped = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Bill',
            toolbarColor: AppColors.brandBlue,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: AppColors.brandBlue,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Crop Bill'),
        ],
      );
      return cropped?.path;
    } on Exception catch (e) {
      _showMessage('Could not crop the image: $e');
      return null;
    }
  }

  /// Re-opens the crop UI for the currently selected photo.
  Future<void> _cropCurrentImage() async {
    final String? path = _imagePath.value;
    if (path == null) {
      return;
    }
    final String? cropped = await _cropImage(path);
    if (cropped != null) {
      _imagePath.value = cropped;
    }
  }

  Future<void> _detectItems() async {
    final String? path = _imagePath.value;
    if (path == null) {
      return;
    }
    _isProcessing.value = true;
    try {
      final String rawText = await _ocrService.extractText(path);
      final ParsedBill parsed = BillParser.parse(rawText);

      if (!mounted) {
        return;
      }
      context.read<BillFlowState>().startNewBill(
        items: parsed.items,
        taxAmount: parsed.taxAmount,
        detectedTotal: parsed.detectedTotal,
        detectedSubtotal: parsed.detectedSubtotal,
      );
      if (parsed.items.isEmpty) {
        _showMessage(
          'No items detected — you can add them manually on the next screen.',
        );
      }
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const EditItemsScreen()));
    } on Exception catch (e) {
      _showMessage('Could not read the bill: $e');
    } finally {
      if (mounted) {
        _isProcessing.value = false;
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(title: const Text('Scan Bill')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ValueListenableBuilder<String?>(
                  valueListenable: _imagePath,
                  builder: (context, path, _) {
                    if (path == null) {
                      return const ScanPlaceholder();
                    }
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(File(path), fit: BoxFit.contain),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Material(
                            color: AppColors.brandNavy.withValues(alpha: 0.6),
                            shape: const CircleBorder(),
                            child: IconButton(
                              tooltip: 'Crop image',
                              icon: const Icon(Icons.crop, color: Colors.white),
                              onPressed: _cropCurrentImage,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              ImageSourceButtons(
                onCamera: () => _pickImage(ImageSource.camera),
                onGallery: () => _pickImage(ImageSource.gallery),
              ),
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: Listenable.merge([_imagePath, _isProcessing]),
                builder: (context, _) => AppButton(
                  label: 'Detect Items',
                  icon: Icons.document_scanner_outlined,
                  isLoading: _isProcessing.value,
                  onPressed: _imagePath.value == null ? null : _detectItems,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
