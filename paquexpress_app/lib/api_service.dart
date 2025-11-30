// lib/api_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

const String baseUrl = "http://127.0.0.1:8000";

class User {
  final int idUsuario;
  final String nombre;
  final String email;
  final String rol;
  final String token;

  User({
    required this.idUsuario,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      idUsuario: json['id_usuario'],
      nombre: json['nombre'],
      email: json['email'],
      rol: json['rol'],
      token: json['access_token'], // JWT
    );
  }
}

class PackageModel {
  final int idPaquete;
  final String codigoRastreo;
  final String direccionDestino;
  final String estado;
  final double? latDestino;
  final double? lngDestino;

  PackageModel({
    required this.idPaquete,
    required this.codigoRastreo,
    required this.direccionDestino,
    required this.estado,
    this.latDestino,
    this.lngDestino,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      idPaquete: json['id_paquete'],
      codigoRastreo: json['codigo_rastreo'],
      direccionDestino: json['direccion_destino'],
      estado: json['estado'],
      latDestino: json['lat_destino'] != null
          ? (json['lat_destino'] as num).toDouble()
          : null,
      lngDestino: json['lng_destino'] != null
          ? (json['lng_destino'] as num).toDouble()
          : null,
    );
  }
}

class ApiService {
  // LOGIN
  Future<User> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data);
    } else {
      final data = jsonDecode(response.body);
      final detail = data['detail'] ?? 'Error desconocido';
      throw Exception('Error al iniciar sesión: $detail');
    }
  }

  // OBTENER PAQUETES ASIGNADOS (usa token)
  Future<List<PackageModel>> getAssignedPackages(
      int idUsuario, String token) async {
    final url = Uri.parse('$baseUrl/paquetes/asignados/$idUsuario');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((json) => PackageModel.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener paquetes asignados');
    }
  }

  // REGISTRAR ENTREGA (FOTO + GPS) usando BYTES (soporta Web)
  Future<bool> registrarEntrega({
    required int idUsuario,
    required int idPaquete,
    required double lat,
    required double lng,
    required String? observaciones,
    required Uint8List fileBytes,
    required String fileName,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/entregas/');

    final request = http.MultipartRequest('POST', url);

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['id_usuario'] = idUsuario.toString();
    request.fields['id_paquete'] = idPaquete.toString();
    request.fields['lat'] = lat.toString();
    request.fields['lng'] = lng.toString();
    request.fields['observaciones'] = observaciones ?? '';

    request.files.add(
      http.MultipartFile.fromBytes(
        'foto',
        fileBytes,
        filename: fileName,
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      return true;
    } else {
      print(response.body);
      throw Exception("Error al registrar la entrega");
    }
  }
}
