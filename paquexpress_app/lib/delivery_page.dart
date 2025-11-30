// lib/delivery_page.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

import 'api_service.dart';
import 'map_page.dart';

class DeliveryPage extends StatefulWidget {
  final User user;
  final PackageModel paquete;

  const DeliveryPage({
    super.key,
    required this.user,
    required this.paquete,
  });

  @override
  State<DeliveryPage> createState() => _DeliveryPageState();
}

class _DeliveryPageState extends State<DeliveryPage> {
  final ApiService _apiService = ApiService();

  Uint8List? _fotoBytes;
  String? _fotoName;
  Position? _posicion;
  bool _sending = false;
  final _obsCtrl = TextEditingController();

  // ======================
  // 1. TOMAR FOTO
  // ======================
  Future<void> _tomarFoto() async {
    final picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 75);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _fotoBytes = bytes;
        _fotoName = image.name.isNotEmpty ? image.name : 'evidencia.jpg';
      });
    }
  }

  // ======================
  // 2. OBTENER GPS
  // ======================
  Future<void> _obtenerGPS() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Activa tu GPS para continuar.")),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Permiso de GPS denegado.")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Ve a configuración y activa los permisos de ubicación.")),
      );
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _posicion = pos;
    });
  }

  // ======================
  // 3. ENVIAR ENTREGA
  // ======================
  Future<void> _enviarEntrega() async {
    if (_fotoBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes tomar una foto primero.")),
      );
      return;
    }

    if (_posicion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes obtener tu GPS primero.")),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      final ok = await _apiService.registrarEntrega(
        idUsuario: widget.user.idUsuario,
        idPaquete: widget.paquete.idPaquete,
        lat: _posicion!.latitude,
        lng: _posicion!.longitude,
        observaciones: _obsCtrl.text,
        fileBytes: _fotoBytes!,
        fileName: _fotoName ?? 'evidencia.jpg',
        token: widget.user.token,
      );

      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Entrega registrada con éxito.")),
        );

        Navigator.pop(context); // regresa a la lista de paquetes
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al registrar entrega: $e")),
      );
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Entrega: ${widget.paquete.codigoRastreo}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Foto tomada
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey[300],
              child: _fotoBytes == null
                  ? const Center(
                      child: Text("No hay foto aún"),
                    )
                  : Image.memory(
                      _fotoBytes!,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _tomarFoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Tomar foto"),
            ),

            const SizedBox(height: 20),
            // GPS
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: _posicion == null ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _posicion == null
                        ? "Ubicación no capturada"
                        : "Lat: ${_posicion!.latitude}, Lng: ${_posicion!.longitude}",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _obtenerGPS,
              icon: const Icon(Icons.gps_fixed),
              label: const Text("Obtener GPS"),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _obsCtrl,
              decoration: const InputDecoration(
                labelText: "Observaciones (opcional)",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MapPage(paquete: widget.paquete),
                    ),
                  );
                },
                icon: const Icon(Icons.map),
                label: const Text("Ver dirección en mapa"),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sending ? null : _enviarEntrega,
                icon: const Icon(Icons.check),
                label: _sending
                    ? const CircularProgressIndicator()
                    : const Text("Registrar entrega"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
