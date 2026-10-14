import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';

part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationRepository _notifRepo;
  StreamSubscription? _notifSub;
  StreamSubscription? _unreadSub;

  NotificationsCubit(this._notifRepo) : super(NotificationsInitial());

  void startWatching(String riderId) {
    _notifSub?.cancel();
    _notifSub = _notifRepo.getNotifications(riderId).listen(
      (notifications) {
        final currentState = state;
        final unreadCount = currentState is NotificationsLoaded
            ? currentState.unreadCount
            : 0;
        emit(NotificationsLoaded(
          notifications: notifications,
          unreadCount: unreadCount,
        ));
      },
      onError: (e) => emit(NotificationsError(e.toString())),
    );

    _unreadSub?.cancel();
    _unreadSub = _notifRepo.getUnreadCount(riderId).listen(
      (count) {
        final currentState = state;
        if (currentState is NotificationsLoaded) {
          emit(currentState.copyWith(unreadCount: count));
        } else {
          emit(NotificationsLoaded(unreadCount: count));
        }
      },
    );
  }

  Future<void> markAsRead(String notificationId) async {
    await _notifRepo.markAsRead(notificationId);
  }

  Future<void> markAllAsRead(String riderId) async {
    await _notifRepo.markAllAsRead(riderId);
  }

  @override
  Future<void> close() {
    _notifSub?.cancel();
    _unreadSub?.cancel();
    return super.close();
  }
}
