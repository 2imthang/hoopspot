import 'package:flutter/material.dart';

/// Hiệu ứng "shimmer" (ánh sáng quét qua) dùng chung cho mọi màn hình đang
/// tải (TASK-036) — bọc quanh 1 layout gồm các [SkeletonBox] để giả hình
/// dạng nội dung thật, không cần thêm package ngoài (`shimmer`), chỉ dùng
/// `AnimationController` + `ShaderMask` sẵn có trong Flutter.
class Shimmer extends StatefulWidget {
  final Widget child;

  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.onSurface;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              base.withValues(alpha: 0.06),
              base.withValues(alpha: 0.16),
              base.withValues(alpha: 0.06),
            ],
            stops: const [0.0, 0.5, 1.0],
            begin: Alignment(-1 - t * 2, 0),
            end: Alignment(1 - t * 2, 0),
          ).createShader(bounds),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// 1 khối xám bo góc — viên gạch cơ bản để dựng khung xương giả nội dung.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadiusGeometry borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        borderRadius: borderRadius,
      ),
    );
  }
}

/// Khung xương giả 1 [CourtCard] (ảnh 16:9 + 3 dòng chữ) — dùng cho
/// Home/Search/Favorites, những màn hiển thị danh sách sân dạng ảnh lớn.
class SkeletonCourtCard extends StatelessWidget {
  const SkeletonCourtCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AspectRatio(aspectRatio: 16 / 9, child: SkeletonBox(borderRadius: BorderRadius.zero)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 160, height: 16),
                const SizedBox(height: 8),
                const SkeletonBox(width: 220, height: 12),
                const SizedBox(height: 10),
                const SkeletonBox(width: 120, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Khung xương giả 1 thẻ danh sách "phẳng" (title + badge + 1-2 dòng phụ)
/// — hình dạng chung cho Booking History/Owner Courts/Owner Bookings/
/// Notifications/mọi màn Admin, khác [SkeletonCourtCard] ở chỗ không có
/// khối ảnh lớn phía trên.
class SkeletonListCard extends StatelessWidget {
  const SkeletonListCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonBox(width: 140, height: 16),
              const Spacer(),
              SkeletonBox(width: 70, height: 20, borderRadius: BorderRadius.circular(20)),
            ],
          ),
          const SizedBox(height: 10),
          const SkeletonBox(width: 200, height: 12),
        ],
      ),
    );
  }
}

/// Danh sách N khung xương giống nhau, bọc trong 1 [Shimmer] chung (không
/// cần mỗi item tự chạy animation riêng). [SkeletonCourtCard] tự có margin
/// dưới nên không cần [spacing] thêm; [SkeletonListCard] thì cần.
class SkeletonList extends StatelessWidget {
  final Widget Function() itemBuilder;
  final int count;
  final EdgeInsetsGeometry padding;
  final double spacing;

  const SkeletonList({
    super.key,
    required this.itemBuilder,
    this.count = 3,
    this.padding = const EdgeInsets.all(16),
    this.spacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0 && spacing > 0) SizedBox(height: spacing),
            itemBuilder(),
          ],
        ],
      ),
    );
  }
}
