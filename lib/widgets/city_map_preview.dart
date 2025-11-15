import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CityMapPreview extends StatefulWidget {
  final LatLng? center;
  final String? cityName;
  final double zoom;
  final double height;
  final double borderRadius;

  const CityMapPreview({
    super.key,
    required this.center,
    this.cityName,
    this.zoom = 11.0,
    this.height = 220,
    this.borderRadius = 12,
  });

  @override
  State<CityMapPreview> createState() => _CityMapPreviewState();
}

class _CityMapPreviewState extends State<CityMapPreview> {
  late final MapController _controller;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _controller = MapController();
  }

  @override
  void didUpdateWidget(covariant CityMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_mapReady || widget.center == null) return;
    // Skip initial null->non-null transition (handled by initialCenter)
    final hadCenterBefore = oldWidget.center != null;
    final centerChanged = hadCenterBefore &&
        (oldWidget.center!.latitude != widget.center!.latitude ||
            oldWidget.center!.longitude != widget.center!.longitude);
    final zoomChanged = widget.zoom != oldWidget.zoom;
    if (centerChanged || zoomChanged) {
      // Move map to new target; wrap in try to avoid errors if disposed mid-hover
      try {
        _controller.move(widget.center!, widget.zoom);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: widget.center == null
          ? _Placeholder(cityName: widget.cityName)
          : Stack(
              children: [
                FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                    initialCenter: widget.center!,
                    initialZoom: widget.zoom,
                    onMapReady: () {
                      _mapReady = true;
                      // If widget updated while map was mounting, ensure we are at latest center/zoom
                      if (widget.center != null) {
                        try {
                          _controller.move(widget.center!, widget.zoom);
                        } catch (_) {}
                      }
                    },
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'zpi_test',
                      maxZoom: 18,
                      minZoom: 2,
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: widget.center!,
                          width: 36,
                          height: 36,
                          child: const _Pin(),
                        ),
                      ],
                    ),
                    RichAttributionWidget(
                      attributions: const [
                        TextSourceAttribution('© OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),
                if (widget.cityName != null && widget.cityName!.isNotEmpty)
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        child: Text(
                          widget.cityName!,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String? cityName;
  const _Placeholder({this.cityName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_outlined, color: Colors.grey.shade400, size: 36),
          const SizedBox(height: 8),
          Text(
            cityName == null || cityName!.isEmpty
                ? 'Hover a city to preview'
                : 'Preview for "$cityName"',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.purple,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
