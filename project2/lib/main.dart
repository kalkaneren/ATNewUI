import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const initialCameraPosition = CameraPosition(
    target: LatLng(41.0122, 28.976),
    zoom: 11.5,
  );

  bool _isMapInitialized = false;
  late GoogleMapController _googleMapController;
  Set<Marker> _markers = {};
  final TextEditingController _searchController = TextEditingController();
  bool _isDrawerOpen = false;

  double _priceInterval = 50;
  double _distanceWithin = 5;
  double _minimumRating = 3;

  Future<void> _initializeMap() async {
    setState(() {
      _isMapInitialized = true;
    });
  }

  void _searchAndNavigate(String query) async {
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final searchedLocation = LatLng(locations.first.latitude, locations.first.longitude);

        setState(() {
          _markers.clear();
          _markers.add(
            Marker(
              markerId: MarkerId(query),
              position: searchedLocation,
              infoWindow: InfoWindow(
                title: query,
                snippet: 'Searched Location',
              ),
            ),
          );
        });

        await _googleMapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: searchedLocation,
            zoom: 16.0,
          ),
        ));

        await Future.delayed(const Duration(milliseconds: 300));
        for (int i = 0; i < 3; i++) {
          await Future.delayed(const Duration(milliseconds: 200));
          await _googleMapController.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(
              target: searchedLocation,
              zoom: 16.0 + (i + 1),
            ),
          ));
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              query,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        _showError('Location not found');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _setMapStyle() async {
    String mapStyle = '''
    [
      {
        "featureType": "all",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#ffffff"
          }
        ]
      },
      {
        "featureType": "all",
        "elementType": "labels.icon",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      },
      {
        "featureType": "administrative",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#e0e0e0"
          }
        ]
      },
      {
        "featureType": "administrative.country",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#616161"
          }
        ]
      },
      {
        "featureType": "administrative.province",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#616161"
          }
        ]
      },
      {
        "featureType": "landscape",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#ffffff"
          }
        ]
      },
      {
        "featureType": "poi",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#f0f0f0"
          }
        ]
      },
      {
        "featureType": "road",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#d0d0d0"
          }
        ]
      },
      {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#b0bec5"
          }
        ]
      }
    ]
    ''';

    await _googleMapController.setMapStyle(mapStyle);
  }

  void _openSettings() {
    setState(() {
      _isDrawerOpen = true;
    });
  }

  void _closeSettings() {
    setState(() {
      _isDrawerOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: _openSettings,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search place...',
                          border: OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {
                              if (_searchController.text.isNotEmpty) {
                                _searchAndNavigate(_searchController.text);
                                _searchController.clear();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    if (_isMapInitialized)
                      GoogleMap(
                        onMapCreated: (controller) {
                          _googleMapController = controller;
                          _setMapStyle();
                        },
                        markers: _markers,
                        myLocationButtonEnabled: true,
                        zoomControlsEnabled: true,
                        initialCameraPosition: initialCameraPosition,
                      ),
                    Center(
                      child: Visibility(
                        visible: !_isMapInitialized,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _initializeMap();
                            });
                          },
                          child: const Text('Load Map'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!keyboardVisible)
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'What food shall we take you to?',
                          style: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        Column(
                          children: [
                            const Text(
                              'Price Interval',
                              style: TextStyle(fontSize: 16.0),
                            ),
                            Slider(
                              value: _priceInterval,
                              min: 0,
                              max: 100,
                              onChanged: (value) {
                                setState(() {
                                  _priceInterval = value;
                                });
                              },
                              label: 'Your food price interval',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        Column(
                          children: [
                            const Text(
                              'Distance Within',
                              style: TextStyle(fontSize: 16.0),
                            ),
                            Slider(
                              value: _distanceWithin,
                              min: 0,
                              max: 10,
                              onChanged: (value) {
                                setState(() {
                                  _distanceWithin = value;
                                });
                              },
                              label: 'Distance within (kms)',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        Column(
                          children: [
                            const Text(
                              'Minimum Rating',
                              style: TextStyle(fontSize: 16.0),
                            ),
                            Slider(
                              value: _minimumRating,
                              min: 0,
                              max: 5,
                              onChanged: (value) {
                                setState(() {
                                  _minimumRating = value;
                                });
                              },
                              label: 'Minimum Rating',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            DropdownButton<String>(
                              value: 'Price',
                              items: <String>['Price', 'Rating', 'Distance']
                                  .map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {},
                            ),
                            Switch(
                              value: true,
                              onChanged: (value) {},
                              activeTrackColor: Colors.lightGreenAccent,
                              activeColor: Colors.green,
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // Handle search button press
                              },
                              child: const Text('SEARCH FOOD'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (_isDrawerOpen)
            GestureDetector(
              onTap: _closeSettings,
              child: Container(
                color: Colors.black54,
                child: Row(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.5,
                      height: MediaQuery.of(context).size.height,
                      color: Colors.white,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          const Text('Option 1'),
                          const SizedBox(height: 10),
                          const Text('Option 2'),
                          const SizedBox(height: 10),
                          const Text('Option 3'),
                          const SizedBox(height: 10),
                          const Text('Option 4'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _googleMapController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
