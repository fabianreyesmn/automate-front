class Document {
  final String id;
  final String vehicleId;
  final String documentType;
  final String storagePath;
  final String? publicUrl;
  final DateTime? expiryDate;
  final DateTime createdAt;

  Document({
    required this.id,
    required this.vehicleId,
    required this.documentType,
    required this.storagePath,
    this.publicUrl,
    this.expiryDate,
    required this.createdAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      vehicleId: json['vehicle_id'],
      documentType: json['document_type'],
      storagePath: json['storage_path'],
      publicUrl: json['public_url'],
      expiryDate: json['expiry_date'] != null ? DateTime.parse(json['expiry_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
