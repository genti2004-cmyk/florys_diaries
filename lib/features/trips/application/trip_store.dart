import 'package:flutter/foundation.dart';

import 'package:florys_diaries/features/album/domain/trip_album_entry.dart';
import 'package:florys_diaries/features/documents/domain/document_category.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';

import '../data/trip_storage_service.dart';
import '../domain/trip.dart';

class TripStore extends ChangeNotifier {
  TripStore({TripStorageService storageService = const TripStorageService()})
      : _storageService = storageService;

  final TripStorageService _storageService;
  final List<Trip> _trips = [];
  bool _isLoading = true;

  bool get isLoading => _isLoading;

  List<Trip> get trips => List.unmodifiable(_sorted(_trips));

  List<Trip> get upcomingTrips {
    return trips.where((trip) => !trip.isPast).toList(growable: false);
  }

  List<Trip> get pastTrips {
    return trips.where((trip) => trip.isPast).toList(growable: false);
  }

  Future<void> load() async {
    final hasSavedTrips = await _storageService.hasSavedTrips();
    final savedTrips = await _storageService.loadTrips();
    _trips
      ..clear()
      ..addAll(hasSavedTrips ? savedTrips : _initialTrips());
    _isLoading = false;
    notifyListeners();

    if (!hasSavedTrips) {
      await _save();
    }
  }

  Future<void> reloadFromStorage() async {
    final savedTrips = await _storageService.loadTrips();
    _trips
      ..clear()
      ..addAll(savedTrips);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTrip(Trip trip) async {
    _trips.add(trip);
    notifyListeners();
    await _save();
  }

  Future<void> updateTrip(Trip trip) async {
    final index = _trips.indexWhere((item) => item.id == trip.id);
    if (index == -1) {
      return;
    }
    _trips[index] = trip;
    notifyListeners();
    await _save();
  }

  Future<void> deleteTrip(String id) async {
    _trips.removeWhere((trip) => trip.id == id);
    notifyListeners();
    await _save();
  }

  String createId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> _save() {
    return _storageService.saveTrips(_sorted(_trips));
  }

  static List<Trip> _sorted(List<Trip> source) {
    final items = List<Trip>.from(source);
    items.sort((a, b) => a.startDate.compareTo(b.startDate));
    return items;
  }

  static List<Trip> _initialTrips() {
    final now = DateTime.now();
    return [
      Trip(
        id: 'sample-paris',
        title: 'Sommer in Paris',
        destination: 'Paris',
        country: 'Frankreich',
        startDate: DateTime(now.year, now.month + 1, 12),
        endDate: DateTime(now.year, now.month + 1, 18),
        notes: 'Hotel, Flugticket und Metro-Plan später hier ablegen.',
        albumEntries: [
          TripAlbumEntry(
            id: 'sample-paris-note',
            typeId: TripAlbumEntryTypes.note.id,
            date: DateTime(now.year, now.month + 1, 12),
            title: 'Ankunft in Paris',
            location: 'Paris',
            description: 'Eiffelturm und Abendspaziergang als erstes Highlight planen.',
          ),
          TripAlbumEntry(
            id: 'sample-paris-highlight',
            typeId: TripAlbumEntryTypes.highlight.id,
            date: DateTime(now.year, now.month + 1, 14),
            title: 'Lieblingsmoment vormerken',
            location: 'Montmartre',
            description: 'Hier später den schönsten Moment der Reise festhalten.',
            isFavorite: true,
          ),
        ],
        documents: [
          TravelDocument(
            id: 'sample-paris-flight',
            title: 'Flugticket Lufthansa',
            categoryId: DocumentCategories.flight.id,
            createdAt: DateTime(now.year, now.month, now.day),
            description: 'Frankfurt → Paris, Buchungsnummer später ergänzen.',
            fileName: 'flugticket_paris.pdf',
          ),
          TravelDocument(
            id: 'sample-paris-hotel',
            title: 'Hotelbestätigung',
            categoryId: DocumentCategories.hotel.id,
            createdAt: DateTime(now.year, now.month, now.day),
            description: 'Check-in Daten und Adresse sichern.',
            fileName: 'hotel_paris.pdf',
          ),
        ],
        photoCount: 0,
      ),
      Trip(
        id: 'sample-rome',
        title: 'Rom Wochenende',
        destination: 'Rom',
        country: 'Italien',
        startDate: DateTime(now.year - 1, 9, 6),
        endDate: DateTime(now.year - 1, 9, 10),
        notes: 'Kolosseum, Trastevere und Vatikan besucht.',
        albumEntries: [
          TripAlbumEntry(
            id: 'sample-rome-highlight',
            typeId: TripAlbumEntryTypes.highlight.id,
            date: DateTime(now.year - 1, 9, 7),
            title: 'Sonnenuntergang am Kolosseum',
            location: 'Rom',
            description: 'Warmer Abend, gute Fotos und Spaziergang Richtung Trastevere.',
            isFavorite: true,
          ),
          TripAlbumEntry(
            id: 'sample-rome-food',
            typeId: TripAlbumEntryTypes.food.id,
            date: DateTime(now.year - 1, 9, 8),
            title: 'Pasta in Trastevere',
            location: 'Trastevere',
            description: 'Restaurant später mit Namen ergänzen.',
          ),
        ],
        documents: [
          TravelDocument(
            id: 'sample-rome-ticket',
            title: 'Kolosseum Ticket',
            categoryId: DocumentCategories.pdf.id,
            createdAt: DateTime(now.year - 1, 9, 1),
            description: 'Eintritt und Zeitfenster als PDF gesichert.',
            fileName: 'kolosseum_ticket.pdf',
          ),
        ],
        photoCount: 24,
      ),
    ];
  }
}
