import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../core/services/places_service.dart';
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
  final _placesService = PlacesService();
  bool _isCompleting = false;

  // Map state
  GoogleMapController? _mapController;
  LatLng? _riderPosition;
  LatLng? _destinationPosition;
  List<LatLng> _routePoints = [];
  String? _duration;
  String? _distance;
  StreamSubscription<Position>? _positionStream;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied ||
          requested == LocationPermission.deniedForever) return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (mounted) {
        setState(() {
          _riderPosition = LatLng(position.latitude, position.longitude);
        });
        _updateRouteIfReady();
      }
    } catch (_) {}

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      if (mounted) {
        setState(() {
          _riderPosition = LatLng(position.latitude, position.longitude);
        });
        _fitMapBounds();
        // Push location to Firestore for customer tracking
        _orderRepo.updateRiderLocation(
          widget.orderId,
          position.latitude,
          position.longitude,
        );
      }
    });
  }

  Future<void> _resolveDestination(String address) async {
    if (_destinationPosition != null) return;
    final result = await _placesService.getLatLngFromAddress(address);
    if (result != null && mounted) {
      setState(() {
        _destinationPosition = LatLng(result.lat, result.lng);
      });
      _updateRouteIfReady();
    }
  }

  Future<void> _updateRouteIfReady() async {
    if (_riderPosition == null || _destinationPosition == null) return;
    _fitMapBounds();
    await _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    final origin = _riderPosition;
    final dest = _destinationPosition;
    if (origin == null || dest == null) return;

    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    if (apiKey.isEmpty) return;

    try {
      final response = await Dio().get(
        'https://maps.googleapis.com/maps/api/directions/json',
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${dest.latitude},${dest.longitude}',
          'mode': 'driving',
          'key': apiKey,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      final data = response.data as Map<String, dynamic>;
      if (data['status'] == 'OK') {
        final routes = data['routes'] as List<dynamic>;
        if (routes.isNotEmpty) {
          final route = routes[0] as Map<String, dynamic>;
          final points = _decodePolyline(
              route['overview_polyline']['points'] as String);
          final leg =
              (route['legs'] as List<dynamic>).first as Map<String, dynamic>;

          if (mounted) {
            setState(() {
              _routePoints = points;
              _duration = leg['duration']?['text'] as String?;
              _distance = leg['distance']?['text'] as String?;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('[ActiveDelivery] Directions error: $e');
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  void _fitMapBounds() {
    if (_mapController == null || !_mapReady) return;

    final positions = <LatLng>[];
    if (_riderPosition != null) positions.add(_riderPosition!);
    if (_destinationPosition != null) positions.add(_destinationPosition!);
    if (positions.length < 2) return;

    double minLat = positions[0].latitude;
    double maxLat = positions[0].latitude;
    double minLng = positions[0].longitude;
    double maxLng = positions[0].longitude;

    for (final p in positions) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        60,
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    if (_riderPosition != null) {
      markers.add(Marker(
        markerId: const MarkerId('rider'),
        position: _riderPosition!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'You'),
      ));
    }
    if (_destinationPosition != null) {
      markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: _destinationPosition!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Delivery Location'),
      ));
    }
    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (_routePoints.isEmpty) return {};
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: _routePoints,
        color: AppColors.secondary,
        width: 5,
      ),
    };
  }

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

          // Resolve destination from order address (use lat/lng if available)
          if (_destinationPosition == null) {
            if (order.deliveryLat != null && order.deliveryLng != null) {
              _destinationPosition = LatLng(order.deliveryLat!, order.deliveryLng!);
              _updateRouteIfReady();
            } else {
              _resolveDestination(order.deliveryAddress);
            }
          }

          if (order.status == 'delivered') {
            return _buildDeliveredView(order);
          }
          return _buildDeliveryView(order);
        },
      ),
    );
  }

  Widget _buildMapSection() {
    final initialPosition = _riderPosition ?? const LatLng(9.0579, 7.4951); // Abuja default

    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialPosition,
              zoom: 14,
            ),
            markers: _buildMarkers(),
            polylines: _buildPolylines(),
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              _mapReady = true;
              _fitMapBounds();
            },
          ),
          // Duration/Distance badge
          if (_duration != null || _distance != null)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_car, size: 16, color: AppColors.secondary),
                    const SizedBox(width: 6),
                    Text(
                      [if (_duration != null) _duration!, if (_distance != null) _distance!]
                          .join(' - '),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Recenter button
          Positioned(
            bottom: 12,
            right: 12,
            child: FloatingActionButton.small(
              heroTag: 'recenter',
              onPressed: _fitMapBounds,
              backgroundColor: AppColors.white,
              child: const Icon(Icons.my_location, color: AppColors.primary, size: 20),
            ),
          ),
        ],
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
          const SizedBox(height: 16),

          // Live Map
          _buildMapSection(),
          const SizedBox(height: 16),

          // Pickup info
          _buildLocationCard(
            icon: Icons.store_outlined,
            iconColor: AppColors.primary,
            title: 'Pickup from',
            subtitle: order.vendorAddress != null && order.vendorAddress!.isNotEmpty
                ? '${order.vendorName}\n${order.vendorAddress}'
                : order.vendorName,
            trailing: order.vendorLat != null && order.vendorLng != null
                ? IconButton(
                    icon: const Icon(Icons.navigation_outlined, color: AppColors.primary),
                    tooltip: 'Navigate to vendor',
                    onPressed: () {
                      launchUrl(Uri.parse(
                        'google.navigation:q=${order.vendorLat},${order.vendorLng}&mode=d',
                      ));
                    },
                  )
                : null,
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
          if (trailing != null) trailing,
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
