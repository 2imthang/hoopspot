import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../booking/presentation/pages/booking_slots_page.dart';
import '../../../favorite/presentation/widgets/favorite_button.dart';
import '../../../review/domain/entities/review_entity.dart';
import '../../domain/entities/court_entity.dart';
import '../bloc/court_detail_cubit.dart';

class CourtDetailPage extends StatelessWidget {
  final String courtId;

  const CourtDetailPage({super.key, required this.courtId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CourtDetailCubit>()..loadCourt(courtId),
      child: const _CourtDetailView(),
    );
  }
}

class _CourtDetailView extends StatelessWidget {
  const _CourtDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: BlocBuilder<CourtDetailCubit, CourtDetailState>(
          builder: (context, state) {
            if (state is CourtDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CourtDetailError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.message, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Quay lại'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final loaded = state as CourtDetailLoaded;
            return _CourtDetailBody(court: loaded.court, state: loaded);
          },
        ),
      ),
    );
  }
}

class _CourtDetailBody extends StatelessWidget {
  final CourtEntity court;
  final CourtDetailLoaded state;

  const _CourtDetailBody({required this.court, required this.state});

  Future<void> _openDirections(BuildContext context) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${court.latitude},${court.longitude}',
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được Google Maps')),
      );
    }
  }

  void _onBookPressed(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookingSlotsPage(court: court)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _ImageCarousel(courtId: court.id, imageUrls: court.imageUrls),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            court.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (state.reviews.isNotEmpty) ...[
                          const Icon(Icons.star, size: 18, color: Colors.orange),
                          const SizedBox(width: 2),
                          Text(
                            '${state.averageRating.toStringAsFixed(1)} (${state.reviews.length})',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            court.address,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${formatVnd(court.pricePerSlot)}/giờ',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (court.isOutdoor) ...[
                          const SizedBox(width: 8),
                          _OutdoorChip(),
                        ],
                      ],
                    ),
                    if (court.amenities.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: court.amenities
                            .map((a) => _AmenityChip(label: a))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      'Đánh giá',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (state.reviews.isEmpty)
                      Text(
                        'Chưa có đánh giá nào',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      Column(
                        children: state.reviews
                            .map((review) => _ReviewCard(review: review))
                            .toList(),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      'Vị trí',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _MapPreview(court: court),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _openDirections(context),
                      icon: const Icon(Icons.directions_outlined),
                      label: const Text('Chỉ đường'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _BottomBookBar(
          pricePerSlot: court.pricePerSlot,
          onBookPressed: () => _onBookPressed(context),
        ),
      ],
    );
  }
}

class _ImageCarousel extends StatefulWidget {
  final String courtId;
  final List<String> imageUrls;

  const _ImageCarousel({required this.courtId, required this.imageUrls});

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: widget.imageUrls.isEmpty
              ? _placeholder(theme)
              : PageView.builder(
                  controller: _pageController,
                  itemCount: widget.imageUrls.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) => Image.network(
                    widget.imageUrls[i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _placeholder(theme),
                  ),
                ),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: _CircleIconButton(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: FavoriteButton(courtId: widget.courtId),
        ),
        if (widget.imageUrls.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.imageUrls.length; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _page
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surface.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        size: 56,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircleIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.black45,
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewEntity review;

  const _ReviewCard({required this.review});

  String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              _initialsOf(review.userName),
              style: TextStyle(color: theme.colorScheme.onPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      review.userName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < review.rating ? Icons.star : Icons.star_border,
                          size: 14,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                if (review.comment.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(review.comment, style: theme.textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmenityChip extends StatelessWidget {
  final String label;

  const _AmenityChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _OutdoorChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Ngoài trời',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

/// Non-interactive OpenStreetMap preview via flutter_map — no API key/card
/// needed, unlike embedding Google Maps SDK. "Chỉ đường" below opens the
/// real Google Maps app for actual navigation.
class _MapPreview extends StatelessWidget {
  final CourtEntity court;

  const _MapPreview({required this.court});

  @override
  Widget build(BuildContext context) {
    final center = latlong.LatLng(court.latitude, court.longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 160,
        child: IgnorePointer(
          child: FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 15),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.hoop_spot',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: center,
                    child: Icon(
                      Icons.location_on,
                      color: Theme.of(context).colorScheme.primary,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBookBar extends StatelessWidget {
  final int pricePerSlot;
  final VoidCallback onBookPressed;

  const _BottomBookBar({
    required this.pricePerSlot,
    required this.onBookPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Giá', style: theme.textTheme.bodySmall),
                  Text(
                    '${formatVnd(pricePerSlot)}/giờ',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(onPressed: onBookPressed, child: const Text('Đặt sân')),
          ],
        ),
      ),
    );
  }
}
