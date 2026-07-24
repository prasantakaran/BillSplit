import 'dart:io';

import 'package:bill_split/features/scan/data/model/parse_bill_model.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_showcase_display_service.dart';
import '../../../../core/utils/showcase_keys.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_top_bar.dart';
import '../../../../shared/widgets/show_case_widget.dart';
import '../../../../shared/providers/bill_flow_state.dart';
import '../../data/services/ml_kit_ocr_service.dart';
import '../../domain/services/ocr_service.dart';
import '../../domain/usecases/scan_bill_use_case.dart';
import '../widgets/image_source_buttons.dart';
import '../widgets/scan_placeholder.dart';
import 'edit_items_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, this.initialImagePath, this.ocrService});

  final String? initialImagePath;

  /// Overridable in tests; defaults to the ML Kit implementation.
  final OcrService? ocrService;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  late final OcrService _ocrService;
  late final ScanBillUseCase _scanBillUseCase;

  /// Only the service this screen created is ours to close; an injected one
  /// belongs to the caller.
  late final bool _ownsOcrService;

  final ValueNotifier<String?> _imagePath = ValueNotifier<String?>(null);
  final ValueNotifier<bool> _isProcessing = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _ownsOcrService = widget.ocrService == null;
    _ocrService = widget.ocrService ?? MlKitOcrService();
    _scanBillUseCase = ScanBillUseCase(_ocrService);
    if (widget.initialImagePath != null) {
      _imagePath.value = widget.initialImagePath;
    } else {
      _recoverLostImage();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppShowcaseService.startIfUnseen(ShowcaseKeys.scanScreenId);
    });
  }

  Future<void> _recoverLostImage() async {
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (!mounted || response.isEmpty) {
        return;
      }

      final List<XFile>? files = response.files;
      if (files != null && files.isNotEmpty) {
        _imagePath.value = files.first.path;
        AppSnackbar.show(context, 'Camera image recovered.');
        return;
      }

      final Exception? exception = response.exception;
      if (exception != null) {
        AppSnackbar.showError(
          context,
          'Could not recover the camera image: $exception',
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          'Could not recover the camera image: $e',
        );
      }
    }
  }

  @override
  void dispose() {
    _imagePath.dispose();
    _isProcessing.dispose();
    if (_ownsOcrService) {
      _ocrService.dispose();
    }
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
      _showError(
        'Could not open '
        '${source == ImageSource.camera ? 'camera' : 'gallery'}: $e',
      );
    }
  }

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
      _showError('Could not crop the image: $e');
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
      _showError('Could not read the bill: $e');
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
    AppSnackbar.show(context, message);
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    AppSnackbar.showError(context, message);
  }

  Future<void> _addItemsManually() async {
    context.read<BillFlowState>().startNewBill();
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const EditItemsScreen()));
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
                description:
                    'Take a new photo or choose one from your '
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
                  description:
                      'Once you\'ve picked and cropped a photo, '
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
              const SizedBox(height: 10),
              AppShowcase(
                showcaseKey: ShowcaseKeys.scanManualButton,
                group: ShowcaseKeys.scanGroup,
                title: 'Add Items Manually',
                description:
                    'If the bill is hard to read, you can add '
                    'items manually instead.',
                icon: Icons.edit_note_outlined,
                child: OutlinedButton.icon(
                  onPressed: _addItemsManually,
                  icon: const Icon(Icons.edit_note_outlined),
                  label: const Text(
                    'Add items manually instead',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.brandNavy,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
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
