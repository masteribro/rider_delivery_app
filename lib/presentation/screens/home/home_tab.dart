import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/orders/orders_cubit.dart';
import '../../bloc/notifications/notifications_cubit.dart';
import '../../../data/models/order_model.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<OrdersCubit>().startWatching(authState.rider.uid);
      context.read<NotificationsCubit>().startWatching(authState.rider.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildOnlineToggle(),
              const SizedBox(height: 24),
              _buildStatsRow(),
              const SizedBox(height: 24),
              _buildActiveDeliveries(),
              const SizedBox(height: 24),
              _buildAvailableOrders(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final rider = state is AuthAuthenticated ? state.rider : null;
        return Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primarySurface,
              child: Text(
                rider?.name.isNotEmpty == true ? rider!.name[0].toUpperCase() : 'R',
                style: AppTextStyles.h3.copyWith(color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${rider?.name.split(' ').first ?? 'Rider'}',
                    style: AppTextStyles.h3,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: rider?.isOnline == true
                              ? AppColors.online
                              : AppColors.offline,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        rider?.isOnline == true ? 'Online' : 'Offline',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            BlocBuilder<NotificationsCubit, NotificationsState>(
              builder: (context, notifState) {
                final unread = notifState is NotificationsLoaded
                    ? notifState.unreadCount
                    : 0;
                return IconButton(
                  onPressed: () => context.push('/notifications'),
                  icon: Badge(
                    isLabelVisible: unread > 0,
                    label: Text('$unread'),
                    child: const Icon(Icons.notifications_outlined),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildOnlineToggle() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final rider = state is AuthAuthenticated ? state.rider : null;
        final isOnline = rider?.isOnline ?? false;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isOnline
                  ? [AppColors.primary, AppColors.primaryLight]
                  : [AppColors.disabled, const Color(0xFF9CA3AF)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOnline ? "You're Online" : "You're Offline",
                      style: AppTextStyles.h3.copyWith(color: AppColors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOnline
                          ? 'You can receive delivery requests'
                          : 'Go online to start receiving orders',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 1.2,
                child: Switch(
                  value: isOnline,
                  onChanged: (_) {
                    context.read<AuthCubit>().toggleOnlineStatus();
                  },
                  activeThumbColor: AppColors.secondary,
                  activeTrackColor: AppColors.secondary.withValues(alpha: 0.4),
                  inactiveThumbColor: AppColors.white,
                  inactiveTrackColor: AppColors.white.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsRow() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final rider = state is AuthAuthenticated ? state.rider : null;
        return Row(
          children: [
            _buildStatCard(
              icon: Icons.delivery_dining_rounded,
              label: 'Deliveries',
              value: '${rider?.completedDeliveries ?? 0}',
              color: AppColors.info,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Earnings',
              value: NumberFormat.currency(symbol: '\u20A6', decimalDigits: 0)
                  .format(rider?.totalEarnings ?? 0),
              color: AppColors.success,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              icon: Icons.star_outline_rounded,
              label: 'Rating',
              value: rider?.rating.toStringAsFixed(1) ?? '0.0',
              color: AppColors.warning,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: AppTextStyles.labelLarge),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveDeliveries() {
    return BlocBuilder<OrdersCubit, OrdersState>(
      builder: (context, state) {
        final active = state is OrdersLoaded ? state.activeDeliveries : <OrderModel>[];
        if (active.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Active Delivery', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            ...active.map((order) => _buildActiveDeliveryCard(order)),
          ],
        );
      },
    );
  }

  Widget _buildActiveDeliveryCard(OrderModel order) {
    return GestureDetector(
      onTap: () => context.push('/delivery/${order.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.secondary, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'IN PROGRESS',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '#${order.id.substring(order.id.length - 6)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.store_outlined, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(order.vendorName, style: AppTextStyles.bodyMedium),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(order.deliveryAddress, style: AppTextStyles.bodySmall),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${order.items.length} items',
                  style: AppTextStyles.caption,
                ),
                const Spacer(),
                Text(
                  NumberFormat.currency(symbol: '\u20A6', decimalDigits: 0).format(order.deliveryFee),
                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.success),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableOrders() {
    return BlocBuilder<OrdersCubit, OrdersState>(
      builder: (context, state) {
        final available = state is OrdersLoaded ? state.availableOrders : <OrderModel>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Available Orders', style: AppTextStyles.h3),
                if (available.isNotEmpty)
                  TextButton(
                    onPressed: () => context.go('/orders'),
                    child: Text(
                      'See All',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (available.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 48, color: AppColors.disabled),
                      const SizedBox(height: 12),
                      Text(
                        'No orders available right now',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'New orders will appear here',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...available.take(3).map((order) => _buildOrderCard(order)),
          ],
        );
      },
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return GestureDetector(
      onTap: () => context.push('/order/${order.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
                        '${order.items.length} items',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                Text(
                  NumberFormat.currency(symbol: '\u20A6', decimalDigits: 0).format(order.deliveryFee),
                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.success),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
}
