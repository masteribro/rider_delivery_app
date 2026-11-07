import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/places_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/place_detail.dart';
import '../../data/models/place_prediction.dart';

class PlacesAutoCompleteField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<PlaceDetail>? onPlaceSelected;
  final String hintText;
  final int maxLines;

  const PlacesAutoCompleteField({
    super.key,
    required this.controller,
    this.onPlaceSelected,
    this.hintText = 'Search for an address',
    this.maxLines = 1,
  });

  @override
  State<PlacesAutoCompleteField> createState() =>
      _PlacesAutoCompleteFieldState();
}

class _PlacesAutoCompleteFieldState extends State<PlacesAutoCompleteField> {
  final _focusNode = FocusNode();
  final _placesService = PlacesService();
  final _layerLink = LayerLink();

  List<PlacePrediction> _predictions = [];
  bool _suppressSearch = false;
  Timer? _debounce;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _focusNode.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus) _removeOverlay();
      });
    }
  }

  void _onTextChanged() {
    if (_suppressSearch) return;

    _debounce?.cancel();
    final query = widget.controller.text.trim();
    if (query.length < 2) {
      _removeOverlay();
      return;
    }

    if (query.length == 2) _placesService.startSession();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchPlaces(query);
    });
  }

  Future<void> _searchPlaces(String query) async {
    final results = await _placesService.getAutoComplete(query);
    if (!mounted) return;

    _predictions = results;
    if (_predictions.isNotEmpty && _focusNode.hasFocus) {
      _showOverlayList();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlayList() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: _getFieldWidth(),
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 56),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            color: AppColors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _predictions.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: AppColors.border.withValues(alpha: 0.4)),
                itemBuilder: (context, index) {
                  final prediction = _predictions[index];
                  return InkWell(
                    onTap: () => _onPredictionTapped(prediction),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 20, color: AppColors.textTertiary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prediction.mainText,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (prediction.secondaryText.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    prediction.secondaryText,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textTertiary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  double _getFieldWidth() {
    final renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.size.width ?? 300;
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _predictions = [];
  }

  Future<void> _onPredictionTapped(PlacePrediction prediction) async {
    _suppressSearch = true;
    widget.controller.text = prediction.description;
    _focusNode.unfocus();
    _removeOverlay();

    final detail = await _placesService.getPlaceDetail(prediction.placeId);
    if (detail != null) {
      widget.onPlaceSelected?.call(detail);
    }

    _suppressSearch = false;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        maxLines: widget.maxLines,
        keyboardType: TextInputType.streetAddress,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: widget.hintText,
          suffixIcon: const Icon(Icons.search, size: 20),
        ),
      ),
    );
  }
}
