import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../bloc/auth/auth_cubit.dart';

class RiderSetupScreen extends StatefulWidget {
  const RiderSetupScreen({super.key});

  @override
  State<RiderSetupScreen> createState() => _RiderSetupScreenState();
}

class _RiderSetupScreenState extends State<RiderSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _plateController = TextEditingController();
  String _vehicleType = 'motorcycle';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().completeProfile(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          vehicleType: _vehicleType,
          plateNumber: _plateController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/home');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.secondarySurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.two_wheeler_rounded,
                      color: AppColors.secondaryDark,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Complete Your Profile', style: AppTextStyles.h2),
                  const SizedBox(height: 8),
                  Text(
                    'Tell us about yourself so you can start accepting deliveries.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildLabel('Full Name'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    style: AppTextStyles.bodyLarge,
                    decoration: const InputDecoration(
                      hintText: 'Your full name',
                      prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondary, size: 22),
                    ),
                    validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Phone Number'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: AppTextStyles.bodyLarge,
                    decoration: const InputDecoration(
                      hintText: '+234 800 000 0000',
                      prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textSecondary, size: 22),
                    ),
                    validator: (v) => (v == null || v.trim().length < 10) ? 'Enter a valid phone number' : null,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Address'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _addressController,
                    textCapitalization: TextCapitalization.words,
                    style: AppTextStyles.bodyLarge,
                    decoration: const InputDecoration(
                      hintText: 'Your area or address',
                      prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.textSecondary, size: 22),
                    ),
                    validator: (v) => (v == null || v.trim().length < 3) ? 'Enter your address' : null,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Vehicle Type'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.inputBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.inputBorder),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _vehicleType,
                        isExpanded: true,
                        style: AppTextStyles.bodyLarge,
                        items: const [
                          DropdownMenuItem(value: 'motorcycle', child: Text('Motorcycle')),
                          DropdownMenuItem(value: 'bicycle', child: Text('Bicycle')),
                          DropdownMenuItem(value: 'car', child: Text('Car')),
                        ],
                        onChanged: (v) => setState(() => _vehicleType = v ?? 'motorcycle'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Plate Number'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _plateController,
                    textCapitalization: TextCapitalization.characters,
                    style: AppTextStyles.bodyLarge,
                    decoration: const InputDecoration(
                      hintText: 'e.g. ABC-123-XY',
                      prefixIcon: Icon(Icons.badge_outlined, color: AppColors.textSecondary, size: 22),
                    ),
                    validator: (v) => (v == null || v.trim().length < 3) ? 'Enter plate number' : null,
                  ),
                  const SizedBox(height: 32),

                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.white,
                                ),
                              )
                            : const Text('Complete Setup'),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.labelSmall.copyWith(
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}
