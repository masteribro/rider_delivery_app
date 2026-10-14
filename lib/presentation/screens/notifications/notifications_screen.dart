import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/notification_model.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/notifications/notifications_cubit.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              final hasUnread =
                  state is NotificationsLoaded && state.unreadCount > 0;
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton(
                onPressed: () {
                  final authState = context.read<AuthCubit>().state;
                  if (authState is AuthAuthenticated) {
                    context
                        .read<NotificationsCubit>()
                        .markAllAsRead(authState.rider.uid);
                  }
                },
                child: Text(
                  'Mark all read',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.primary),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          if (state is NotificationsLoaded) {
            if (state.notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none_rounded,
                        size: 64, color: AppColors.disabled),
                    const SizedBox(height: 16),
                    Text(
                      'No notifications yet',
                      style: AppTextStyles.bodyLarge
                          .copyWith(color: AppColors.textTertiary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You\'ll be notified about new orders and updates',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _NotificationCard(
                    notification: state.notifications[index]);
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!notification.isRead) {
          context.read<NotificationsCubit>().markAsRead(notification.id);
        }
        if (notification.orderId != null) {
          context.push('/order/${notification.orderId}');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? AppColors.white : AppColors.primarySurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notification.isRead ? AppColors.border : AppColors.primary,
            width: notification.isRead ? 0.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, color: _iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTextStyles.labelMedium,
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(notification.createdAt),
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData get _icon {
    switch (notification.type) {
      case 'new_order':
        return Icons.shopping_bag_outlined;
      case 'order_update':
        return Icons.update_outlined;
      case 'earning':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color get _iconColor {
    switch (notification.type) {
      case 'new_order':
        return AppColors.success;
      case 'order_update':
        return AppColors.info;
      case 'earning':
        return AppColors.secondary;
      default:
        return AppColors.textSecondary;
    }
  }

  Color get _iconBgColor {
    switch (notification.type) {
      case 'new_order':
        return AppColors.successLight;
      case 'order_update':
        return AppColors.infoLight;
      case 'earning':
        return AppColors.secondarySurface;
      default:
        return AppColors.primarySurface;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(time);
  }
}
