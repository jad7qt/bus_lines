import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  // need to query API to get bus lines
  late List<Busline> _buslines = [];

  // Function to get busline data
  Future<List<Busline>> fetchData() async {
    final res = await http.get(Uri.parse('https://www.cs.virginia.edu/~pm8fc/busses/busses.json'));
    if (res.statusCode == 200){
      // Parse data and store into state
      final data = json.decode(res.body);

      // stop info
      final Map<int, Position> stops = {};
      for(final stop in data['stops']){
        stops[stop['id']] = Position.fromJson(stop);
      }

      // handle routes
      final Map<int, List<Position>> routes = {};
      for(final route in data['routes']){
        // routes[route['id']] = route['stops'];
        final List<Position> currStops = [];
        for(final stopID in route['stops']) {  // FOR EACH STOP IN THE ROUTE, ADD POSITION
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
      // TODO: Get the stops in a map, stop ID to position (list of 2 doubles)
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
      });
    });
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
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => MapPage(title: _buslines[index].name, bounds: _buslines[index].bounds, busline: _buslines[index])
                ),
              );
            },
            child: ListTile(
              title: Text(_buslines[index].name),
              tileColor: Color(int.parse(_buslines[index].color, radix: 16) + 0xFF000000),
              selectedColor: Color(int.parse(_buslines[index].color, radix: 16) + 0xFF000000),
            ),
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
    for(final position in busline.stops){
      _markers[i.toString()] = Marker(
        markerId: MarkerId(i.toString()),
        position: LatLng(position.lat, position.long),
      );
      i += 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green[700],
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          elevation: 2,
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
            // LatLngBounds(
            //   northeast: LatLng(38.130205, -78.436039),
            //   southwest: LatLng(38.031599, -78.508578),
            // )
          ),
        ),
      ),
    );
  }
}

class Busline {
  Busline({required this.name, required this.color, required this.id, required this.bounds, required this.stops});
  final String name;  // long_name
  final String color;  // text_color
  final int id;  // id
  final List<double> bounds;  // bounds
  late List<Position> stops;  // COMPLEX

  factory Busline.fromJson(Map<String, dynamic> json) {
    return Busline(
      bounds: List<double>.from(json['bounds']),
      id: json['id'],
      name: json['long_name'],
      color: json['text_color'],
      stops: [],
    );
  }
}

class Route {
  Route({required this.id, required this.stops});
  final int id;
  final List<int> stops;
}

class Stop {
  Stop({required this.id, required this.position});
  final int id;  // id
  final List<double> position;  // bounds

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      position: List<double>.from(json['position']),
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