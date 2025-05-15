import 'package:flutter/material.dart';

import 'package:app_mobile/common/utils/constants.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final Color textColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isLoading;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.color = kPrimaryColor,
    this.textColor = Colors.white,
    this.borderRadius = 8.0,
    this.padding = const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: padding,
      ),
      onPressed:
          isLoading ? null : onPressed, // Desabilita o botão durante o loading
      child: isLoading
          ? const SizedBox(
              height: 20.0, // Ajuste a altura conforme necessário
              width: 20.0, // Ajuste a largura conforme necessário
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2.0,
              ),
            )
          : Text(
              text,
              style: TextStyle(color: textColor, fontSize: 16),
            ),
    );
  }
}
