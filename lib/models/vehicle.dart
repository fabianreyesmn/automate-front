class Vehicle {
  final String id;
  final String userId;
  final String make;
  final String model;
  final int? year;
  final String? licensePlate;
  final String? nickname;
  final DateTime createdAt;

  Vehicle({
    required this.id,
    required this.userId,
    required this.make,
    required this.model,
    this.year,
    this.licensePlate,
    this.nickname,
    required this.createdAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      userId: json['user_id'],
      make: json['make'],
      model: json['model'],
      year: json['year'],
      licensePlate: json['license_plate'],
      nickname: json['nickname'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'make': make,
      'model': model,
      'year': year,
      'license_plate': licensePlate,
      'nickname': nickname,
    };
  }
}
