import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

// --- Mock Data based on the React component ---
class Vehicle {
  final String id;
  final String make;
  final String model;
  final int year;
  final String licensePlate;
  final String imageUrl;

  Vehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.licensePlate,
    required this.imageUrl,
  });
}

enum DocumentType { insurance, registration, inspection }

class VehicleDocument {
  final String id;
  final String vehicleId;
  final DocumentType type;
  final DateTime expiryDate;
  final String fileName;

  VehicleDocument({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.expiryDate,
    required this.fileName,
  });

  String get typeAsString {
    return type.toString().split('.').last.capitalize();
  }
}

final List<Vehicle> mockVehicles = [
  Vehicle(id: 'v1', make: 'Toyota', model: 'Camry', year: 2021, licensePlate: 'ABC-123', imageUrl: 'https://picsum.photos/seed/camry/200/120'),
  Vehicle(id: 'v2', make: 'Honda', model: 'CR-V', year: 2022, licensePlate: 'XYZ-789', imageUrl: 'https://picsum.photos/seed/crv/200/120'),
];

final Map<String, List<VehicleDocument>> mockDocuments = {
  'v1': [
    VehicleDocument(id: 'd1', vehicleId: 'v1', type: DocumentType.insurance, expiryDate: DateTime(2024, 12, 31), fileName: 'insurance_policy.pdf'),
    VehicleDocument(id: 'd2', vehicleId: 'v1', type: DocumentType.registration, expiryDate: DateTime(2025, 5, 15), fileName: 'registration.pdf'),
  ],
  'v2': [
    VehicleDocument(id: 'd3', vehicleId: 'v2', type: DocumentType.insurance, expiryDate: DateTime(2025, 1, 20), fileName: 'honda_insurance.pdf'),
  ]
};
// --- End Mock Data ---

class DigitalGloveboxScreen extends StatefulWidget {
  const DigitalGloveboxScreen({super.key});

  @override
  State<DigitalGloveboxScreen> createState() => _DigitalGloveboxScreenState();
}

class _DigitalGloveboxScreenState extends State<DigitalGloveboxScreen> {
  Vehicle? _selectedVehicle = mockVehicles.first;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        Text('My Vehicles', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        ...mockVehicles.map((v) => VehicleCard(
              vehicle: v,
              isSelected: _selectedVehicle?.id == v.id,
              onSelect: () => setState(() => _selectedVehicle = v),
            )),
        
        if (_selectedVehicle != null) ...[
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Documents for ${_selectedVehicle!.model}', style: theme.textTheme.headlineSmall),
              TextButton.icon(
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Add'),
                onPressed: () {
                  // TODO: Implement Add Document Modal
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (mockDocuments[_selectedVehicle!.id]?.isNotEmpty ?? false)
            ...mockDocuments[_selectedVehicle!.id]!.map((doc) => DocumentItem(doc: doc))
          else
            const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No documents found for this vehicle.'),
            )),
        ],
      ],
    );
  }
}

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final bool isSelected;
  final VoidCallback onSelect;

  const VehicleCard({super.key, required this.vehicle, required this.isSelected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(vehicle.imageUrl, width: 100, height: 60, fit: BoxFit.cover),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${vehicle.make} ${vehicle.model}', style: Theme.of(context).textTheme.titleLarge),
                    Text('${vehicle.year} - ${vehicle.licensePlate}', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class DocumentItem extends StatelessWidget {
  final VehicleDocument doc;
  const DocumentItem({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(LucideIcons.fileText, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.typeAsString, style: Theme.of(context).textTheme.titleMedium),
                  Text('Expires: ${doc.expiryDate.toLocal().toString().split(' ')[0]}', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
    String capitalize() {
      return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
    }
}