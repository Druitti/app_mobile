import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_mobile/common/utils/constants.dart';
import 'package:app_mobile/common/utils/failures.dart';
import 'package:dartz/dartz.dart';
// <----- iniciando alteração
import 'package:app_mobile/services/location_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
// <----- finalizando alteração

class CameraService {
  static final CameraService _instance = CameraService._internal();
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  // <----- iniciando alteração
  final LocationService _locationService = LocationService();
  // <----- finalizando alteração

  factory CameraService() => _instance;

  CameraService._internal();

  Future<void> initialize() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _controller!.initialize();
    }
  }

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  // <----- iniciando alteração
  /// Tira uma foto e retorna o caminho da imagem e a localização atual
  /// Retorna um mapa com 'path' (caminho da foto) e 'location' (LatLng da localização)
  Future<Map<String, dynamic>?> takePictureWithLocation() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }

    try {
      // Tirar a foto
      final XFile photo = await _controller!.takePicture();
      
      // Capturar a localização no mesmo momento
      final currentPosition = await _locationService.getCurrentLocation();
      LatLng? location;
      String? address;
      
      if (currentPosition != null) {
        location = LatLng(
          currentPosition.latitude,
          currentPosition.longitude
        );
        
        // Tentar obter o endereço da localização
        try {
          final placemarks = await _locationService.getAddressFromCoordinates(
            currentPosition.latitude,
            currentPosition.longitude
          );
          if (placemarks.isNotEmpty) {
            address = placemarks.first;
          }
        } catch (e) {
          print('Erro ao obter endereço: $e');
        }
      }
      
      // Salvar os metadados de localização no EXIF da imagem
      await _addLocationMetadataToImage(photo.path, location);
      
      return {
        'path': photo.path,
        'location': location,
        'address': address,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Erro ao tirar foto com localização: $e');
      return null;
    }
  }
  
  /// Adiciona metadados de localização à imagem
  Future<void> _addLocationMetadataToImage(String imagePath, LatLng? location) async {
    if (location == null) return;
    
    try {
      // Criar um arquivo de metadados junto com a imagem
      final File imageFile = File(imagePath);
      final String metadataPath = '$imagePath.metadata';
      final File metadataFile = File(metadataPath);
      
      // Salvar os metadados em um arquivo JSON
      final Map<String, dynamic> metadata = {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await metadataFile.writeAsString(jsonEncode(metadata));
      
      print('Metadados de localização salvos: $metadataPath');
    } catch (e) {
      print('Erro ao adicionar metadados de localização: $e');
    }
  }
  
  /// Recupera os metadados de localização de uma imagem
  Future<Map<String, dynamic>?> getLocationMetadataFromImage(String imagePath) async {
    try {
      final String metadataPath = '$imagePath.metadata';
      final File metadataFile = File(metadataPath);
      
      if (await metadataFile.exists()) {
        final String metadataContent = await metadataFile.readAsString();
        return jsonDecode(metadataContent) as Map<String, dynamic>;
      }
      
      return null;
    } catch (e) {
      print('Erro ao ler metadados de localização: $e');
      return null;
    }
  }
  // <----- finalizando alteração
  
  Future<String?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }

    try {
      final XFile photo = await _controller!.takePicture();
      return photo.path;
    } catch (e) {
      return null;
    }
  }

  // <----- iniciando alteração
  /// Seleciona uma imagem da galeria e tenta obter a localização atual
  Future<Map<String, dynamic>?> pickImageFromGalleryWithLocation() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image == null) {
        return null;
      }
      
      // Capturar a localização atual no momento da seleção
      final currentPosition = await _locationService.getCurrentLocation();
      LatLng? location;
      String? address;
      
      if (currentPosition != null) {
        location = LatLng(
          currentPosition.latitude,
          currentPosition.longitude
        );
        
        // Tentar obter o endereço da localização
        try {
          final placemarks = await _locationService.getAddressFromCoordinates(
            currentPosition.latitude,
            currentPosition.longitude
          );
          if (placemarks.isNotEmpty) {
            address = placemarks.first;
          }
        } catch (e) {
          print('Erro ao obter endereço: $e');
        }
      }
      
      // Salvar os metadados de localização
      await _addLocationMetadataToImage(image.path, location);
      
      return {
        'path': image.path,
        'location': location,
        'address': address,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Erro ao selecionar imagem com localização: $e');
      return null;
    }
  }
  // <----- finalizando alteração

  Future<String?> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      return image?.path;
    } catch (e) {
      return null;
    }
  }

  // <----- iniciando alteração
  /// Salva a imagem localmente com metadados de localização
  Future<Map<String, dynamic>?> saveImageWithLocationToLocal(
    File imageFile, 
    LatLng? location,
    String? address
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String fileName = 'entrega_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = '${directory.path}/$fileName';
      
      // Copiar a imagem
      await imageFile.copy(filePath);
      
      // Salvar os metadados junto com a imagem
      if (location != null) {
        final String metadataPath = '$filePath.metadata';
        final File metadataFile = File(metadataPath);
        
        final Map<String, dynamic> metadata = {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'address': address,
          'timestamp': DateTime.now().toIso8601String(),
        };
        
        await metadataFile.writeAsString(jsonEncode(metadata));
      }
      
      return {
        'path': filePath,
        'location': location,
        'address': address,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Erro ao salvar imagem com localização: $e');
      return null;
    }
  }
  // <----- finalizando alteração

  Future<String?> saveImageToLocal(File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String fileName = 'entrega_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = '${directory.path}/$fileName';
      
      await imageFile.copy(filePath);
      return filePath;
    } catch (e) {
      return null;
    }
  }

  CameraController? get controller => _controller;

  void dispose() {
    _controller?.dispose();
  }
}