import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../bloc/auth/auth_cubit.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final rider = state is AuthAuthenticated ? state.rider : null;
          if (rider == null) return const SizedBox.shrink();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primarySurface,
                        child: Text(
                          rider.name.isNotEmpty ? rider.name[0].toUpperCase() : 'R',
                          style: AppTextStyles.h1.copyWith(color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(rider.name, style: AppTextStyles.h3),
                      const SizedBox(height: 4),
                      Text(rider.email, style: AppTextStyles.bodySmall),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStat('Deliveries', '${rider.completedDeliveries}'),
                          Container(width: 1, height: 32, color: AppColors.divider),
                          _buildStat('Rating', rider.rating > 0 ? rider.rating.toStringAsFixed(1) : 'N/A'),
                          Container(width: 1, height: 32, color: AppColors.divider),
                          _buildStat('Vehicle', _formatVehicle(rider.vehicleType)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Info section
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      _buildInfoTile(Icons.phone_outlined, 'Phone', rider.phone),
                      const Divider(height: 0),
                      _buildInfoTile(Icons.location_on_outlined, 'Address', rider.address),
                      const Divider(height: 0),
                      _buildInfoTile(Icons.two_wheeler_outlined, 'Vehicle', _formatVehicle(rider.vehicleType)),
                      const Divider(height: 0),
                      _buildInfoTile(Icons.badge_outlined, 'Plate Number', rider.plateNumber),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Actions
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      _buildActionTile(
                        Icons.edit_outlined,
                        'Edit Profile',
                        () => _showEditDialog(context),
                      ),
                      const Divider(height: 0),
                      _buildActionTile(
                        Icons.help_outline,
                        'Help & Support',
                        () {},
                      ),
                      const Divider(height: 0),
                      _buildActionTile(
                        Icons.info_outline,
                        'About',
                        () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Sign out
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.read<AuthCubit>().signOut();
                      context.go('/login');
                    },
                    icon: const Icon(Icons.logout, color: AppColors.error),
                    label: Text(
                      'Sign Out',
                      style: AppTextStyles.labelMedium.copyWith(color: AppColors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size(double.infinity, 52),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.labelLarge),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(label, style: AppTextStyles.caption),
      subtitle: Text(
        value.isNotEmpty ? value : 'Not set',
        style: AppTextStyles.bodyMedium,
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(label, style: AppTextStyles.bodyMedium),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: onTap,
    );
  }

  String _formatVehicle(String type) {
    switch (type) {
      case 'motorcycle':
        return 'Motorcycle';
      case 'bicycle':
        return 'Bicycle';
      case 'car':
        return 'Car';
      default:
        return type;
    }
  }

  void _showEditDialog(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    final rider = authCubit.riderProfile;
    if (rider == null) return;

    final nameController = TextEditingController(text: rider.name);
    final phoneController = TextEditingController(text: rider.phone);
    final addressController = TextEditingController(text: rider.address);
    final plateController = TextEditingController(text: rider.plateNumber);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit Profile', style: AppTextStyles.h3),
                const SizedBox(height: 20),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: plateController,
                  decoration: const InputDecoration(labelText: 'Plate Number'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    authCubit.updateProfile(
                      name: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                      address: addressController.text.trim(),
                      plateNumber: plateController.text.trim(),
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
