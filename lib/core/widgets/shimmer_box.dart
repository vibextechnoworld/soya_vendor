import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:soya_app/util/colors.dart';

class ShimmerBox extends StatelessWidget {
  final double height;
  final double width;
  final double radius;

  const ShimmerBox({
    super.key,
    required this.height,
    required this.width,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: greyColorOpacity4,
      highlightColor: greyColorOpacity2,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
