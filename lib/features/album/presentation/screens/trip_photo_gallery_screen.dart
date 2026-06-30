import 'dart:io';

import 'package:flutter/material.dart';

import 'package:florys_diaries/features/documents/data/travel_file_service.dart';
import 'package:florys_diaries/features/documents/domain/travel_document.dart';

class TripPhotoGalleryScreen extends StatefulWidget {
  const TripPhotoGalleryScreen({
    required this.photos,
    this.initialIndex = 0,
    super.key,
  });

  final List<TravelDocument> photos;
  final int initialIndex;

  @override
  State<TripPhotoGalleryScreen> createState() =>
      _TripPhotoGalleryScreenState();
}

class _TripPhotoGalleryScreenState extends State<TripPhotoGalleryScreen> {
  static const TravelFileService _fileService = TravelFileService();

  late final PageController _pageController;
  late final Future<List<File?>> _filesFuture;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    final maxIndex = widget.photos.isEmpty ? 0 : widget.photos.length - 1;
    _currentIndex = widget.initialIndex < 0
        ? 0
        : (widget.initialIndex > maxIndex ? maxIndex : widget.initialIndex);
    _pageController = PageController(initialPage: _currentIndex);
    _filesFuture = _resolveFiles();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<List<File?>> _resolveFiles() {
    return Future.wait(
      widget.photos.map(_fileService.resolveDocumentFile),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Keine Fotos vorhanden.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final currentPhoto = widget.photos[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reisefotos'),
            Text(
              '${_currentIndex + 1} von ${widget.photos.length}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<File?>>(
        future: _filesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final files = snapshot.data ?? const <File?>[];

          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.photos.length,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final file = index < files.length ? files[index] : null;
                    return _GalleryPage(file: file);
                  },
                ),
              ),
              _GalleryInfoBar(
                photo: currentPhoto,
                currentIndex: _currentIndex,
                totalCount: widget.photos.length,
              ),
              _ThumbnailStrip(
                photos: widget.photos,
                files: files,
                selectedIndex: _currentIndex,
                onSelected: (index) {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GalleryPage extends StatelessWidget {
  const _GalleryPage({required this.file});

  final File? file;

  @override
  Widget build(BuildContext context) {
    if (file == null || !file!.existsSync()) {
      return const _MissingPhoto();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: InteractiveViewer(
        minScale: 0.8,
        maxScale: 5,
        boundaryMargin: const EdgeInsets.all(40),
        child: Center(
          child: Image.file(
            file!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const _MissingPhoto();
            },
          ),
        ),
      ),
    );
  }
}

class _GalleryInfoBar extends StatelessWidget {
  const _GalleryInfoBar({
    required this.photo,
    required this.currentIndex,
    required this.totalCount,
  });

  final TravelDocument photo;
  final int currentIndex;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final title = photo.title.trim().isEmpty
        ? 'Foto ${currentIndex + 1}'
        : photo.title.trim();
    final fileName = photo.fileName.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (fileName.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            child: Text(
              '${currentIndex + 1}/$totalCount',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThumbnailStrip extends StatelessWidget {
  const _ThumbnailStrip({
    required this.photos,
    required this.files,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<TravelDocument> photos;
  final List<File?> files;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 84,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          scrollDirection: Axis.horizontal,
          itemCount: photos.length,
          separatorBuilder: (context, index) => const SizedBox(width: 9),
          itemBuilder: (context, index) {
            final file = index < files.length ? files[index] : null;
            final selected = index == selectedIndex;

            return GestureDetector(
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 62,
                decoration: BoxDecoration(
                  color: const Color(0xFF161616),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? Colors.white : Colors.white24,
                    width: selected ? 2.5 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: file != null && file.existsSync()
                    ? Image.file(
                        file,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const _ThumbnailPlaceholder();
                        },
                      )
                    : const _ThumbnailPlaceholder(),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MissingPhoto extends StatelessWidget {
  const _MissingPhoto();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, size: 64, color: Colors.white54),
          SizedBox(height: 12),
          Text(
            'Dieses Foto konnte nicht geladen werden.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF202020),
      child: Center(
        child: Icon(Icons.image_outlined, color: Colors.white54),
      ),
    );
  }
}
