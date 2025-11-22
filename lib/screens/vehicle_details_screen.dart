import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher
import '../models/document.dart' as app;
import '../models/vehicle.dart';
import '../providers/auth_provider.dart';
import '../services/vehicle_service.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final Vehicle vehicle;
  const VehicleDetailsScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  late Future<List<app.Document>> _documentsFuture;

  @override
  void initState() {
    super.initState();
    _documentsFuture = _fetchDocuments();
  }

  Future<List<app.Document>> _fetchDocuments() async {
    final token = await Provider.of<AuthProvider>(context, listen: false).user?.getIdToken();
    if (token == null) throw Exception('Not authenticated');
    return VehicleService.getDocuments(token, widget.vehicle.id);
  }

  void _refetchDocuments() {
    setState(() {
      _documentsFuture = _fetchDocuments();
    });
  }

  Future<void> _uploadDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'pdf', 'png'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      // TODO: Show a dialog to get document type and expiry date
      String documentType = "Licencia"; // Placeholder

      try {
        final token = await Provider.of<AuthProvider>(context, listen: false).user?.getIdToken();
        if (token == null) throw Exception('Not authenticated');

        await VehicleService.uploadDocument(
          token: token,
          vehicleId: widget.vehicle.id,
          documentType: documentType,
          file: file,
        );
        _refetchDocuments();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documento subido con éxito!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir documento: $e')),
        );
      }
    }
  }

  // Function to launch URL
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el documento: $urlString')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicle.nickname ?? '${widget.vehicle.make} ${widget.vehicle.model}'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Marca: ${widget.vehicle.make}', style: Theme.of(context).textTheme.titleMedium),
                Text('Modelo: ${widget.vehicle.model}', style: Theme.of(context).textTheme.titleMedium),
                if (widget.vehicle.year != null) Text('Año: ${widget.vehicle.year}', style: Theme.of(context).textTheme.titleMedium),
                if (widget.vehicle.licensePlate != null) Text('Matrícula: ${widget.vehicle.licensePlate}', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Documentos", style: Theme.of(context).textTheme.headlineSmall),
          ),
          Expanded(
            child: FutureBuilder<List<app.Document>>(
              future: _documentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No hay documentos para este vehículo."));
                }
                final documents = snapshot.data!;
                return ListView.builder(
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final doc = documents[index];
                    return ListTile(
                      title: Text(doc.documentType),
                      subtitle: Text('Subido el: ${doc.createdAt.toLocal().toString().split(' ')[0]}'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        if (doc.publicUrl != null) {
                          _launchURL(doc.publicUrl!);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('URL del documento no disponible.')),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadDocument,
        child: const Icon(Icons.upload_file),
        tooltip: 'Subir Documento',
      ),
    );
  }
}
