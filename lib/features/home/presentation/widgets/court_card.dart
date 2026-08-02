import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../court/domain/entities/court_entity.dart';

/// Reused by Home and Search & Filter to render one court in the list.
/// Distance is shown as a fixed "--" placeholder for now — real GPS-based
/// distance is wired up later when Google Maps is integrated (TASK-017).
class CourtCard extends StatelessWidget {
  final CourtEntity court;
  final VoidCallback? onTap;

  const CourtCard({super.key, required this.court, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(aspectRatio: 16 / 9, child: _CourtImage(court: court)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    court.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    court.address,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '-- km · ${formatVnd(court.pricePerSlot)}/giờ',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (court.isOutdoor) ...[
                        const SizedBox(width: 8),
                        _OutdoorChip(),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourtImage extends StatelessWidget {
  final CourtEntity court;

  const _CourtImage({required this.court});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (court.imageUrls.isEmpty) {
      return _placeholder(theme, Icons.image_outlined);
    }
    return Image.network(
      court.imageUrls.first,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _placeholder(theme, Icons.broken_image_outlined),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _placeholder(theme, null);
      },
    );
  }

  Widget _placeholder(ThemeData theme, IconData? icon) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: icon == null
          ? null
          : Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
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
