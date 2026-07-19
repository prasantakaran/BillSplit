import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/models/friend.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';

/// Dialog collecting a friend's details — for a new friend, or editing an
/// existing one when [initial] is passed.
///
/// Returns the created/edited [Friend] via [show], or null when cancelled.
/// Saving to Firestore is the caller's job — the dialog is UI only.
class AddFriendDialog extends StatefulWidget {
  const AddFriendDialog({super.key, this.initial});

  /// When set, the dialog edits this friend (fields prefilled, id kept).
  final Friend? initial;

  static Future<Friend?> show(BuildContext context, {Friend? initial}) {
    return showDialog<Friend>(
      context: context,
      builder: (_) => AddFriendDialog(initial: initial),
    );
  }

  @override
  State<AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends State<AddFriendDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController = TextEditingController(
    text: widget.initial?.name ?? '',
  );
  late final TextEditingController _upiController = TextEditingController(
    text: widget.initial?.upiId ?? '',
  );
  late final TextEditingController _phoneController = TextEditingController(
    text: widget.initial?.phone ?? '',
  );

  bool get _isEditing => widget.initial != null;

  @override
  void dispose() {
    _nameController.dispose();
    _upiController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final String upiId = _upiController.text.trim();
    final String phone = _phoneController.text.trim();
    Navigator.of(context).pop(
      Friend(
        id: widget.initial?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        upiId: upiId.isEmpty ? null : upiId,
        phone: phone.isEmpty ? null : phone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: AppColors.lightBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        insetPadding: EdgeInsets.symmetric(horizontal: 30),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isEditing ? 'Edit Friend' : 'Add Friend',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    controller: _nameController,
                    hint: 'Full name',
                    prefixIcon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    validator: Validators.fullName,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _upiController,
                    hint: 'UPI ID (optional)',
                    prefixIcon: Icons.currency_rupee,
                    textInputAction: TextInputAction.next,
                    validator: Validators.upiId,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _phoneController,
                    hint: 'Mobile number (optional)',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: Validators.optionalMobile,
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: _isEditing ? 'Save Changes' : 'Add Friend',
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.lightTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
