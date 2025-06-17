import 'dart:io';
import 'package:app_mobile/common/widgets/camera_widget.dart';
import 'package:app_mobile/presentation/client/home/client_home_screen.dart';
import 'package:app_mobile/presentation/driver/deliveries/driver_home_screen.dart';
import 'package:app_mobile/services/camera_service.dart';
import 'package:app_mobile/services/database_service.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:app_mobile/common/model/delivery.dart';
import 'package:app_mobile/common/widgets/loading_indicator.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:app_mobile/services/order_service.dart';
import 'package:app_mobile/common/model/order.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateStatusScreen extends StatefulWidget {
  final Delivery delivery;

  const UpdateStatusScreen({Key? key, required this.delivery})
      : super(key: key);

  @override
  State<UpdateStatusScreen> createState() => _UpdateStatusScreenState();
}

class _UpdateStatusScreenState extends State<UpdateStatusScreen> {
  String _selectedStatus = 'Em Trânsito';
  String? _photoPath;
  bool _isLoading = false;
  bool _statusChangeInProgress = false;
  String? _errorMessage;
  LatLng? _photoLocation;
  String? _photoAddress;

  late DatabaseService _databaseService;
  final OrderService _orderService = OrderService();

  final List<String> _statusOptions = [
    'Pendente',
    'Em Trânsito',
    'Chegando',
    'Entregue',
    'Falha na Entrega',
  ];

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService();

