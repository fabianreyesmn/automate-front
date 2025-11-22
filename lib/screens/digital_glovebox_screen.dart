import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../providers/auth_provider.dart';
import '../services/vehicle_service.dart';

class DigitalGloveboxScreen extends StatefulWidget {
  const DigitalGloveboxScreen({super.key});

  @override
  State<DigitalGloveboxScreen> createState() => _DigitalGloveboxScreenState();
}

class _DigitalGloveboxScreenState extends State<DigitalGloveboxScreen> {
  late Future<List<Vehicle>> _vehiclesFuture;

  @override
  void initState() {
    super.initState();
    _vehiclesFuture = _fetchVehicles();
  }

  Future<List<Vehicle>> _fetchVehicles() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = await authProvider.user?.getIdToken();
    if (token == null) {
      // This should not happen if we are on this screen, due to router redirects
      throw Exception('Not authenticated');
    }
    return VehicleService.getVehicles(token);
  }

  void _refreshVehicles() {
    setState(() {
      _vehiclesFuture = _fetchVehicles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Guantera Digital"),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Vehicle>>(
        future: _vehiclesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("Error al cargar vehículos: ${snapshot.error}"),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No tienes vehículos todavía.\n¡Añade uno para empezar!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final vehicles = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(vehicle.nickname ?? '${vehicle.make} ${vehicle.model}'),
                  subtitle: Text(vehicle.licensePlate ?? 'Sin matrícula'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    context.push('/vehicle-details', extra: vehicle);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push('/add-vehicle');
          if (result == true) {
            _refreshVehicles();
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Añadir Vehículo',
      ),
    );
  }
}
