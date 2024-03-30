import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Charlottesville Bus Lines'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {

  void toggleFavorite(Busline busline) {
    setState(() {
      busline.isFavorited = !busline.isFavorited;
      // Save favorite bus lines to shared preferences
      saveFavoriteBuslines();
    });
  }

  void saveFavoriteBuslines() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favoriteIds = [];
    for (final busline in _buslines) {
      if (busline.isFavorited) {
        favoriteIds.add(busline.id.toString());
      }
    }
    prefs.setStringList('favoriteBuslines', favoriteIds);
  }

  void saveBuslist() {
    setState(() {
      List<Busline> favoriteBuslines = _buslines.where((busline) =>
      busline.isFavorited).toList();
      favoriteBuslines.sort((a, b) => a.name.compareTo(b.name));

      List<Busline> nonFavoriteBuslines = _buslines.where((busline) =>
      !busline.isFavorited).toList();
      nonFavoriteBuslines.sort((a, b) => a.name.compareTo(b.name));

      _buslines = [...favoriteBuslines, ...nonFavoriteBuslines];
    });
  }

  Future<List<String>> loadFavoriteBuslines() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? favoriteIds = prefs.getStringList('favoriteBuslines');
    return favoriteIds ?? [];
  }

  // need to query API to get bus lines
  late List<Busline> _buslines = [];

  // Function to get busline data
  Future<List<Busline>> fetchData() async {
    final res = await http.get(Uri.parse('https://www.cs.virginia.edu/~pm8fc/busses/busses.json'));
    if (res.statusCode == 200){
      // Parse data and store into state
      final data = json.decode(res.body);

      // stop info
      final Map<int, Stop> stops = {};
      for(final stop in data['stops']){
        stops[stop['id']] = Stop.fromJson(stop);
      }

      // handle routes
      final Map<int, List<Stop>> routes = {};
      for(final route in data['routes']){
        // routes[route['id']] = route['stops'];
        final List<Stop> currStops = [];
        for(final stopID in route['stops']) {  // FOR EACH STOP IN THE ROUTE, ADD STOP
          currStops.add(stops[stopID]!);
        }
        routes[route['id']] = currStops;
      }

      // handle lines
      List<Busline> lines = [];
      for(final line in data['lines']){
        // lines.add(line['long_name']);
        lines.add(Busline.fromJson(line));
      }
      for(final bus in lines){
        bus.stops = routes[bus.id]!;
      }
      return lines;
    }else{
      throw Exception("Data could not be loaded");
    }

  }

  @override
  void initState() {
    super.initState();
    fetchData().then((lines) {
      setState(() {
        _buslines = lines;
        saveBuslist();
        loadFavoriteBuslines().then((favoriteIds) async {
          // TODO: FIX THIS
          print("Checking favorite1:");
          for (String id in favoriteIds) {
            print("Checking favorite2:");
            print(id);
            Busline ? curr_busline ;
            // Busline? busline = _buslines.firstWhere((busline) => busline.id.toString() == id);
            for(final Busline bus in _buslines){
              print("Checking: " + bus.id.toString() + " against : " + id);
              if (bus.id.toString() == id){
                print("TRUE HERE");
                curr_busline = bus;
              }
            }
            if(curr_busline != null){
              print("Checking favorite3:");
              curr_busline.isFavorited = true;
            }
          }
          saveBuslist();
        });
      });
    });
    // loadFavoriteBuslines().then((favoriteIds) async {
    //   // TODO: FIX THIS
    //   print("Checking favorite1:");
    //   for (String id in favoriteIds) {
    //     print("Checking favorite2:");
    //     print(id);
    //     Busline ? curr_busline ;
    //     // Busline? busline = _buslines.firstWhere((busline) => busline.id.toString() == id);
    //     for(final Busline bus in _buslines){
    //       print("Checking: " + bus.id.toString() + " against : " + id);
    //       if (bus.id.toString() == id){
    //         print("TRUE HERE");
    //         curr_busline = bus;
    //       }
    //     }
    //     if(curr_busline != null){
    //       print("Checking favorite3:");
    //       curr_busline.isFavorited = true;
    //     }
    //   }
    //   saveBuslist();
    // });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.builder(
        itemCount: _buslines.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_buslines[index].name),
            tileColor: Color(
                int.parse(_buslines[index].color, radix: 16) + 0xFF000000),
            selectedColor: Color(
                int.parse(_buslines[index].color, radix: 16) + 0xFF000000),
            trailing: IconButton(
              icon: Icon(
                _buslines[index].isFavorited ? Icons.favorite : Icons
                    .favorite_border,
                color: _buslines[index].isFavorited ? Colors.red : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  toggleFavorite(_buslines[index]);
                  saveFavoriteBuslines(); // Call the function to save favorites
                  saveBuslist();
                });
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        MapPage(title: _buslines[index].name,
                            bounds: _buslines[index].bounds,
                            busline: _buslines[index])
                ),
              );
            },
          );
        },
      ),
    );
  }
}
class MapPage extends StatefulWidget {
  const MapPage({super.key, required this.title, required this.bounds, required this.busline});

  final String title;
  final List<double> bounds;
  final Busline busline;

  @override
  State<MapPage> createState() => _MapPageState(bounds, busline);
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController mapController;
  // final LatLng _center = const LatLng(45.521563, -122.677433);
  late final LatLng _center;
  late final LatLng _boundNE;
  late final LatLng _boundSW;
  final Map<String, Marker> _markers = {};

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  _MapPageState(List<double> bounds, Busline busline) {
    _center = LatLng((bounds[0] + bounds[2])/2.0, (bounds[1] + bounds[3])/2.0);
    _boundNE = LatLng(bounds[2], bounds[3]);
    _boundSW = LatLng(bounds[0], bounds[1]);

    int i = 0;
    for(final stop in busline.stops){
      _markers[i.toString()] = Marker(
        markerId: MarkerId(stop.name),
        position: LatLng(stop.position.lat, stop.position.long),
        infoWindow: InfoWindow(
          title: stop.name,
          snippet: "Bus Stop ${i}",
        ),
      );
      i += 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 2,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        )
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 12,
        ),
        markers: _markers.values.toSet(),
        cameraTargetBounds: CameraTargetBounds(
          LatLngBounds(
            northeast: _boundNE,
            southwest: _boundSW,
          )
        ),
      ),
    );
  }
}

class Busline {
  Busline({required this.name, required this.color, required this.id, required this.bounds, required this.stops, required this.isFavorited});
  final String name;  // long_name
  final String color;  // text_color
  final int id;  // id
  final List<double> bounds;  // bounds
  late List<Stop> stops;  // COMPLEX
  late bool isFavorited; // New property

  factory Busline.fromJson(Map<String, dynamic> json) {
    return Busline(
      bounds: List<double>.from(json['bounds']),
      id: json['id'],
      name: json['long_name'],
      color: json['text_color'],
      stops: [],
      isFavorited: false,
    );
  }
}

class Route {
  Route({required this.id, required this.stops});
  final int id;
  final List<int> stops;
}

class Stop {
  Stop({required this.id, required this.position, required this.name});
  final int id;  // id
  final String name;
  final Position position;  // bounds

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      position: Position.fromJson(json),
      name: json['name'],
      id: json['id'],
    );
  }
}

class Position {
  Position({required this.lat, required this.long});
  final double lat;
  final double long;

  factory Position.fromJson(Map<String, dynamic> json) {
    List<double> position = List<double>.from(json['position']);
    if (position.length >= 2) {
      return Position(
        lat: position[0],
        long: position[1],
      );
    } else {
      throw FormatException('Invalid position format');
    }
  }
}