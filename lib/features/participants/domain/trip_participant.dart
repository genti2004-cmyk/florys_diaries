class TripParticipant {
  const TripParticipant({required this.id, required this.name});

  final String id;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  static TripParticipant fromJson(Map<String, dynamic> json) {
    return TripParticipant(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
    );
  }

  TripParticipant copyWith({String? id, String? name}) {
    return TripParticipant(id: id ?? this.id, name: name ?? this.name);
  }
}
