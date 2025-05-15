import 'dart:io';
import 'package:flutter/material.dart';
import 'package:app_mobile/common/model/delivery.dart';
import 'package:app_mobile/common/widgets/custom_button.dart';
import 'package:app_mobile/common/widgets/loading_indicator.dart';
import 'package:app_mobile/services/camera_service.dart';
import 'package:app_mobile/services/location_service.dart';
import 'package:app_mobile/presentation/driver/bloc/driver_bloc.dart'; // Importar BLoC
import 'package:app_mobile/common/utils/helpers.dart'; // Para showSnackBar/Dialogs
import 'package:image_picker/image_picker.dart'; // Para XFile
import 'package:geolocator/geolocator.dart'; // Para Position
import 'package:dartz/dartz.dart' as dartz;

class UpdateStatusScreen extends StatefulWidget {
  final Delivery delivery;

  const UpdateStatusScreen({Key? key, required this.delivery}) : super(key: key);

  @override
  State<UpdateStatusScreen> createState() => _UpdateStatusScreenState();
}

class _UpdateStatusScreenState extends State<UpdateStatusScreen> {
  final CameraService _cameraService = CameraService();
  final LocationService _locationService = LocationService();
  // Instanciar BLoC (via Provider ou DI)
  // final DriverBloc _driverBloc = DriverBloc(); // Exemplo

  String _selectedStatus = 'Entregue'; // Status inicial padrão
  XFile? _takenPhoto;
  Position? _photoLocation;
  bool _isProcessing = false;

  final List<String> _statusOptions = ['Entregue', 'Falha na Entrega', 'Cliente Ausente'];

  Future<void> _takePictureAndLocation() async {
    setState(() => _isProcessing = true);

    // 1. Obter Localização Atual
    final locationResult = await _locationService.getCurrentLocation();
    Position? currentLocation;
    locationResult.fold(
      (failure) {
        showErrorDialog(context, 'Erro de Localização', failure.message);
        setState(() => _isProcessing = false);
        return; // Aborta se não conseguir localização
      },
      (position) {
        currentLocation = position;
      },
    );

    if (currentLocation == null) return; // Segurança extra

    // 2. Tirar Foto
    final photoResult = await _cameraService.takePicture();
    photoResult.fold(
      (failure) {
        showErrorDialog(context, 'Erro da Câmera', failure.message);
        setState(() => _isProcessing = false);
      },
      (photo) {
        setState(() {
          _takenPhoto = photo;
          _photoLocation = currentLocation; // Associa a localização à foto tirada
          _isProcessing = false;
        });
        showSnackBar(context, 'Foto capturada com sucesso!');
      },
    );
  }

  Future<void> _confirmUpdate() async {
    if (_selectedStatus == 'Entregue' && _takenPhoto == null) {
      showErrorDialog(context, 'Foto Necessária',
          'Para marcar como "Entregue", é necessário tirar a foto da assinatura.');
      return;
    }

    setState(() => _isProcessing = true);

    // Criar objeto Delivery atualizado
    Delivery updatedDelivery = widget.delivery.copyWith(
      status: _selectedStatus,
      photoPath: _takenPhoto?.path,
      latitude: _photoLocation?.latitude,
      longitude: _photoLocation?.longitude,
      timestamp: DateTime.now(), // Atualiza o timestamp para o momento da confirmação
    );

    print('Atualizando entrega: ${updatedDelivery.id}');
    print('Status: ${updatedDelivery.status}');
    print('Foto: ${updatedDelivery.photoPath}');
    print('Localização: (${updatedDelivery.latitude}, ${updatedDelivery.longitude})');

    // Disparar evento no BLoC para salvar a atualização (SQLite e API)
    // _driverBloc.add(UpdateDeliveryStatusEvent(updatedDelivery));

    // Simulação de sucesso após um tempo
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isProcessing = false);

    // Mostrar confirmação e voltar para a tela inicial do motorista
    showSnackBar(context, 'Status da entrega atualizado com sucesso!');
    // Navegar de volta para a home do motorista (ou outra tela apropriada)
    // Usar pushAndRemoveUntil para limpar a pilha de navegação
    Navigator.of(context).pushNamedAndRemoveUntil('/driver_home', (Route<dynamic> route) => false);
    // Certifique-se de ter uma rota nomeada '/driver_home' ou ajuste a navegação

    // Exemplo de como navegar para a home se não usar rotas nomeadas:
    // Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atualizar Status da Entrega'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Entrega: ${widget.delivery.description}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Cliente: ${widget.delivery.clientName}'),
                  const SizedBox(height: 8),
                  Text('Endereço: ${widget.delivery.deliveryAddress}'),
                  const SizedBox(height: 20),
                  const Text('Selecione o novo status:', style: TextStyle(fontSize: 16)),
                  DropdownButton<String>(
                    value: _selectedStatus,
                    isExpanded: true,
                    items: _statusOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedStatus = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  // Seção da Foto
                  if (_selectedStatus == 'Entregue') ...[
                    CustomButton(
                      text: _takenPhoto == null
                          ? 'Tirar Foto da Assinatura'
                          : 'Tirar Nova Foto',
                      onPressed: _takePictureAndLocation,
                      color: Colors.orangeAccent,
                    ),
                    const SizedBox(height: 10),
                    if (_takenPhoto != null)
                      Center(
                        child: Column(
                          children: [
                            const Text('Foto Capturada:'),
                            Image.file(
                              File(_takenPhoto!.path),
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                            if (_photoLocation != null)
                              Text(
                                'Localização: (${_photoLocation!.latitude.toStringAsFixed(5)}, ${_photoLocation!.longitude.toStringAsFixed(5)})',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                  // Botão de Confirmação
                  Center(
                    child: CustomButton(
                      text: 'Confirmar Atualização',
                      onPressed: _confirmUpdate,
                      isLoading: _isProcessing,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Indicador de Loading sobreposto
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const LoadingIndicator(),
            ),
        ],
      ),
    );
  }
}

