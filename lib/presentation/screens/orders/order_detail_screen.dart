import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/orders/orders_cubit.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final orderRepo = OrderRepository();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Order Details')),
      body: StreamBuilder<OrderModel?>(
        stream: orderRepo.watchOrder(orderId),
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
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderHeader(order),
                const SizedBox(height: 20),
                _buildSection('Pickup Location', [
                  _buildInfoRow(Icons.store_outlined, order.vendorName),
                ]),
                const SizedBox(height: 16),
                _buildSection('Delivery Address', [
                  _buildInfoRow(Icons.location_on_outlined, order.deliveryAddress),
                ]),
                const SizedBox(height: 16),
                _buildSection('Order Items', [
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Text('${item.quantity}x', style: AppTextStyles.labelMedium),
                            const SizedBox(width: 12),
                            Expanded(child: Text(item.name, style: AppTextStyles.bodyMedium)),
                            Text(
                              NumberFormat.currency(symbol: '\u20A6', decimalDigits: 0)
                                  .format(item.total),
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      )),
                  const Divider(height: 24),
                  _buildPriceRow('Subtotal', order.subtotal),
                  const SizedBox(height: 4),
                  _buildPriceRow('Delivery Fee', order.deliveryFee),
                  const Divider(height: 24),
                  _buildPriceRow('Total', order.total, bold: true),
                ]),
                if (order.notes != null && order.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSection('Notes', [
                    Text(order.notes!, style: AppTextStyles.bodySmall),
                  ]),
                ],
                const SizedBox(height: 24),
                if (order.isAvailableForPickup) _buildAcceptButton(context, order),
                if (order.status == 'picked_up' && order.riderId != null)
                  _buildGoToDeliveryButton(context, order),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderHeader(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${orderId.substring(orderId.length - 6)}',
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, yyyy - h:mm a').format(order.createdAt),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          _buildStatusBadge(order.status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case 'ready':
        bgColor = AppColors.successLight;
        textColor = AppColors.success;
      case 'picked_up':
        bgColor = AppColors.warningLight;
        textColor = AppColors.warning;
      case 'delivered':
        bgColor = AppColors.successLight;
        textColor = AppColors.success;
      default:
        bgColor = AppColors.infoLight;
        textColor = AppColors.info;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.labelSmall),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
      ],
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: bold ? AppTextStyles.labelMedium : AppTextStyles.bodySmall,
        ),
        Text(
          NumberFormat.currency(symbol: '\u20A6', decimalDigits: 0).format(amount),
          style: bold ? AppTextStyles.labelMedium : AppTextStyles.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildAcceptButton(BuildContext context, OrderModel order) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final rider = authState is AuthAuthenticated ? authState.rider : null;
        if (rider == null) return const SizedBox.shrink();

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              await context.read<OrdersCubit>().acceptOrder(
                    orderId: order.id,
                    riderId: rider.uid,
                    riderName: rider.name,
                    riderPhone: rider.phone,
                  );
              if (context.mounted) {
                context.pushReplacement('/delivery/${order.id}');
              }
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Accept & Pickup'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoToDeliveryButton(BuildContext context, OrderModel order) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => context.pushReplacement('/delivery/${order.id}'),
        icon: const Icon(Icons.delivery_dining_rounded),
        label: const Text('Go to Delivery'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 52),
        ),
      ),
    );
  }
}
