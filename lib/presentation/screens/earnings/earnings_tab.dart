import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/order_model.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/orders/orders_cubit.dart';

class EarningsTab extends StatelessWidget {
  const EarningsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Earnings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEarningsSummary(context),
            const SizedBox(height: 24),
            Text('Recent Deliveries', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            _buildDeliveryHistory(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsSummary(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final rider = state is AuthAuthenticated ? state.rider : null;
        final earnings = rider?.totalEarnings ?? 0;
        final deliveries = rider?.completedDeliveries ?? 0;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                'Total Earnings',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                NumberFormat.currency(symbol: '\u20A6', decimalDigits: 0).format(earnings),
                style: AppTextStyles.h1.copyWith(
                  color: AppColors.white,
                  fontSize: 36,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.delivery_dining_rounded, color: AppColors.secondary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '$deliveries deliveries completed',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeliveryHistory(BuildContext context) {
    return BlocBuilder<OrdersCubit, OrdersState>(
      builder: (context, state) {
        final allOrders = state is OrdersLoaded ? state.myOrders : <OrderModel>[];
        final delivered = allOrders.where((o) => o.status == 'delivered').toList();

        if (delivered.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.disabled),
                  const SizedBox(height: 12),
                  Text(
                    'No completed deliveries yet',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: delivered.map((order) => _buildDeliveryItem(order)).toList(),
        );
      },
    );
  }

  Widget _buildDeliveryItem(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.vendorName, style: AppTextStyles.labelMedium),
                Text(
                  order.deliveredAt != null
                      ? DateFormat('MMM d, h:mm a').format(order.deliveredAt!)
                      : DateFormat('MMM d, h:mm a').format(order.createdAt),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Text(
            '+${NumberFormat.currency(symbol: '\u20A6', decimalDigits: 0).format(order.deliveryFee)}',
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.success),
          ),
        ],
      ),
    );
  }
}
