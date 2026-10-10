part of 'orders_cubit.dart';

abstract class OrdersState extends Equatable {
  const OrdersState();
  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrdersState {}

class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<OrderModel> availableOrders;
  final List<OrderModel> myOrders;
  final List<OrderModel> activeDeliveries;

  const OrdersLoaded({
    this.availableOrders = const [],
    this.myOrders = const [],
    this.activeDeliveries = const [],
  });

  OrdersLoaded copyWith({
    List<OrderModel>? availableOrders,
    List<OrderModel>? myOrders,
    List<OrderModel>? activeDeliveries,
  }) {
    return OrdersLoaded(
      availableOrders: availableOrders ?? this.availableOrders,
      myOrders: myOrders ?? this.myOrders,
      activeDeliveries: activeDeliveries ?? this.activeDeliveries,
    );
  }

  @override
  List<Object?> get props => [
        availableOrders.length,
        myOrders.length,
        activeDeliveries.length,
      ];
}

class OrdersError extends OrdersState {
  final String message;
  const OrdersError(this.message);
  @override
  List<Object?> get props => [message];
}
