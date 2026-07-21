import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_showcase_display_service.dart';
import '../../../../core/utils/showcase_keys.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_top_bar.dart';
import '../../../../shared/widgets/show_case_widget.dart';
import '../../../split/presentation/providers/bill_flow_state.dart';
import '../../data/services/ml_kit_ocr_service.dart';
import '../../domain/bill_parser.dart';
import '../../domain/services/ocr_service.dart';
import '../../domain/usecases/scan_bill_use_case.dart';
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
  final OcrService _ocrService = MlKitOcrService();
  late final ScanBillUseCase _scanBillUseCase = ScanBillUseCase(_ocrService);

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppShowcaseService.startIfUnseen(ShowcaseKeys.scanScreenId);
    });
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
      // Cropping is required: keeping only the items, tax and total section
      // removes background clutter and noticeably improves OCR accuracy.
      final String? cropped = await _cropImage(picked.path);
      if (cropped == null) {
        _showMessage(
          'Please crop the photo to the items, tax and total section '
          'of the bill to continue.',
        );
        return;
      }
      _imagePath.value = cropped;
    } on Exception catch (e) {
      _showMessage(
        'Could not open '
        '${source == ImageSource.camera ? 'camera' : 'gallery'}: $e',
      );
    }
  }

  /// Opens the crop UI for the picked photo. Returns null when the user
  /// backs out.
  Future<String?> _cropImage(String sourcePath) async {
    try {
      final CroppedFile? cropped = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop: Items + Tax + Total',
            toolbarColor: AppColors.brandBlue,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: AppColors.brandBlue,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Crop: Items + Tax + Total'),
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
      final ParsedBill parsed = await _scanBillUseCase(path);

      if (!mounted) {
        return;
      }
      context.read<BillFlowState>().startNewBill(
        items: parsed.items,
        taxAmount: parsed.taxAmount,
        taxLines: parsed.taxLines,
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
      appBar: const AppTopBar(title: 'Scan Bill'),
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
              AppShowcase(
                showcaseKey: ShowcaseKeys.scanSourceButtons,
                group: ShowcaseKeys.scanGroup,
                title: 'Pick a Photo',
                description: 'Take a new photo or choose one from your '
                    'gallery to get started.',
                icon: Icons.add_a_photo_outlined,
                child: ImageSourceButtons(
                  onCamera: () => _pickImage(ImageSource.camera),
                  onGallery: () => _pickImage(ImageSource.gallery),
                ),
              ),
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: Listenable.merge([_imagePath, _isProcessing]),
                builder: (context, _) => AppShowcase(
                  showcaseKey: ShowcaseKeys.scanDetectButton,
                  group: ShowcaseKeys.scanGroup,
                  title: 'Detect Items',
                  description: 'Once you\'ve picked and cropped a photo, '
                      'tap here to read the items automatically.',
                  icon: Icons.document_scanner_outlined,
                  child: AppButton(
                    label: 'Detect Items',
                    icon: Icons.document_scanner_outlined,
                    isLoading: _isProcessing.value,
                    onPressed: _imagePath.value == null ? null : _detectItems,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
