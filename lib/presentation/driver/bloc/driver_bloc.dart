import 'package:bloc/bloc.dart';
import 'package:app_mobile/common/model/delivery.dart';

// Eventos
abstract class DriverEvent {}

class LoadAvailableDeliveriesEvent extends DriverEvent {}

class LoadCompletedDeliveriesEvent extends DriverEvent {}

class AcceptDeliveryEvent extends DriverEvent {
  final String deliveryId;
  
  AcceptDeliveryEvent(this.deliveryId);
}

class UpdateDeliveryStatusEvent extends DriverEvent {
  final String id;
  final String status;
  final String? photoPath;
  
  UpdateDeliveryStatusEvent({
    required this.id,
    required this.status,
    this.photoPath,
  });
}

// Estados
abstract class DriverState {}

class DriverInitial extends DriverState {}

class DriverLoading extends DriverState {}

class AvailableDeliveriesLoaded extends DriverState {
  final List<Delivery> deliveries;
  
  AvailableDeliveriesLoaded(this.deliveries);
}

class CompletedDeliveriesLoaded extends DriverState {
  final List<Delivery> deliveries;
  
  CompletedDeliveriesLoaded(this.deliveries);
}

class DeliveryAccepted extends DriverState {
  final Delivery delivery;
  
  DeliveryAccepted(this.delivery);
}

class StatusUpdated extends DriverState {}

class DriverError extends DriverState {
  final String message;
  
  DriverError(this.message);
}

// BLoC
class DriverBloc extends Bloc<DriverEvent, DriverState> {
  DriverBloc() : super(DriverInitial()) {
    // Tratar evento de carregar entregas disponíveis
    on<LoadAvailableDeliveriesEvent>((event, emit) async {
      emit(DriverLoading());
      try {
        // Em um app real, buscar dados da API ou banco de dados
        await Future.delayed(const Duration(seconds: 1)); // Simulação
        
        // Dados simulados
        final deliveries = [
          Delivery(
            id: 'delivery_111',
            description: 'Pacote Pequeno - Documentos Urgentes',
            status: 'Pendente',
            clientName: 'Empresa X',
            deliveryAddress: 'Rua das Flores, 123, São Paulo',
            timestamp: DateTime.now().add(const Duration(minutes: 30)),
          ),
          // Mais entregas...
        ];
        
        emit(AvailableDeliveriesLoaded(deliveries));
      } catch (e) {
        emit(DriverError('Falha ao carregar entregas: $e'));
      }
    });
    
    // @to-do Implementar os demais handlers de eventos...
  }
}