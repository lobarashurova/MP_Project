import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yandex_maps_mapkit_lite/mapkit.dart' as ymk;
import 'package:yandex_maps_mapkit_lite/mapkit_factory.dart';
import 'package:yandex_maps_mapkit_lite/yandex_map.dart';
import 'package:xurmo/core/constants/app_colors.dart';
import 'package:xurmo/core/constants/map_config.dart';
import 'package:xurmo/data/models/delivery_location.dart';
import 'package:xurmo/data/repositories/geocoding_repository.dart';

/// Full-screen Yandex map for choosing a delivery address.
///
/// The pin stays fixed in the middle of the screen and the person moves the
/// map under it. When the map stops, the address under the pin is looked up
/// and shown in the bottom card. Pops with the chosen [DeliveryLocation], or
/// null when the person backs out.
class LocationPickerPage extends StatefulWidget {
  /// Where to open the map, e.g. the previously chosen address.
  final DeliveryLocation? initial;

  final GeocodingRepository? geocoding;

  const LocationPickerPage({super.key, this.initial, this.geocoding});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  late final GeocodingRepository _geocoding;
  ymk.Map? _map;

  /// Yandex keeps only a weak reference to camera listeners, so hold it here.
  late final _CameraIdleListener _cameraListener = _CameraIdleListener(_onCameraIdle);

  DeliveryLocation? _selected;
  bool _isResolving = false;
  String? _resolveError;
  bool _isLocating = false;

  /// Increments on every lookup so a slow answer for an old pin position
  /// can't overwrite the answer for the current one.
  int _lookupId = 0;
  Timer? _idleDebounce;

  @override
  void initState() {
    super.initState();
    _geocoding = widget.geocoding ?? GeocodingRepository();
    _selected = widget.initial;
    // MapKit only loads tiles between onStart and onStop.
    mapkit.onStart();
  }

  @override
  void dispose() {
    _idleDebounce?.cancel();
    _map?.removeCameraListener(_cameraListener);
    mapkit.onStop();
    super.dispose();
  }

  // ------------------------------------------------------------------ Map

  void _onMapCreated(ymk.MapWindow window) {
    final map = window.map;
    _map = map;

    // A delivery pin doesn't need rotation or 3D tilt.
    map.rotateGesturesEnabled = false;
    map.tiltGesturesEnabled = false;

    // Yandex's licence requires its logo to stay visible; keep it clear of
    // the bottom card.
    map.logo.setAlignment(const ymk.LogoAlignment(
      ymk.LogoHorizontalAlignment.Right,
      ymk.LogoVerticalAlignment.Top,
    ));
    map.logo.setPadding(const ymk.LogoPadding(horizontalPadding: 12, verticalPadding: 72));

    map.addCameraListener(_cameraListener);

    final initial = widget.initial;
    map.move(_cameraAt(
      initial?.latitude ?? MapConfig.defaultLatitude,
      initial?.longitude ?? MapConfig.defaultLongitude,
      initial == null ? MapConfig.defaultZoom : MapConfig.streetZoom,
    ));
  }

  static ymk.CameraPosition _cameraAt(double latitude, double longitude, double zoom) {
    return ymk.CameraPosition(
      ymk.Point(latitude: latitude, longitude: longitude),
      zoom: zoom,
      azimuth: 0,
      tilt: 0,
    );
  }

  void _onCameraIdle() {
    // Wait briefly so a quick series of drags causes one lookup, not several.
    _idleDebounce?.cancel();
    _idleDebounce = Timer(const Duration(milliseconds: 400), _resolveCenter);
  }

  Future<void> _resolveCenter() async {
    final target = _map?.cameraPosition.target;
    if (target == null || !mounted) return;

    final id = ++_lookupId;
    setState(() {
      _isResolving = true;
      _resolveError = null;
    });

    try {
      final place = await _geocoding.reverse(target.latitude, target.longitude);
      if (!mounted || id != _lookupId) return;
      setState(() {
        _selected = place ??
            DeliveryLocation(
              latitude: target.latitude,
              longitude: target.longitude,
              address: 'Pinned location',
              fullAddress:
                  '${target.latitude.toStringAsFixed(5)}, ${target.longitude.toStringAsFixed(5)}',
            );
        _isResolving = false;
      });
    } on GeocodingFailure catch (e) {
      if (!mounted || id != _lookupId) return;
      setState(() {
        // The coordinates are still valid, so the pin can be confirmed even
        // when the address lookup fails.
        _selected = DeliveryLocation(
          latitude: target.latitude,
          longitude: target.longitude,
          address: 'Pinned location',
        );
        _resolveError = e.message;
        _isResolving = false;
      });
    }
  }

  void _moveTo(double latitude, double longitude) {
    _map?.move(
      _cameraAt(latitude, longitude, MapConfig.streetZoom),
      animation: const ymk.Animation(type: ymk.AnimationType.Smooth, duration: 0.6),
    );
  }

  // ------------------------------------------------------------- Actions

