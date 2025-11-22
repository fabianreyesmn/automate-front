import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../providers/auth_provider.dart';
import '../services/vehicle_service.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _licensePlateCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = await authProvider.user?.getIdToken();

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error de autenticación.")),
      );
      setState(() => _loading = false);
      return;
    }

    try {
      final newVehicle = Vehicle(
        id: '', // El backend lo genera
        userId: '', // El backend lo asigna
        make: _makeCtrl.text,
        model: _modelCtrl.text,
        year: int.tryParse(_yearCtrl.text),
        nickname: _nicknameCtrl.text,
        licensePlate: _licensePlateCtrl.text,
        createdAt: DateTime.now(),
      );

      await VehicleService.addVehicle(token, newVehicle);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vehículo añadido con éxito")),
        );
        Navigator.of(context).pop(true); // Devuelve true para indicar éxito
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al añadir vehículo: $e")),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Añadir Vehículo"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _makeCtrl,
                decoration: const InputDecoration(labelText: "Marca"),
                validator: (value) => value!.isEmpty ? "Campo requerido" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _modelCtrl,
                decoration: const InputDecoration(labelText: "Modelo"),
                validator: (value) => value!.isEmpty ? "Campo requerido" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _yearCtrl,
                decoration: const InputDecoration(labelText: "Año"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nicknameCtrl,
                decoration: const InputDecoration(labelText: "Apodo (Ej: El Viajero)"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _licensePlateCtrl,
                decoration: const InputDecoration(labelText: "Matrícula"),
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text("Guardar Vehículo"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
