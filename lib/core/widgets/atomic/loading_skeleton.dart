import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/dimensions.dart';

class LoadingSkeleton extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;
  const LoadingSkeleton({super.key, this.height = 16, this.width, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: scheme.surfaceContainerHighest.withOpacity(.3),
      highlightColor: scheme.surface.withOpacity(.7),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: borderRadius ?? BorderRadius.circular(AppDimens.radiusS),
        ),
      ),
    );
  }
}