  Future<void> _goToMyLocation() async {
    setState(() => _isLocating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _showMessage('Turn on location services to use your current location.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        _showMessage('Location permission is needed to find you on the map.');
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        _showMessage('Location is blocked for Xurmo. Enable it in your phone settings.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      _moveTo(position.latitude, position.longitude);
    } on TimeoutException {
      _showMessage('Could not get your location. Try again or move the map.');
    } catch (_) {
      _showMessage('Could not get your location. Try again or move the map.');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _openSearch() async {
    final result = await showSearch<DeliveryLocation?>(
      context: context,
      delegate: _AddressSearchDelegate(_geocoding),
    );
    if (result == null || !mounted) return;

    // Show the chosen address immediately; the lookup after the camera stops
    // will confirm or refine it.
    setState(() {
      _selected = result;
      _resolveError = null;
    });
    _moveTo(result.latitude, result.longitude);
  }

  void _confirm() {
    final selected = _selected;
    if (selected == null) return;
    Navigator.of(context).pop(selected);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          YandexMap(onMapCreated: _onMapCreated),

          // Fixed centre pin. Its tip sits on the map centre.
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 44),
                child: Icon(CupertinoIcons.location_solid, size: 44, color: AppColors.primary),
              ),
            ),
          ),

          // Back button and search bar.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  _CircleButton(
                    icon: Icons.arrow_back,
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Material(
                      color: AppColors.surface,
                      elevation: 3,
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: _openSearch,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Icon(Icons.search, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Text('Search street or place',
                                  style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom card with the address and the confirm button.
          Align(
            alignment: Alignment.bottomCenter,
            child: _AddressCard(
              selected: _selected,
              isResolving: _isResolving,
              error: _resolveError,
              isLocating: _isLocating,
              onMyLocation: _isLocating ? null : _goToMyLocation,
              onConfirm: _selected == null || _isResolving ? null : _confirm,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _CircleButton({required this.icon, required this.tooltip, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 3,
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, color: AppColors.iconPrimary),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final DeliveryLocation? selected;
  final bool isResolving;
  final String? error;
  final bool isLocating;
  final VoidCallback? onMyLocation;
  final VoidCallback? onConfirm;

  const _AddressCard({
    required this.selected,
    required this.isResolving,
    required this.error,
    required this.isLocating,
    required this.onMyLocation,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final title = isResolving
        ? 'Finding address…'
        : (selected?.address ?? 'Move the map to place the pin');
    final subtitle = isResolving
        ? null
        : (error ?? (selected != null && selected!.fullAddress != selected!.address
            ? selected!.fullAddress
            : null));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 12),
          child: _CircleButton(
            icon: isLocating ? Icons.more_horiz : Icons.my_location,
            tooltip: 'Use my location',
            onPressed: onMyLocation,
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12)],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Delivery address',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.iconPrimary,
                        ),
                      ),
                    ),
                    if (isResolving)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: error != null ? AppColors.error : AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Confirm address',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.divider,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    MapConfig.geocodingAttribution,
                    style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Address search screen. Waits for a pause in typing before asking the
/// geocoder, to respect Nominatim's one-request-per-second limit.
class _AddressSearchDelegate extends SearchDelegate<DeliveryLocation?> {
  final GeocodingRepository _geocoding;

  _AddressSearchDelegate(this._geocoding)
      : super(searchFieldLabel: 'Street, building or place');

  Timer? _debounce;
  String _pendingQuery = '';
  Future<List<DeliveryLocation>>? _results;

  Future<List<DeliveryLocation>> _resultsFor(String query) {
    if (query != _pendingQuery || _results == null) {
      _pendingQuery = query;
      _debounce?.cancel();
      final completer = Completer<List<DeliveryLocation>>();
      _debounce = Timer(const Duration(milliseconds: 700), () {
        _geocoding.search(query).then(completer.complete, onError: completer.completeError);
      });
      _results = completer.future;
    }
    return _results!;
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  @override
  void close(BuildContext context, DeliveryLocation? result) {
    _debounce?.cancel();
    super.close(context, result);
  }

  Widget _buildList(BuildContext context) {
    final q = query.trim();
    if (q.length < 3) {
      return const _SearchHint('Type at least 3 letters of a street or place.');
    }

    return FutureBuilder<List<DeliveryLocation>>(
      future: _resultsFor(q),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return _SearchHint(error is GeocodingFailure
              ? error.message
              : 'Could not search right now. Please try again.');
        }
        final results = snapshot.data ?? const [];
        if (results.isEmpty) {
          return const _SearchHint(
              'No places found. Try a street name, or move the map to place the pin.');
        }
        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final place = results[index];
            return ListTile(
              leading: const Icon(CupertinoIcons.location, color: AppColors.primary),
              title: Text(place.address),
              subtitle: place.fullAddress == place.address
                  ? null
                  : Text(place.fullAddress, maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () => close(context, place),
            );
          },
        );
      },
    );
  }
}

class _SearchHint extends StatelessWidget {
  final String text;
  const _SearchHint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(text, style: TextStyle(color: AppColors.textSecondary)),
    );
  }
}

/// Calls [onIdle] each time the camera stops moving.
final class _CameraIdleListener implements ymk.MapCameraListener {
  final VoidCallback onIdle;

  _CameraIdleListener(this.onIdle);

  @override
  void onCameraPositionChanged(
    ymk.Map map,
    ymk.CameraPosition cameraPosition,
    ymk.CameraUpdateReason cameraUpdateReason,
    bool finished,
  ) {
    if (finished) onIdle();
  }
}
