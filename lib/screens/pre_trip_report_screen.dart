import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PreTripReportScreen extends StatefulWidget {
  const PreTripReportScreen({super.key});

  @override
  State<PreTripReportScreen> createState() => _PreTripReportScreenState();
}

class _PreTripReportScreenState extends State<PreTripReportScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _origin;
  String? _destination;
  bool _loading = false;
  bool _smartLoading = false;
  String? _report;
  String? _smartSummary;

  Future<void> _generateReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      _loading = true;
      _report = null;
      _smartSummary = null;
    });

    try {
      // 1. Geocoding
      final List<Location> originLocations = await locationFromAddress(_origin!);
      final List<Location> destLocations = await locationFromAddress(_destination!);

      if (originLocations.isEmpty || destLocations.isEmpty) {
        throw Exception('No se pudo encontrar la ubicación para el origen o destino.');
      }

      final origin = originLocations.first;
      final dest = destLocations.first;

      // 2. Get Auth Token and Backend URL
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) {
        throw Exception('No estás autenticado.');
      }

      final backendUrl = dotenv.env['BACKEND_URL'];
      if (backendUrl == null) {
        throw Exception('La URL del backend no está configurada.');
      }

      // 3. Call Backend API
      final uri = Uri.parse('$backendUrl/api/pre-trip-report').replace(queryParameters: {
        'from_lat': origin.latitude.toString(),
        'from_lon': origin.longitude.toString(),
        'to_lat': dest.latitude.toString(),
        'to_lon': dest.longitude.toString(),
      });

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // 4. Process response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _report = data['report'];
        });
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Error del servidor: ${errorData['error'] ?? response.reasonPhrase}');
      }
    } catch (e) {
      final errorMessage = e.toString().replaceAll("Exception: ", "");
      setState(() {
        _report = 'Error al generar el reporte:\n$errorMessage';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _generateSmartSummary() {
    if (_report == null || _report!.startsWith('Error')) return;
    
    setState(() => _smartLoading = true);
    
    // Simulación de la llamada a la API de IA
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        final hasRain = _report!.toLowerCase().contains('lluvia');
        final hasSnow = _report!.toLowerCase().contains('nieve');
        
        String weatherAdvice = "";
        if(hasRain) weatherAdvice = "Parece que lloverá, así que maneja con cuidado.";
        if(hasSnow) weatherAdvice = "Hay pronóstico de nieve, toma precauciones adicionales en el camino.";

        _smartSummary = "¡Todo listo para tu viaje a $_destination! "
            "El camino es de aproximadamente ${_getMetricFromReport('Distancia') ?? 'varios'} km "
            "y te tomará alrededor de ${_getMetricFromReport('Duración estimada') ?? 'un tiempo'}. "
            "$weatherAdvice ¡Buen viaje!";
        _smartLoading = false;
      });
    });
  }

  String? _getMetricFromReport(String metricName) {
    if (_report == null) return null;
    // Usamos una 'raw string' (r'...') para evitar problemas con el caracter '$'
    final regex = RegExp(r'$metricName: (.*?)(?=\n|$)');
    final match = regex.firstMatch(_report!);
    return match?.group(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Reporte Pre-Viaje', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Planifica tu ruta con datos de clima y viaje.'),
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Origen',
                  hintText: 'Ej: Tu casa',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.mapPin),
                ),
                onSaved: (value) => _origin = value,
                validator: (value) => (value == null || value.isEmpty) ? 'Ingresa un origen' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Destino',
                  hintText: 'Ej: Oficina',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.flag),
                ),
                onSaved: (value) => _destination = value,
                validator: (value) => (value == null || value.isEmpty) ? 'Ingresa un destino' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(LucideIcons.fileText),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: theme.textTheme.titleMedium,
                  ),
                  onPressed: _loading ? null : _generateReport,
                  label: _loading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3)) : const Text('Generar Reporte'),
                ),
              ),
            ],
          ),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
            child: Center(child: Text('Analizando ruta y clima...', style: TextStyle(color: Colors.grey))),
          ),
        if (_report != null)
          Card(
            elevation: 0,
            color: Colors.blue.withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.blue.withOpacity(0.2)),
            ),
            margin: const EdgeInsets.only(top: 24),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tu Reporte de Viaje', style: theme.textTheme.titleLarge?.copyWith(color: Colors.blue[800])),
                  const SizedBox(height: 16),
                  Text(_report!, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _smartLoading ? const SizedBox.shrink() : const Icon(LucideIcons.sparkles, size: 18),
                      label: _smartLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3)) : const Text('Generar Resumen Inteligente'),
                      onPressed: _smartLoading ? null : _generateSmartSummary,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        textStyle: theme.textTheme.titleMedium,
                      ),
                    ),
                  ),
                  if (_smartSummary != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Row(
                              children: [
                                Icon(LucideIcons.sparkles, size: 18, color: Colors.purple[900]),
                                const SizedBox(width: 8),
                                Text("Resumen Inteligente", style: theme.textTheme.titleMedium?.copyWith(color: Colors.purple[900], fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(_smartSummary!, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.purple[900], height: 1.4)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}