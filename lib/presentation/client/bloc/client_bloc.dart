import 'package:bloc/bloc.dart';
import 'package:app_mobile/common/model/order.dart';

// Eventos
abstract class ClientEvent {}

class LoadActiveOrdersEvent extends ClientEvent {}

class LoadOrderHistoryEvent extends ClientEvent {}

class LoadTrackingInfoEvent extends ClientEvent {
  final String orderId;
  
  LoadTrackingInfoEvent(this.orderId);
}

// Estados
abstract class ClientState {}

class ClientInitial extends ClientState {}

class ClientLoading extends ClientState {}

class ActiveOrdersLoaded extends ClientState {
  final List<Order> orders;
  
  ActiveOrdersLoaded(this.orders);
}

class OrderHistoryLoaded extends ClientState {
  final List<Order> orders;
  
  OrderHistoryLoaded(this.orders);
}

class TrackingInfoLoaded extends ClientState {
  final String? orderStatus;
  final String? driverName;
  final DateTime? estimatedDelivery;
  final double? latitude;
  final double? longitude;
  
  TrackingInfoLoaded({
    this.orderStatus,
    this.driverName,
    this.estimatedDelivery,
    this.latitude,
    this.longitude,
  });
}

class ClientError extends ClientState {
  final String message;
  
  ClientError(this.message);
}

// BLoC
class ClientBloc extends Bloc<ClientEvent, ClientState> {
  ClientBloc() : super(ClientInitial()) {
    // Tratar evento de carregar pedidos ativos
    on<LoadActiveOrdersEvent>((event, emit) async {
      emit(ClientLoading());
      try {
        // Em um app real, buscar dados da API ou banco de dados
        await Future.delayed(const Duration(seconds: 1)); // Simulação
        
        // Dados simulados
        final orders = [
          Order(
            id: 'order_123',
            description: 'Pacote Eletrônicos',
            status: 'Em Trânsito',
            estimatedDelivery: DateTime.now().add(const Duration(hours: 2)),
            driverName: 'João Silva',
          ),
          // Mais pedidos...
        ];
        
        emit(ActiveOrdersLoaded(orders));
      } catch (e) {
        emit(ClientError('Falha ao carregar pedidos: $e'));
      }
    });
    
    // Tratar evento de carregar histórico
    on<LoadOrderHistoryEvent>((event, emit) async {
      // Implementação similar para histórico
    });
    
    // Tratar evento de rastreamento de pedido
    on<LoadTrackingInfoEvent>((event, emit) async {
      // Implementação similar para rastreamento
    });
  }
}