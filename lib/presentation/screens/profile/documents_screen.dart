import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/rider_model.dart';
import '../../../data/repositories/document_repository.dart';
import '../../bloc/auth/auth_cubit.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _documentRepo = DocumentRepository();
  final _picker = ImagePicker();
  String? _uploadingType;

  static const _requiredDocs = [
    {'type': 'id_card', 'label': 'Government ID', 'icon': Icons.badge_outlined, 'desc': 'National ID card, passport, or voter\'s card'},
    {'type': 'drivers_license', 'label': "Driver's License", 'icon': Icons.card_membership_outlined, 'desc': 'Valid driver\'s license'},
    {'type': 'vehicle_registration', 'label': 'Vehicle Registration', 'icon': Icons.directions_car_outlined, 'desc': 'Vehicle registration document or proof of ownership'},
  ];

  Future<void> _pickAndUpload(String type) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;

    final rider = context.read<AuthCubit>().riderProfile;
    if (rider == null) return;

    setState(() => _uploadingType = type);

    try {
      await _documentRepo.uploadDocument(
        riderId: rider.uid,
        type: type,
        imageFile: File(picked.path),
      );
      if (mounted) {
        await context.read<AuthCubit>().refreshProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Document uploaded successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingType = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Document Verification'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final rider = state is AuthAuthenticated ? state.rider : null;
          if (rider == null) return const SizedBox.shrink();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusBanner(rider),
                const SizedBox(height: 20),
                Text('Required Documents', style: AppTextStyles.h3),
                const SizedBox(height: 4),
                Text(
                  'Upload all 3 documents to begin your verification.',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 16),
                ..._requiredDocs.map((docInfo) {
                  final type = docInfo['type'] as String;
                  final existingDoc = rider.getDocument(type);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildDocumentCard(
                      type: type,
                      label: docInfo['label'] as String,
                      icon: docInfo['icon'] as IconData,
                      description: docInfo['desc'] as String,
                      document: existingDoc,
                      isUploading: _uploadingType == type,
                    ),
                  );
                }),
                const SizedBox(height: 16),
                _buildInfoSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBanner(RiderModel rider) {
    Color bgColor;
    Color borderColor;
    Color iconColor;
    IconData icon;
    String title;
    String subtitle;

    if (rider.isVerified) {
      bgColor = AppColors.successLight;
      borderColor = AppColors.success;
      iconColor = AppColors.success;
      icon = Icons.verified_outlined;
      title = 'Verified';
      subtitle = 'Your documents have been approved. You can accept deliveries.';
    } else if (rider.isVerificationPending) {
      bgColor = AppColors.warningLight;
      borderColor = AppColors.warning;
      iconColor = AppColors.warning;
      icon = Icons.hourglass_top_rounded;
      title = 'Verification Pending';
      subtitle = 'Your documents are being reviewed. This usually takes 24-48 hours.';
    } else if (rider.isRejected) {
      bgColor = AppColors.errorLight;
      borderColor = AppColors.error;
      iconColor = AppColors.error;
      icon = Icons.error_outline;
      title = 'Verification Rejected';
      subtitle = 'Some documents were rejected. Please re-upload them.';
    } else {
      bgColor = AppColors.infoLight;
      borderColor = AppColors.info;
      iconColor = AppColors.info;
      icon = Icons.info_outline;
      title = 'Not Verified';
      subtitle = 'Upload all required documents to start the verification process.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelMedium.copyWith(color: iconColor)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.caption.copyWith(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard({
    required String type,
    required String label,
    required IconData icon,
    required String description,
    required RiderDocument? document,
    required bool isUploading,
  }) {
    final hasDoc = document != null;
    final isApproved = document?.isApproved ?? false;
    final isRejected = document?.isRejected ?? false;
    final isPending = document?.isPending ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isApproved
              ? AppColors.success
              : isRejected
                  ? AppColors.error
                  : isPending
                      ? AppColors.warning
                      : AppColors.border,
          width: hasDoc ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isApproved
                      ? AppColors.successLight
                      : isRejected
                          ? AppColors.errorLight
                          : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22, color: isApproved ? AppColors.success : AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.labelMedium),
                    const SizedBox(height: 2),
                    Text(description, style: AppTextStyles.caption.copyWith(fontSize: 11)),
                  ],
                ),
              ),
              if (document != null) _buildStatusChip(document),
            ],
          ),
          if (isRejected && document!.rejectionReason != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      document.rejectionReason!,
                      style: AppTextStyles.caption.copyWith(color: AppColors.error, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (isUploading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            )
          else if (!hasDoc || isRejected)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _pickAndUpload(type),
                icon: Icon(hasDoc ? Icons.refresh : Icons.upload_outlined, size: 18),
                label: Text(hasDoc ? 'Re-upload' : 'Upload Document'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            )
          else if (isPending)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _pickAndUpload(type),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Replace'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(RiderDocument document) {
    Color color;
    String text;
    IconData icon;

    if (document.isApproved) {
      color = AppColors.success;
      text = 'Approved';
      icon = Icons.check_circle_outline;
    } else if (document.isRejected) {
      color = AppColors.error;
      text = 'Rejected';
      icon = Icons.cancel_outlined;
    } else {
      color = AppColors.warning;
      text = 'Pending';
      icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: AppTextStyles.caption.copyWith(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text('How it works', style: AppTextStyles.labelMedium),
            ],
          ),
          const SizedBox(height: 12),
          _buildStep('1', 'Upload all 3 required documents'),
          const SizedBox(height: 8),
          _buildStep('2', 'Our team reviews your documents (24-48 hrs)'),
          const SizedBox(height: 8),
          _buildStep('3', 'Once approved, you can go online and accept deliveries'),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(number, style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
      ],
    );
  }
}
