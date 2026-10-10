import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';

part 'orders_state.dart';

class OrdersCubit extends Cubit<OrdersState> {
  final OrderRepository _orderRepo;
  StreamSubscription? _availableSub;
  StreamSubscription? _myOrdersSub;
  StreamSubscription? _activeSub;

  OrdersCubit(this._orderRepo) : super(OrdersInitial());

  void startWatching(String riderId) {
    emit(OrdersLoading());

    _availableSub?.cancel();
    _availableSub = _orderRepo.getAvailableOrders().listen(
      (orders) {
        final currentState = state;
        if (currentState is OrdersLoaded) {
          emit(currentState.copyWith(availableOrders: orders));
        } else {
          emit(OrdersLoaded(availableOrders: orders));
        }
      },
      onError: (e) => emit(OrdersError(e.toString())),
    );

    _myOrdersSub?.cancel();
    _myOrdersSub = _orderRepo.getRiderOrders(riderId).listen(
      (orders) {
        final currentState = state;
        if (currentState is OrdersLoaded) {
          emit(currentState.copyWith(myOrders: orders));
        } else {
          emit(OrdersLoaded(myOrders: orders));
        }
      },
    );

    _activeSub?.cancel();
    _activeSub = _orderRepo.getActiveDeliveries(riderId).listen(
      (orders) {
        final currentState = state;
        if (currentState is OrdersLoaded) {
          emit(currentState.copyWith(activeDeliveries: orders));
        } else {
          emit(OrdersLoaded(activeDeliveries: orders));
        }
      },
    );
  }

  Future<void> acceptOrder({
    required String orderId,
    required String riderId,
    required String riderName,
    required String riderPhone,
  }) async {
    try {
      await _orderRepo.acceptOrder(
        orderId: orderId,
        riderId: riderId,
        riderName: riderName,
        riderPhone: riderPhone,
      );
    } catch (e) {
      emit(OrdersError('Failed to accept order: ${e.toString()}'));
    }
  }

  Future<void> completeDelivery(String orderId, String riderId) async {
    try {
      await _orderRepo.completeDelivery(orderId, riderId);
    } catch (e) {
      emit(OrdersError('Failed to complete delivery: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _availableSub?.cancel();
    _myOrdersSub?.cancel();
    _activeSub?.cancel();
    return super.close();
  }
}
