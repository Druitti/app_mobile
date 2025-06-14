import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:app_mobile/services/location_service.dart';
import 'dart:async';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapLocationPicker extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng, String) onLocationSelected;
  
  const MapLocationPicker({
    Key? key, 
    this.initialLocation,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  final LocationService _locationService = LocationService();
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _searchController = TextEditingController();

  LatLng? _selectedLocation;
  LatLng? _currentLocation;
  String _selectedAddress = 'Endereço não selecionado';
  bool _isLoading = true;
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  Set<Marker> _markers = {};
  Timer? _debounce;

  // Chave da API do Google Maps - substitua pela sua chave
  final String _googleApiKey = 'AIzaSyA3rnp3O6e1oYp7LM9aNMHJuQ2sJH8ymQY';

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    setState(() => _isLoading = true);

    try {
      // Se houver uma localização inicial, use-a
      if (widget.initialLocation != null) {
        _selectedLocation = widget.initialLocation;
        _addMarker(_selectedLocation!);
      } 
      // Caso contrário, obtenha a localização atual
      else {
        final currentPosition = await _locationService.getCurrentLocation();
        if (currentPosition != null) {
          _currentLocation = LatLng(
            currentPosition.latitude,
            currentPosition.longitude
          );
          
          // Inicialmente, definimos a localização selecionada como a atual
          _selectedLocation = _currentLocation;
          _addMarker(_selectedLocation!);
        } else {
          // Localização padrão (São Paulo) caso não consiga obter a atual
          _selectedLocation = const LatLng(-23.5505, -46.6333);
          _addMarker(_selectedLocation!);
        }
      }
      
      // Tentar obter o endereço da localização selecionada
      await _updateAddressFromCoordinates();
    } catch (e) {
      print('Erro ao inicializar mapa: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addMarker(LatLng position) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: position,
          draggable: true,
          onDragEnd: (newPosition) {
            setState(() {
              _selectedLocation = newPosition;
              _updateAddressFromCoordinates();
            });
          },
        ),
      };
    });
  }

  // Usar geocoding (local) para obter endereço a partir de coordenadas
  Future<void> _updateAddressFromCoordinates() async {
    if (_selectedLocation == null) return;
    
    try {
      setState(() => _isSearching = true);
      
      // Usar geocoding para obter endereço a partir das coordenadas
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        // Formatar o endereço completo
        final formattedAddress = [
          place.street,
          place.subLocality,
          place.locality,
          place.postalCode,
          place.country,
        ].where((element) => element != null && element.isNotEmpty).join(', ');
        
        setState(() {
          _selectedAddress = formattedAddress;
        });
      } else {
        // Fallback para coordenadas se a geocodificação falhar
        setState(() {
          _selectedAddress = 'Latitude: ${_selectedLocation!.latitude.toStringAsFixed(5)}, '
                         + 'Longitude: ${_selectedLocation!.longitude.toStringAsFixed(5)}';
        });
      }
    } catch (e) {
      print('Erro ao obter endereço: $e');
      // Fallback para coordenadas se houver erro
      setState(() {
        _selectedAddress = 'Latitude: ${_selectedLocation!.latitude.toStringAsFixed(5)}, '
                       + 'Longitude: ${_selectedLocation!.longitude.toStringAsFixed(5)}';
      });
    } finally {
      setState(() => _isSearching = false);
    }
  }
  
  // Usar API do Google para pesquisar endereços
  Future<void> _searchAddressWithGoogle(String query) async {
  if (query.isEmpty) {
    setState(() {
      _searchResults = [];
    });
    return;
  }
  
  try {
    setState(() => _isSearching = true);
    
    // Usar a API de Places Autocomplete para obter sugestões
    final url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(query)}'
        '&key=$_googleApiKey'
        '&language=pt-BR'
        '&components=country:br'; // Limitar à resultados do Brasil
    
    print('Buscando endereços para: $query');
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Status da API: ${data['status']}');
      
      if (data['status'] == 'OK' && data['predictions'] != null) {
        // Lista para armazenar resultados preliminares
        List<Map<String, dynamic>> preliminaryResults = [];
        
        // Processar cada previsão (prediction) da API
        for (var prediction in data['predictions']) {
          preliminaryResults.add({
            'place_id': prediction['place_id'],
            'description': prediction['description'],
          });
        }
        
        print('Encontrados ${preliminaryResults.length} resultados preliminares');
        
        // Para cada resultado preliminar, fazer uma única chamada para obter detalhes
        // Vamos limitar a 5 resultados para não sobrecarregar a API
        final limitedResults = preliminaryResults.take(5).toList();
        final List<Map<String, dynamic>> processedResults = [];
        
        for (var result in limitedResults) {
          try {
            // Obter detalhes do lugar para ter as coordenadas
            final detailsUrl = 'https://maps.googleapis.com/maps/api/place/details/json'
                '?place_id=${result['place_id']}'
                '&key=$_googleApiKey'
                '&language=pt-BR'
                '&fields=geometry,formatted_address';
            
            final detailsResponse = await http.get(Uri.parse(detailsUrl));
            
            if (detailsResponse.statusCode == 200) {
              final detailsData = json.decode(detailsResponse.body);
              
              if (detailsData['status'] == 'OK' && detailsData['result'] != null) {
                final detailResult = detailsData['result'];
                final location = detailResult['geometry']['location'];
                final formattedAddress = detailResult['formatted_address'];
                
                processedResults.add({
                  'address': formattedAddress ?? result['description'],
                  'location': LatLng(
                    location['lat'] as double,
                    location['lng'] as double,
                  ),
                });
              }
            }
          } catch (e) {
            print('Erro ao obter detalhes do endereço: $e');
          }
        }
        
        print('Processados ${processedResults.length} resultados finais');
        
        // Se não conseguimos processar nenhum resultado, tentamos usar só as descrições
        if (processedResults.isEmpty && preliminaryResults.isNotEmpty) {
          setState(() {
            _searchResults = preliminaryResults.map((result) => {
              'address': result['description'],
              // Valores dummy para localização
              'location': const LatLng(0, 0),
              'place_id': result['place_id'],
              'needs_geocoding': true,
            }).toList();
          });
        } else {
          setState(() {
            _searchResults = processedResults;
          });
        }
      } else {
        // Se não houver resultados da API, tentar com geocoding local
        print('API não retornou resultados: ${data['status']}');
        _searchAddressWithGeocoding(query);
      }
    } else {
      throw Exception('Falha na comunicação com a API: ${response.statusCode}');
    }
  } catch (e) {
    print('Erro na busca de endereço: $e');
    // Tentar usar geocoding local como fallback
    _searchAddressWithGeocoding(query);
  } finally {
    setState(() => _isSearching = false);
  }
}
  
  // Usar geocoding local como fallback para pesquisa de endereços
  Future<void> _searchAddressWithGeocoding(String query) async {
    try {
      setState(() => _isSearching = true);
      
      // Usar geocoding para obter coordenadas a partir do endereço
      List<Location> locations = await locationFromAddress(query);
      
      // Converter os resultados para o formato que precisamos
      List<Map<String, dynamic>> results = [];
      
      for (var location in locations) {
        // Fazer geocodificação reversa para obter endereço completo
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );
        
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          
          // Formatar o endereço completo
          final formattedAddress = [
            place.street,
            place.subLocality,
            place.locality,
            place.postalCode,
            place.country,
          ].where((element) => element != null && element.isNotEmpty).join(', ');
          
          results.add({
            'address': formattedAddress,
            'location': LatLng(location.latitude, location.longitude),
          });
        }
      }
      
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      print('Erro na busca de endereço com geocoding: $e');

    } finally {
      setState(() => _isSearching = false);
    }
  }
  
  void _selectSearchResult(Map<String, dynamic> result) async {
  // Verificar se precisa fazer geocodificação adicional
  if (result.containsKey('needs_geocoding') && result['needs_geocoding'] == true) {
    try {
      setState(() => _isSearching = true);
      
      // Obter detalhes do lugar para ter as coordenadas
      final detailsUrl = 'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=${result['place_id']}'
          '&key=$_googleApiKey'
          '&language=pt-BR'
          '&fields=geometry,formatted_address';
      
      final detailsResponse = await http.get(Uri.parse(detailsUrl));
      
      if (detailsResponse.statusCode == 200) {
        final detailsData = json.decode(detailsResponse.body);
        
        if (detailsData['status'] == 'OK' && detailsData['result'] != null) {
          final detailResult = detailsData['result'];
          final location = detailResult['geometry']['location'];
          final formattedAddress = detailResult['formatted_address'] ?? result['address'];
          
          setState(() {
            _selectedLocation = LatLng(
              location['lat'] as double,
              location['lng'] as double,
            );
            _selectedAddress = formattedAddress;
            _searchResults = [];
            _searchController.text = formattedAddress;
          });
          
          _addMarker(_selectedLocation!);
          
          // Mover câmera para o local selecionado
          _controller.future.then((controller) {
            controller.animateCamera(CameraUpdate.newLatLngZoom(_selectedLocation!, 15));
          });
          
          return;
        }
      }
      
      // Se falhou em obter coordenadas pela API, tente com geocoding local
      await _geocodeAddressUsingLocal(result['address']);
      
    } catch (e) {
      print('Erro ao obter coordenadas para o resultado: $e');
      await _geocodeAddressUsingLocal(result['address']);
    } finally {
      setState(() => _isSearching = false);
    }
  } else {
    // Processo normal para resultados que já têm coordenadas
    setState(() {
      _selectedLocation = result['location'] as LatLng;
      _selectedAddress = result['address'] as String;
      _searchResults = [];
      _searchController.text = result['address'] as String;
    });
    
    _addMarker(_selectedLocation!);
    
    // Mover câmera para o local selecionado
    _controller.future.then((controller) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(_selectedLocation!, 15));
    });
  }
}
Future<void> _geocodeAddressUsingLocal(String address) async {
  try {
    List<Location> locations = await locationFromAddress(address);
    
    if (locations.isNotEmpty) {
      final location = locations.first;
      setState(() {
        _selectedLocation = LatLng(location.latitude, location.longitude);
        _selectedAddress = address;
        _searchResults = [];
        _searchController.text = address;
      });
      
      _addMarker(_selectedLocation!);
      
      // Mover câmera para o local selecionado
      _controller.future.then((controller) {
        controller.animateCamera(CameraUpdate.newLatLngZoom(_selectedLocation!, 15));
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível encontrar este endereço')),
      );
    }
  } catch (e) {
    print('Erro ao geocodificar endereço: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Erro ao processar o endereço')),
    );
  }
}

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
      _addMarker(position);
      _updateAddressFromCoordinates();
    });
  }

  Future<void> _goToCurrentLocation() async {
    final currentPosition = await _locationService.getCurrentLocation();
    if (currentPosition != null) {
      final controller = await _controller.future;
      
      final currentLatLng = LatLng(
        currentPosition.latitude,
        currentPosition.longitude
      );
      
      controller.animateCamera(CameraUpdate.newLatLngZoom(currentLatLng, 15));
      
      setState(() {
        _selectedLocation = currentLatLng;
        _addMarker(currentLatLng);
        _updateAddressFromCoordinates();
      });
    }
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      widget.onLocationSelected(_selectedLocation!, _selectedAddress);
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma localização no mapa')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Local de Entrega'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _confirmLocation,
            tooltip: 'Confirmar localização',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Barra de pesquisa com resultados de busca
                Padding(
  padding: const EdgeInsets.all(8.0),
  child: Column(
    children: [
      // Barra de pesquisa
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar endereço...',
            prefixIcon: _isSearching 
                ? Container(
                    padding: const EdgeInsets.all(10),
                    width: 20, 
                    height: 20, 
                    child: const CircularProgressIndicator(strokeWidth: 2)
                  )
                : const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchResults = [];
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
          onChanged: (value) {
            // Implementar debounce para não fazer muitas chamadas enquanto digita
            if (_debounce?.isActive ?? false) _debounce!.cancel();
            _debounce = Timer(const Duration(milliseconds: 500), () {
              if (value.isNotEmpty) {
                _searchAddressWithGoogle(value);
              } else {
                setState(() {
                  _searchResults = [];
                });
              }
            });
          },
        ),
      ),
      
      // Lista de resultados de pesquisa (com visual melhorado)
      if (_searchResults.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 4),
          constraints: const BoxConstraints(maxHeight: 250),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final result = _searchResults[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: index == 0
                      ? const BorderRadius.vertical(top: Radius.circular(10))
                      : index == _searchResults.length - 1
                          ? const BorderRadius.vertical(bottom: Radius.circular(10))
                          : null,
                  onTap: () => _selectSearchResult(result),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, size: 20, color: Colors.redAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            result['address'] as String,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
    ],
  ),
),
                
                // Exibe o endereço selecionado
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Endereço selecionado:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedAddress,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Mapa ocupa o restante do espaço
                Expanded(
                  child: Stack(
                    children: [
                      GoogleMap(
                        mapType: MapType.normal,
                        initialCameraPosition: CameraPosition(
                          target: _selectedLocation ?? const LatLng(-23.5505, -46.6333),
                          zoom: 15,
                        ),
                        markers: _markers,
                        onMapCreated: (GoogleMapController controller) {
                          _controller.complete(controller);
                        },
                        onTap: _onMapTap,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                      ),
                      
                      // Botão de localização atual
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: FloatingActionButton(
                          heroTag: 'btn_current_location',
                          onPressed: _goToCurrentLocation,
                          child: const Icon(Icons.my_location),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _confirmLocation,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Confirmar Local de Entrega'),
        ),
      ),
    );
  }
}