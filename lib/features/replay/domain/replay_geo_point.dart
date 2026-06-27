class ReplayGeoPoint {
  const ReplayGeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  bool get isValid {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  bool isSameAs(ReplayGeoPoint other) {
    return latitude == other.latitude && longitude == other.longitude;
  }
}
