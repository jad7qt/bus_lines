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
      // List<String> lines = [];
      List<Busline> lines = [];
      for(final line in data['lines']){
        // lines.add(line['long_name']);
        lines.add(Busline.fromJson(line));
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
                    builder: (context) => MapPage(title: _buslines[index].name, bounds: _buslines[index].bounds)
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
  const MapPage({super.key, required this.title, required this.bounds});

  final String title;
  final List<double> bounds;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController mapController;

  final LatLng _center = const LatLng(45.521563, -122.677433);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
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
          title: const Text('Maps Sample App'),
          elevation: 2,
        ),
        body: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: _center,
            zoom: 11.0,
          ),
        ),
      ),
    );
  }
}

class Busline {
  Busline({required this.name, required this.color, required this.id, required this.bounds});
  final String name;  // long_name
  final String color;  // text_color
  final int id;  // id
  final List<double> bounds;  // bounds
// TODO: ADD STOPS LIST
  // final List<List<int>> stops;  // COMPLEX

  factory Busline.fromJson(Map<String, dynamic> json) {
    return Busline(
      bounds: List<double>.from(json['bounds']),
      id: json['id'],
      name: json['long_name'],
      color: json['text_color'],
    );
  }
}