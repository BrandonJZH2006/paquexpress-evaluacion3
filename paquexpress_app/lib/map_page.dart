// lib/map_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'api_service.dart'; // Para usar PackageModel

class MapPage extends StatelessWidget {
  final PackageModel paquete;

  const MapPage({super.key, required this.paquete});

  @override
  Widget build(BuildContext context) {
    // Si no tiene coordenadas, mostramos un mensaje.
    if (paquete.latDestino == null || paquete.lngDestino == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Mapa: ${paquete.codigoRastreo}'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Este paquete no tiene coordenadas de destino configuradas.\n'
              'Asigna lat_destino y lng_destino en la base de datos para verlo en el mapa.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final LatLng center =
        LatLng(paquete.latDestino!, paquete.lngDestino!);

    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa: ${paquete.codigoRastreo}'),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: 16,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: "com.example.paquexpress_app",
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: center,
                width: 60,
                height: 60,
                child: const Icon(
                  Icons.location_on,
                  size: 40,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
