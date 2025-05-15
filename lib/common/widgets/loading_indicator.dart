import 'package:flutter/material.dart';
import 'package:app_mobile/common/utils/constants.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color color;

  const LoadingIndicator({
    Key? key,
    this.size = 40.0,
    this.color = kPrimaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(color),
          strokeWidth: 3.0,
        ),
      ),
    );
  }
}
