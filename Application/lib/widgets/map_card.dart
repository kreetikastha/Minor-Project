import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/band_status.dart';

class MapCard extends StatelessWidget {
  final BandStatus? status;
  final Set<Marker> markers;
  final Function(GoogleMapController) onMapCreated;
  final double height;

  const MapCard({
    Key? key,
    required this.status,
    required this.markers,
    required this.onMapCreated,
    this.height = 350,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: status == null
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    status!.latitude,
                    status!.longitude,
                  ),
                  zoom: 16,
                ),
                markers: markers,
                myLocationEnabled: true,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: onMapCreated,
                style: _darkMapStyle, // Optional: You can add dark mode json here
              ),
      ),
    );
  }

  // Dark mode style for the map (simplified)
  final String _darkMapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#242f3e"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#746855"}]
    }
  ]
  ''';
}
