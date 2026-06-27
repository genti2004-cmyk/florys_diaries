import 'package:flutter/material.dart';

class DocumentCategory {
  const DocumentCategory({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

class DocumentCategories {
  const DocumentCategories._();

  static const flight = DocumentCategory(
    id: 'flight',
    label: 'Flugticket',
    icon: Icons.flight_takeoff_rounded,
  );
  static const train = DocumentCategory(
    id: 'train',
    label: 'Bahnticket',
    icon: Icons.train_rounded,
  );
  static const hotel = DocumentCategory(
    id: 'hotel',
    label: 'Hotel',
    icon: Icons.hotel_rounded,
  );
  static const car = DocumentCategory(
    id: 'car',
    label: 'Mietwagen',
    icon: Icons.directions_car_rounded,
  );
  static const passport = DocumentCategory(
    id: 'passport',
    label: 'Reisedokument',
    icon: Icons.badge_rounded,
  );
  static const pdf = DocumentCategory(
    id: 'pdf',
    label: 'PDF',
    icon: Icons.picture_as_pdf_rounded,
  );
  static const photo = DocumentCategory(
    id: 'photo',
    label: 'Foto/Screenshot',
    icon: Icons.photo_library_rounded,
  );
  static const note = DocumentCategory(
    id: 'note',
    label: 'Notiz',
    icon: Icons.notes_rounded,
  );
  static const other = DocumentCategory(
    id: 'other',
    label: 'Sonstiges',
    icon: Icons.description_rounded,
  );

  static const List<DocumentCategory> values = [
    flight,
    train,
    hotel,
    car,
    passport,
    pdf,
    photo,
    note,
    other,
  ];

  static DocumentCategory byId(String id) {
    return values.firstWhere(
      (category) => category.id == id,
      orElse: () => other,
    );
  }
}
