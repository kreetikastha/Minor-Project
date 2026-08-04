import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/band_status.dart';

class MapCard extends StatelessWidget {
  final BandStatus? status;
  final Position? phonePosition;
  final Set<Marker> markers;
  final Function(GoogleMapController) onMapCreated;
  final double height;

  const MapCard({
    Key? key,
    required this.status,
    this.phonePosition,
    required this.markers,
    required this.onMapCreated,
    this.height = 350,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine the initial camera focus
    LatLng initialTarget = const LatLng(27.7172, 85.3240); 
    
    if (status != null) {
      initialTarget = LatLng(status!.latitude, status!.longitude);
    } else if (phonePosition != null) {
      initialTarget = LatLng(phonePosition!.latitude, phonePosition!.longitude);
    }

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
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialTarget,
            zoom: 15,
          ),
          markers: markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          onMapCreated: onMapCreated,
          style: _darkMapStyle,
        ),
      ),
    );
  }

  final String _darkMapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#242f3e"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#746855"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#17263c"}]
    }
  ]
  ''';
}
