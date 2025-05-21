import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_mobile/services/camera_service.dart';
import 'package:app_mobile/services/location_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CameraWidget extends StatefulWidget {
  final Function(String path, LatLng? location, String? address) onImageCaptured;
  
  const CameraWidget({
    Key? key, 
    required this.onImageCaptured,
  }) : super(key: key);

  @override
  State<CameraWidget> createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {
  final CameraService _cameraService = CameraService();
  final LocationService _locationService = LocationService();
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Verificar permissão de câmera
      bool hasPermission = await _cameraService.checkCameraPermission();
      
      if (!hasPermission) {
        hasPermission = await _cameraService.requestCameraPermission();
        
        if (!hasPermission) {
          setState(() {
            _errorMessage = 'Permissão de câmera negada';
            _isLoading = false;
          });
          return;
        }
      }
      
      // Inicializar câmera
      await _cameraService.initialize();
      
      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao inicializar a câmera: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _takePicture() async {
    if (_isLoading || !_isInitialized) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Capturar imagem com localização usando o método atualizado
      final result = await _cameraService.takePictureWithLocation();
      
      if (result != null) {
        // Fornecer feedback tátil
        HapticFeedback.mediumImpact();
        
        widget.onImageCaptured(
          result['path'] as String,
          result['location'] as LatLng?,
          result['address'] as String?,
        );
      } else {
        setState(() {
          _errorMessage = 'Falha ao capturar imagem';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao capturar imagem: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Selecionar imagem da galeria com localização atual
      final result = await _cameraService.pickImageFromGalleryWithLocation();
      
      if (result != null) {
        widget.onImageCaptured(
          result['path'] as String,
          result['location'] as LatLng?,
          result['address'] as String?,
        );
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao selecionar imagem: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tela de carregamento ou erro
    if (_isLoading && !_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeCamera,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    // Interface da câmera
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Visualização da câmera - parte principal
          Expanded(
            child: Stack(
              children: [
                // Preview da câmera
                if (_cameraService.controller != null && _isInitialized)
                  Center(
                    child: AspectRatio(
                      aspectRatio: _cameraService.controller!.value.aspectRatio,
                      child: CameraPreview(_cameraService.controller!),
                    ),
                  )
                else
                  const Center(
                    child: Text('Inicializando câmera...', style: TextStyle(color: Colors.white)),
                  ),
                
                // Overlay de grade (regra dos terços)
                if (_cameraService.controller != null && _isInitialized)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: GridPainter(
                        color: Colors.white.withOpacity(0.3),
                        lineWidth: 0.7,
                      ),
                    ),
                  ),
                
                // Indicador de localização
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.location_on, color: Colors.green, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Localização ativa',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Controles da câmera
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Botão da galeria
                _buildCircularButton(
                  Icons.photo_library_rounded,
                  _isLoading ? null : _pickFromGallery,
                  Colors.white24,
                ),
                
                // Botão de captura
                GestureDetector(
                  onTap: _isLoading ? null : _takePicture,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          )
                        : Container(
                            margin: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                  ),
                ),
                
                // Botão para inverter a câmera
                _buildCircularButton(
                  Icons.flip_camera_ios_rounded,
                  _isLoading ? null : () {
                    // Implementar troca de câmera
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Troca de câmera não implementada'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  Colors.white24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper para criar botões circulares
  Widget _buildCircularButton(IconData icon, VoidCallback? onTap, Color backgroundColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}

// Classe para desenhar a grade de regra dos terços
class GridPainter extends CustomPainter {
  final Color color;
  final double lineWidth;
  
  GridPainter({
    required this.color,
    required this.lineWidth,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = lineWidth;
    
    // Linhas horizontais (regra dos terços)
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(0, 2 * size.height / 3),
      Offset(size.width, 2 * size.height / 3),
      paint,
    );
    
    // Linhas verticais (regra dos terços)
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(2 * size.width / 3, 0),
      Offset(2 * size.width / 3, size.height),
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldPainter) {
    return false;
  }
}