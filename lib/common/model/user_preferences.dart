import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart'; // Para ThemeMode

// Representa as preferências do usuário armazenadas localmente.
class UserPreferences extends Equatable {
  final ThemeMode themeMode; // Ex: ThemeMode.light, ThemeMode.dark, ThemeMode.system
  // Adicione outras preferências conforme necessário
  // final bool showNotifications;
  // final String preferredLanguage;

  const UserPreferences({
    required this.themeMode,
    // this.showNotifications = true,
    // this.preferredLanguage = 'pt',
  });

  // Construtor padrão com valores iniciais
  factory UserPreferences.initial() {
    return const UserPreferences(
      themeMode: ThemeMode.system, // Padrão do sistema
    );
  }

  // Método copyWith para facilitar atualizações imutáveis
  UserPreferences copyWith({
    ThemeMode? themeMode,
    // bool? showNotifications,
    // String? preferredLanguage,
  }) {
    return UserPreferences(
      themeMode: themeMode ?? this.themeMode,
      // showNotifications: showNotifications ?? this.showNotifications,
      // preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }

  @override
  List<Object?> get props => [
        themeMode,
        // showNotifications,
        // preferredLanguage,
      ];
}

