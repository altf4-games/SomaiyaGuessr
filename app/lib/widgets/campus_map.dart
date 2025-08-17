import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../utils/theme.dart';
import 'package:flutter/services.dart'; // Import for HapticFeedback

class CampusMap extends StatefulWidget {
  final Function(LatLng) onTap;
  final LatLng? guessLocation;

  const CampusMap({
    super.key,
    required this.onTap,
    this.guessLocation,
  });

  @override
  State<CampusMap> createState() => _CampusMapState();
}

class _CampusMapState extends State<CampusMap>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _bounceController; // Added bounce animation for better UX
  late Animation<double> _bounceAnimation;

  // Somaiya Campus bounds
  static const LatLng _campusCenter = LatLng(19.0728, 72.8997);
  static const double _initialZoom = 16.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
    
    _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(CampusMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.guessLocation != null && oldWidget.guessLocation != widget.guessLocation) {
      _bounceController.reset();
      _bounceController.forward();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose(); // Proper cleanup to prevent framework errors
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
              options: MapOptions(
                initialCenter: _campusCenter,
                initialZoom: _initialZoom,
                minZoom: 14.0,
                maxZoom: 19.0,
                onTap: (tapPosition, point) {
                  widget.onTap(point);
                  HapticFeedback.lightImpact(); // Added haptic feedback for better mobile experience
                },
                cameraConstraint: CameraConstraint.unconstrained(), // Removed restrictive camera constraint to prevent assertion errors
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                // bounds: LatLngBounds( // Removed unsupported bounds parameter
                //   const LatLng(19.0650, 72.8920), // More generous southwest bound
                //   const LatLng(19.0800, 72.9070), // More generous northeast bound
                // ),
                // boundsOptions: const FitBoundsOptions(
                //   padding: EdgeInsets.all(20),
                // ),
              ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.somaiya.guessr',
              maxZoom: 19,
              subdomains: const ['a', 'b', 'c'],
              errorTileCallback: (tile, error, stackTrace) {
                // Handle tile loading errors gracefully
                debugPrint('Tile loading error: $error');
              },
              // Add additional configuration for better loading
              tileProvider: NetworkTileProvider(),
            ),
            if (widget.guessLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.guessLocation!,
                    width: 120,
                    height: 120,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_pulseAnimation, _bounceAnimation]),
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _bounceAnimation.value,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryAccent.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primaryAccent.withOpacity(0.5),
                                      width: 3,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primaryAccent,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.my_location,
                                  color: Colors.white,
                                  size: 20, // Larger icon for better visibility
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            PolygonLayer(
              polygons: [
                Polygon(
                  points: [
                    const LatLng(19.0650, 72.8920),
                    const LatLng(19.0650, 72.9070),
                    const LatLng(19.0800, 72.9070),
                    const LatLng(19.0800, 72.8920),
                  ],
                  color: AppColors.primaryAccent.withOpacity(0.08),
                  borderColor: AppColors.primaryAccent.withOpacity(0.4),
                  borderStrokeWidth: 2,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
