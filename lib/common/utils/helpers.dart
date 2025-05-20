import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Adicione intl: ^0.18.1 ou superior no pubspec.yaml se não estiver lá

// Funções auxiliares comuns

// Formatar Data e Hora
String formatDateTime(DateTime dateTime) {
  return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
}
String formatPrice(double price) {
  final NumberFormat formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  return formatter.format(price);
}
String? validateRequiredField(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Este campo é obrigatório';
  }
  return null;
}

// Validar email
String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'O email é obrigatório';
  }
  final RegExp emailRegExp = RegExp(
    r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
  );
  if (!emailRegExp.hasMatch(value)) {
    return 'Digite um email válido';
  }
  return null;
}


// Mostrar SnackBar
void showSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
    ),
  );
}

// Exibir Diálogo de Confirmação
Future<bool?> showConfirmationDialog(
  BuildContext context,
  String title,
  String content,
) async {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () {
              Navigator.of(context).pop(false); // Retorna false
            },
          ),
          TextButton(
            child: const Text('Confirmar'),
            onPressed: () {
              Navigator.of(context).pop(true); // Retorna true
            },
          ),
        ],
      );
    },
  );
}

// Exibir Diálogo de Erro
Future<void> showErrorDialog(BuildContext context, String title, String message) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // O usuário deve tocar no botão para fechar
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(message),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

// Adicione outras funções auxiliares conforme necessário

