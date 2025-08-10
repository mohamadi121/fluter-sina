import 'package:asoud/core/ui/ui_status.dart';
import 'package:asoud/features/business_card/presentation/bloc/business_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationPicker extends StatelessWidget {
  const LocationPicker({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<BusinessBloc, BusinessState>(
        builder: (context, state) {
          if (state.status is UiLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state.status is UiSuccess) {
            final selectedLocation = state.location;
            return _buildMap(selectedLocation, context, state);
          } else if (state.status is UiIdle) {
            return _buildMap(const LatLng(0, 0), context, state);
          } else if (state.status is UiError) {
            return Center(child: Text((state.status as UiError).message));
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  Widget _buildMap(LatLng selectedLocation, BuildContext context, BusinessState state) {
    final locationBloc = context.read<BusinessBloc>();
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(20)),
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: selectedLocation == const LatLng(0, 0)
                  ? const LatLng(35.6783, 51.4161)
                  : selectedLocation,
              initialZoom: 18,
              interactionOptions: const InteractionOptions(enableMultiFingerGestureRace: true),
              onPositionChanged: (_, __) {
                if (state.status is UiSuccess) {
                  // locationBloc.add(UpdateSelectedLocation(locationBloc.mapController.center));
                }
              },
              onTap: (tapPosition, point) async {
                if (locationBloc.state.status is UiIdle || locationBloc.state.status is UiSuccess) {
                  locationBloc.add(DetermineCurrentPosition());
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: [
                  if (locationBloc.state.status is UiSuccess)
                    Marker(
                      width: 30.0,
                      height: 30.0,
                      point: selectedLocation,
                      child: const Icon(Icons.location_on, size: 30, color: Colors.red),
                    ),
                  if (locationBloc.state.status is UiSuccess)
                    Marker(
                      width: 30.0,
                      height: 30.0,
                      point: selectedLocation,
                      child: const Icon(Icons.pin_drop, size: 30, color: Colors.blue),
                    ),
                ],
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () async {
                      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                      final location = LatLng(position.latitude, position.longitude);
                      locationBloc.add(UpdateSelectedLocation(location));
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
