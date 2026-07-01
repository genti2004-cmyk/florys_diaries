import 'package:florys_diaries/features/trips/domain/trip.dart';

class TripTemplate {
  const TripTemplate({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.sourceTrip,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final Trip sourceTrip;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'sourceTrip': sourceTrip.toJson(),
    };
  }

  static TripTemplate fromJson(Map<String, dynamic> json) {
    final rawTrip = json['sourceTrip'];
    return TripTemplate(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.now(),
      sourceTrip: rawTrip is Map<String, dynamic>
          ? Trip.fromJson(rawTrip)
          : Trip(
              id: 'invalid',
              title: '',
              destination: '',
              country: '',
              startDate: DateTime.now(),
              endDate: DateTime.now(),
            ),
    );
  }
}
