class AppointmentPublic {
  final String id;
  final String clientName;
  final String destinationAddress;
  final double roundtripDistance;
  final DateTime appointmentDate;

  AppointmentPublic({
    required this.id,
    required this.clientName,
    required this.destinationAddress,
    required this.roundtripDistance,
    required this.appointmentDate,
  });

  factory AppointmentPublic.fromJson(Map<String, dynamic> json) {
    return AppointmentPublic(
      id: json['id'],
      clientName: json['client_name'],
      destinationAddress: json['destination_address'].toString().toUpperCase(),
      roundtripDistance: (json['roundtrip_distance'] as num).toDouble(),
      appointmentDate: DateTime.parse(json['appointment_date']),
    );
  }
}