    // Inicializar com o status atual da entrega
    if (_statusOptions.contains(widget.delivery.status)) {
      _selectedStatus = widget.delivery.status;
    } else {
      _selectedStatus = _statusOptions.first;
    }
  }

  // Função para capturar foto usando a câmera
  // Função para capturar foto usando o CameraWidget
  Future<void> _capturePhoto() async {
    if (_isLoading) return; // Evitar múltiplas chamadas

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Mostrar o CameraWidget em um diálogo
      final result = await _showCameraWidget(context);

      // Se o usuário cancelou
      if (result == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Atualizar estado com o resultado (caminho da foto e localização)
      setState(() {
        _photoPath = result['path'] as String?;
        _photoLocation = result['location'] as LatLng?;
        _photoAddress = result['address'] as String?;
        _isLoading = false;
      });

      // Mostrar mensagem de sucesso
      if (_photoLocation != null) {
        _showMessage(
            'Foto capturada com sucesso!\nLocalização registrada: ${_photoLocation!.latitude.toStringAsFixed(5)}, ${_photoLocation!.longitude.toStringAsFixed(5)}');
      } else {
        _showMessage('Foto capturada com sucesso!');
      }
    } catch (e) {
      print('Erro ao capturar foto: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao capturar foto: ${e.toString()}';
      });

      _showMessage('Erro ao capturar foto: ${e.toString()}', isError: true);
    }
  }

  // Diálogo para exibir o CameraWidget
  Future<Map<String, dynamic>?> _showCameraWidget(BuildContext context) async {
    // Obter o tamanho da tela para melhor dimensionamento
    final screenSize = MediaQuery.of(context).size;
    final isPortrait = screenSize.height > screenSize.width;

    return await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87, // Fundo mais escuro para destacar a câmera
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cabeçalho do diálogo
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Capturar Comprovante de Entrega',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.of(context).pop(),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.white.withOpacity(0.8),
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Container da câmera
                Container(
                  height: isPortrait
                      ? screenSize.height * 0.6
                      : screenSize.height * 0.7,
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16)),
                    child: CameraWidget(
                      onImageCaptured: (path, location, address) {
                        // Fornecer feedback tátil ao capturar imagem
                        HapticFeedback.mediumImpact();

                        Navigator.of(context).pop({
                          'path': path,
                          'location': location,
                          'address': address,
                        });
                      },
                    ),
                  ),
                ),

                // Dica para o usuário
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16)),
                  ),
                  child: const Text(
                    'Aponte a câmera para o comprovante e toque no botão central para capturar a foto. A localização será registrada automaticamente.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // Diálogo para exibir preview da câmera

  // Função auxiliar para exibir mensagens
  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  // Função para atualizar o status da entrega
  Future<void> _updateDeliveryStatus() async {
    if (_statusChangeInProgress) return;
    if (_selectedStatus == 'Entregue' && _photoPath == null) {
      _showMessage('Uma foto é obrigatória para confirmar a entrega',
          isError: true);
      return;
    }
    setState(() {
      _statusChangeInProgress = true;
      _errorMessage = null;
    });
    try {
      // Atualizar status no backend
      final updated = await _orderService.updateOrderStatus(
          widget.delivery.id, _selectedStatus.toUpperCase());
      if (updated) {
        _showMessage('Status atualizado com sucesso', isError: false);
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        _showMessage('Não foi possível atualizar o status', isError: true);
        setState(() {
          _statusChangeInProgress = false;
        });
      }
    } catch (e) {
      print('Erro ao atualizar status: $e');
      _showMessage('Erro ao atualizar status: ${e.toString()}', isError: true);
      setState(() {
        _statusChangeInProgress = false;
        _errorMessage = 'Erro ao atualizar status: ${e.toString()}';
      });
    }
  }

  Widget _buildPhotoLocationInfo() {
    if (_photoLocation == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue.shade700, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Localização da foto:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _photoAddress ??
                'Latitude: ${_photoLocation!.latitude.toStringAsFixed(5)}, Longitude: ${_photoLocation!.longitude.toStringAsFixed(5)}',
            style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
          ),
        ],
      ),
    );
  }

  // Controlar o botão de voltar do dispositivo
  Future<bool> _onWillPop() async {
    // Bloquear navegação durante carregamento
    if (_isLoading || _statusChangeInProgress) return false;

    // Confirmar descarte de alterações
    if (_selectedStatus != widget.delivery.status || _photoPath != null) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Descartar alterações'),
          content:
              const Text('Você tem alterações não salvas. Deseja descartar?'),
          actions: [
            TextButton(
              child: const Text('Não'),
              onPressed: () => Navigator.pop(context, false),
            ),
            TextButton(
              child: const Text('Sim'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );
      return confirm ?? false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Atualizar Status de Entrega'),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: 'Ajuda',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Como atualizar o status'),
                    content: const Text(
                      'Selecione o novo status da entrega no menu suspenso.\n\n'
                      'Se escolher "Entregue", será necessário capturar uma foto como comprovante.\n\n'
                      'Após definir o status correto, toque em ATUALIZAR STATUS para confirmar.',
                    ),
                    actions: [
                      TextButton(
                        child: const Text('Entendi'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: LoadingIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Exibir mensagem de erro se houver
                    if (_errorMessage != null)
                      Card(
                        color: Colors.red.shade50,
                        margin: const EdgeInsets.only(bottom: 16.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: Colors.red.shade800),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red.shade800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Informações da entrega
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Entrega #${widget.delivery.id}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Cliente: ${widget.delivery.clientName}'),
                            Text('Descrição: ${widget.delivery.description}'),
                            Text(
                                'Endereço: ${widget.delivery.deliveryAddress}'),
                            const SizedBox(height: 4),
                            Text(
                              'Status atual: ${widget.delivery.status}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(widget.delivery.status),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seleção de novo status
                    const Text(
                      'Novo Status:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedStatus,
                            onChanged: (String? newValue) {
                              if (newValue != null &&
                                  !_statusChangeInProgress) {
                                setState(() {
                                  _selectedStatus = newValue;
                                  // Remova a linha abaixo que fazia a atualização prematura
                                  // _databaseService.atualizarStatusEntrega(widget.delivery.id, newValue);
                                });
                              }
                            },
                            items: _statusOptions
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(value),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(value),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Área de foto para entregas concluídas
                    if (_selectedStatus == 'Entregue')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Foto de Comprovante:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Uma foto é obrigatória para confirmar a entrega.',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),

                          // Área de foto
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _photoPath != null
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      // Exibir a imagem capturada
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(7),
                                        child: Image.file(
                                          File(_photoPath!),
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Icon(Icons.broken_image,
                                                      size: 48,
                                                      color: Colors.grey),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Erro ao carregar imagem: $error',
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                        color: Colors.grey),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      // Botão para remover foto
                                      Positioned(
                                        top: 5,
                                        right: 5,
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            icon: const Icon(Icons.close,
                                                color: Colors.red),
                                            onPressed: () {
                                              setState(() {
                                                _photoPath = null;
                                                _photoLocation = null;
                                                _photoAddress = null;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      // Indicador de sucesso
                                      Positioned(
                                        bottom: 10,
                                        left: 10,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.green.withOpacity(0.8),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.check_circle,
                                                  color: Colors.white,
                                                  size: 16),
                                              const SizedBox(width: 4),
                                              Text(
                                                _photoLocation != null
                                                    ? 'Foto com localização'
                                                    : 'Foto capturada',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.camera_alt,
                                          size: 48, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text(
                                        'Nenhuma foto capturada',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Toque no botão abaixo para capturar',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                          ),

                          // Exibir informações de localização se disponíveis
                          if (_photoPath != null && _photoLocation != null)
                            _buildPhotoLocationInfo(),

                          const SizedBox(height: 12),

                          ElevatedButton.icon(
                            icon: const Icon(Icons.camera_alt),
                            label: Text(_photoPath == null
                                ? 'Capturar Foto'
                                : 'Capturar Novamente'),
                            onPressed:
                                _statusChangeInProgress ? null : _capturePhoto,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Botão para cancelar
              OutlinedButton(
                child: const Text('CANCELAR'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: _statusChangeInProgress
                    ? null
                    : () {
                        Navigator.pop(context);
                      },
              ),
              // Botão para atualizar status
              ElevatedButton(
                child: Text(_statusChangeInProgress
                    ? 'ATUALIZANDO...'
                    : 'ATUALIZAR STATUS'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  backgroundColor:
                      _statusChangeInProgress ? Colors.grey : Colors.green,
                ),
                onPressed:
                    _statusChangeInProgress ? null : _updateDeliveryStatus,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Função auxiliar para obter cor com base no status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pendente':
        return Colors.orange;
      case 'Em Trânsito':
        return Colors.blue;
      case 'Chegando':
        return Colors.purple;
      case 'Entregue':
        return Colors.green;
      case 'Falha na Entrega':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
