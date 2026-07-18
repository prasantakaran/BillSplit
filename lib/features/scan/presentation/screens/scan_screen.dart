import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../split/presentation/providers/bill_flow_state.dart';
import '../../data/services/ocr_service.dart';
import '../../domain/bill_parser.dart';
import 'edit_items_screen.dart';

/// Entry point of the bill flow: photograph or pick a bill image, run
/// on-device OCR, parse it into items, and continue to the edit screen.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();

  final ValueNotifier<String?> _imagePath = ValueNotifier<String?>(null);
  final ValueNotifier<bool> _isProcessing = ValueNotifier<bool>(false);

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
      if (picked != null) {
        _imagePath.value = picked.path;
      }
    } on Exception catch (e) {
      _showMessage('Could not open ${source == ImageSource.camera ? 'camera' : 'gallery'}: $e');
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
          );
      if (parsed.items.isEmpty) {
        _showMessage(
          'No items detected — you can add them manually on the next screen.',
        );
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const EditItemsScreen()),
      );
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
                      return const _ScanPlaceholder();
                    }
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(File(path), fit: BoxFit.contain),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Camera'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
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

class _ScanPlaceholder extends StatelessWidget {
  const _ScanPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 72,
              color: AppColors.brandBlue.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            const Text(
              'Snap or pick a photo of the bill',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Keep the bill flat and well lit for the best results.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.lightTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
