import 'package:flutter/material.dart';
import 'package:app_mobile/common/model/delivery.dart';

class UpdateStatusScreen extends StatefulWidget {
  final Delivery delivery;

  const UpdateStatusScreen({Key? key, required this.delivery}) : super(key: key);

  @override
  State<UpdateStatusScreen> createState() => _UpdateStatusScreenState();
}

class _UpdateStatusScreenState extends State<UpdateStatusScreen> {
  String _selectedStatus = 'Em Trânsito';
  String? _photoPath;
  bool _isLoading = false;
  
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
    // Verificar se o status atual da entrega está na lista de opções
    if (_statusOptions.contains(widget.delivery.status)) {
      _selectedStatus = widget.delivery.status;
    } else {
      // Se não estiver na lista, use o primeiro status disponível
      _selectedStatus = _statusOptions.first;
    }
  }
  
  Future<void> _capturePhoto() async {
    // Simulação de captura de foto
    setState(() {
      _isLoading = true;
    });
    
    // Simular delay de processamento
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _photoPath = '/path/to/captured_photo.jpg'; // Caminho simulado
      _isLoading = false;
    });
  }
  
  Future<void> _updateDeliveryStatus() async {
    // Simulação de atualização de status
    setState(() {
      _isLoading = true;
    });
    
    // Simular processo de atualização com o backend
    await Future.delayed(const Duration(seconds: 2));
    
    // Em um app real, usar o BLoC aqui
    // _driverBloc.add(UpdateDeliveryStatusEvent(
    //   id: widget.delivery.id,
    //   status: _selectedStatus,
    //   photoPath: _photoPath,
    // ));
    
    setState(() {
      _isLoading = false;
    });
    
    // Mostrar confirmação e voltar para a tela anterior ou para home
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Status atualizado com sucesso!'),
        duration: Duration(seconds: 2),
      ),
    );
    
    // Se entregue, voltar para a tela de entregas disponíveis
    if (_selectedStatus == 'Entregue' || _selectedStatus == 'Falha na Entrega') {
      Navigator.of(context).popUntil(ModalRoute.withName('/driver_home'));
    } else {
      // Caso contrário, voltar para a tela de navegação
      Navigator.pop(context);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Intercepta o botão voltar do dispositivo
      onWillPop: () async {
        // Se estiver carregando, não permite voltar
        if (_isLoading) return false;
        
        // Se fez alterações, mostra diálogo de confirmação
        if (_selectedStatus != widget.delivery.status || _photoPath != null) {
          final bool? confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Descartar alterações'),
              content: const Text('Você tem alterações não salvas. Deseja descartar?'),
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
        
        return true; // Permite voltar normalmente
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Atualizar Status de Entrega'),
          // Mantém o botão voltar padrão, mas o WillPopScope acima irá interceptá-lo
          actions: [
            // Botão de ajuda
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
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                          Text('Endereço: ${widget.delivery.deliveryAddress}'),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  const Text(
                    'Novo Status:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                            if (newValue != null) {
                              setState(() {
                                _selectedStatus = newValue;
                              });
                            }
                          },
                          items: _statusOptions.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  if (_selectedStatus == 'Entregue')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Foto de Comprovante:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        
                        // Area de foto
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _photoPath != null
                            ? const Center(child: Text('Foto capturada!'))
                            : const Center(child: Text('Nenhuma foto capturada')),
                        ),
                        const SizedBox(height: 12),
                        
                        ElevatedButton.icon(
                          icon: const Icon(Icons.camera_alt),
                          label: Text(_photoPath == null ? 'Capturar Foto' : 'Capturar Novamente'),
                          onPressed: _capturePhoto,
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
              // Botão para cancelar (voltar)
              OutlinedButton(
                child: const Text('CANCELAR'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () {
                  // O WillPopScope acima irá tratar isso
                  Navigator.pop(context);
                },
              ),
              // Botão para salvar (original, movido)
              ElevatedButton(
                child: const Text('ATUALIZAR STATUS'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () {
                  // Validar se precisa de foto para status "Entregue"
                  if (_selectedStatus == 'Entregue' && _photoPath == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Captura de foto é obrigatória para entregas concluídas!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  _updateDeliveryStatus();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}