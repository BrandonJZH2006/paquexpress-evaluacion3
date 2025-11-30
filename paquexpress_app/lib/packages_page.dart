// lib/packages_page.dart
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'delivery_page.dart';

class PackagesPage extends StatefulWidget {
  final User user;

  const PackagesPage({super.key, required this.user});

  @override
  State<PackagesPage> createState() => _PackagesPageState();
}

class _PackagesPageState extends State<PackagesPage> {
  final ApiService _apiService = ApiService();
  late Future<List<PackageModel>> _futurePackages;

  @override
  void initState() {
    super.initState();
    _futurePackages = _apiService.getAssignedPackages(
      widget.user.idUsuario,
      widget.user.token, // 👈 AQUÍ PASAMOS EL TOKEN
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _futurePackages = _apiService.getAssignedPackages(
        widget.user.idUsuario,
        widget.user.token, // 👈 AQUÍ TAMBIÉN
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paquetes de ${widget.user.nombre}'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<PackageModel>>(
          future: _futurePackages,
          builder: (context, snapshot) {
            // ... (lo que ya tenías de lista)
            // esto ya lo dejaste bien antes
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error al cargar paquetes:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final paquetes = snapshot.data ?? [];

            if (paquetes.isEmpty) {
              return const Center(
                child: Text('No hay paquetes pendientes asignados.'),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: paquetes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final pkg = paquetes[index];

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(pkg.codigoRastreo),
                    subtitle: Text(pkg.direccionDestino),
                    trailing: Text(
                      pkg.estado,
                      style: TextStyle(
                        color: pkg.estado == 'pendiente'
                            ? Colors.orange
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DeliveryPage(
                            user: widget.user,
                            paquete: pkg,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
