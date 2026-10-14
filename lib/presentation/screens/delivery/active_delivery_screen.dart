import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/orders/orders_cubit.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  final String orderId;
  const ActiveDeliveryScreen({super.key, required this.orderId});

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  final _orderRepo = OrderRepository();
  bool _isCompleting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Active Delivery'),
        leading: IconButton(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: StreamBuilder<OrderModel?>(
        stream: _orderRepo.watchOrder(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final order = snapshot.data;
          if (order == null) {
            return Center(
              child: Text('Order not found', style: AppTextStyles.bodyLarge),
            );
          }
          if (order.status == 'delivered') {
            return _buildDeliveredView(order);
          }
          return _buildDeliveryView(order);
        },
      ),
    );
  }

  Widget _buildDeliveryView(OrderModel order) {
    final riderEarning = order.serviceFee > 0 ? order.serviceFee : order.deliveryFee;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          _buildProgressSection(order),
          const SizedBox(height: 24),

          // Pickup info
          _buildLocationCard(
            icon: Icons.store_outlined,
            iconColor: AppColors.primary,
            title: 'Pickup from',
            subtitle: order.vendorName,
            trailing: null,
          ),
          const SizedBox(height: 12),

          // Delivery info
          _buildLocationCard(
            icon: Icons.location_on_outlined,
            iconColor: AppColors.error,
            title: 'Deliver to',
            subtitle: order.deliveryAddress,
            trailing: null,
          ),
          const SizedBox(height: 24),

          // Order summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order Summary', style: AppTextStyles.labelSmall),
                const SizedBox(height: 12),
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text('${item.quantity}x ', style: AppTextStyles.caption),
                          Expanded(child: Text(item.name, style: AppTextStyles.bodySmall)),
                        ],
                      ),
                    )),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Your Earnings', style: AppTextStyles.labelMedium),
                    Text(
                      NumberFormat.currency(symbol: '\u20A6', decimalDigits: 0)
                          .format(riderEarning),
                      style: AppTextStyles.labelMedium.copyWith(color: AppColors.success),
                    ),
                  ],
                ),
                if (order.serviceFee > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'From service fee',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Delivery PIN info
          if (order.deliveryPin != null && order.deliveryPin!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pin_outlined, size: 22, color: AppColors.info),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery PIN Required',
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.info),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ask the customer for their 4-digit delivery PIN to confirm delivery.',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          if (order.notes != null && order.notes!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note_outlined, size: 20, color: AppColors.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Customer Note', style: AppTextStyles.labelSmall.copyWith(color: AppColors.warning)),
                        const SizedBox(height: 4),
                        Text(order.notes!, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Complete delivery button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCompleting ? null : () => _onCompletePressed(order),
              icon: _isCompleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                    )
                  : const Icon(Icons.check_circle_rounded),
              label: Text(_isCompleting ? 'Completing...' : 'Mark as Delivered'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                minimumSize: const Size(double.infinity, 56),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Call customer button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _callCustomer(),
              icon: const Icon(Icons.phone_outlined),
              label: const Text('Call Customer'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onCompletePressed(OrderModel order) async {
    if (order.deliveryPin != null && order.deliveryPin!.isNotEmpty) {
      _showPinDialog(order);
    } else {
      await _completeDelivery(order);
    }
  }

  void _showPinDialog(OrderModel order) {
    final pinController = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.pin_outlined, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('Enter Delivery PIN'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ask the customer for their 4-digit PIN to confirm delivery.',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: AppTextStyles.h2.copyWith(letterSpacing: 8),
                    decoration: InputDecoration(
                      hintText: '- - - -',
                      hintStyle: AppTextStyles.h2.copyWith(
                        color: AppColors.disabled,
                        letterSpacing: 8,
                      ),
                      counterText: '',
                      errorText: errorText,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final pin = pinController.text.trim();
                    if (pin.length != 4) {
                      setDialogState(() => errorText = 'Please enter 4 digits');
                      return;
                    }
                    final valid = await _orderRepo.verifyDeliveryPin(order.id, pin);
                    if (valid) {
                      if (ctx.mounted) Navigator.pop(ctx);
                      await _completeDelivery(order);
                    } else {
                      setDialogState(() => errorText = 'Incorrect PIN. Try again.');
                      pinController.clear();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildProgressSection(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.delivery_dining_rounded, color: AppColors.secondary, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery in Progress',
                      style: AppTextStyles.h3.copyWith(color: AppColors.white),
                    ),
                    Text(
                      'Order #${order.id.substring(order.id.length - 6)}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.white.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStep('Picked Up', true),
              Expanded(child: Container(height: 2, color: AppColors.white.withValues(alpha: 0.3))),
              _buildStep('On The Way', true),
              Expanded(child: Container(height: 2, color: AppColors.white.withValues(alpha: 0.3))),
              _buildStep('Delivered', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String label, bool completed) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed ? AppColors.secondary : AppColors.white.withValues(alpha: 0.3),
          ),
          child: completed
              ? const Icon(Icons.check, size: 14, color: AppColors.primary)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.white.withValues(alpha: completed ? 1 : 0.5),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildDeliveredView(OrderModel order) {
    final riderEarning = order.serviceFee > 0 ? order.serviceFee : order.deliveryFee;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
            ),
            const SizedBox(height: 24),
            Text('Delivery Complete!', style: AppTextStyles.h2),
            const SizedBox(height: 8),
            Text(
              'You earned ${NumberFormat.currency(symbol: '\u20A6', decimalDigits: 0).format(riderEarning)}',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.success),
            ),
            if (order.serviceFee > 0) ...[
              const SizedBox(height: 4),
              Text(
                'From service fee',
                style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeDelivery(OrderModel order) async {
    setState(() => _isCompleting = true);
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthAuthenticated) {
        await context.read<OrdersCubit>().completeDelivery(
              order.id,
              authState.rider.uid,
            );
        if (mounted) {
          context.read<AuthCubit>().refreshProfile();
        }
      }
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  Future<void> _callCustomer() async {
    final uri = Uri(scheme: 'tel', path: '0000000000');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
