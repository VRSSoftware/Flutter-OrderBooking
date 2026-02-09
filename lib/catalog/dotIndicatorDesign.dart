
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vrs_erp/constants/app_constants.dart';

class DotIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;

  const DotIndicator({
    required this.count,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: currentIndex == index ? 10 : 6,
          height: currentIndex == index ? 10 : 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentIndex == index
                ? Colors.green
                : Colors.grey.withOpacity(0.5),
          ),
        );
      }),
    );
  }
}