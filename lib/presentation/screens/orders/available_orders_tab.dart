import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../bloc/orders/orders_cubit.dart';
import '../../../data/models/order_model.dart';

class AvailableOrdersTab extends StatelessWidget {
  const AvailableOrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Orders'),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textTertiary,
            indicatorColor: AppColors.primary,
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: [
              Tab(text: 'Available'),
              Tab(text: 'My Orders'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AvailableOrdersList(),
            _MyOrdersList(),
          ],
        ),
      ),
    );
  }
}

class _AvailableOrdersList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersCubit, OrdersState>(
      builder: (context, state) {
        if (state is OrdersLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = state is OrdersLoaded ? state.availableOrders : <OrderModel>[];
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: AppColors.disabled),
                const SizedBox(height: 16),
                Text('No available orders', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textTertiary)),
                const SizedBox(height: 8),
                Text('Check back soon!', style: AppTextStyles.caption),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: orders.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _OrderCard(order: orders[index]),
        );
      },
    );
  }
}

class _MyOrdersList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersCubit, OrdersState>(
      builder: (context, state) {
        final orders = state is OrdersLoaded ? state.myOrders : <OrderModel>[];
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.disabled),
                const SizedBox(height: 16),
                Text('No deliveries yet', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textTertiary)),
                const SizedBox(height: 8),
                Text('Your completed deliveries will appear here', style: AppTextStyles.caption),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: orders.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _OrderCard(order: orders[index], showStatus: true),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final bool showStatus;

  const _OrderCard({required this.order, this.showStatus = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (order.status == 'picked_up') {
          context.push('/delivery/${order.id}');
        } else {
          context.push('/order/${order.id}');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.store_outlined, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.vendorName, style: AppTextStyles.labelMedium),
                      Text(
                        DateFormat('MMM d, h:mm a').format(order.createdAt),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                if (showStatus)
                  _buildStatusBadge(order.status)
                else
                  Text(
                    NumberFormat.currency(symbol: '\u20A6', decimalDigits: 0)
                        .format(order.deliveryFee),
                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.success),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 16, color: AppColors.textTertiary),
                const SizedBox(width: 6),
                Text('${order.items.length} items', style: AppTextStyles.bodySmall),
                const Spacer(),
                Text(
                  NumberFormat.currency(symbol: '\u20A6', decimalDigits: 0).format(order.total),
                  style: AppTextStyles.priceSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.deliveryAddress,
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case 'picked_up':
        bgColor = AppColors.warningLight;
        textColor = AppColors.warning;
      case 'delivered':
        bgColor = AppColors.successLight;
        textColor = AppColors.success;
      case 'cancelled':
        bgColor = AppColors.errorLight;
        textColor = AppColors.error;
      default:
        bgColor = AppColors.infoLight;
        textColor = AppColors.info;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: AppTextStyles.caption.copyWith(color: textColor, fontWeight: FontWeight.w700, fontSize: 10),
      ),
    );
  }
}
