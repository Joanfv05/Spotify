import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isPaused = false;
  List<Map<String, dynamic>> _canciones = [];
  String _cancionActual = 'Ninguna';

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    solicitarPermisos();
  }

  Future<void> solicitarPermisos() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 33) {
      var status = await Permission.audio.request();
      if (status.isGranted) {
        cargarCanciones();
      } else {
        print("Permiso denegado para acceder al audio.");
      }
    } else {
      var status = await Permission.storage.request();
      if (status.isGranted) {
        cargarCanciones();
      } else {
        print("Permiso denegado para acceder al almacenamiento.");
      }
    }
  }

  Future<void> cargarCanciones() async {
    try {
      String jsonString = await rootBundle.loadString('assets/canciones.json');
      List<dynamic> jsonList = json.decode(jsonString);
      setState(() {
        _canciones = List<Map<String, dynamic>>.from(jsonList);
      });
    } catch (e) {
      print("Error al cargar el archivo JSON: $e");
    }
  }

  Future<void> reproducirCancion(String ruta, String titulo) async {
    try {
      await _audioPlayer.setFilePath(ruta);
      _audioPlayer.play();
      setState(() {
        _isPlaying = true;
        _isPaused = false;
        _cancionActual = titulo;
      });
    } catch (e) {
      print("Error al reproducir: $e");
    }
  }

  Future<void> pausarCancion() async {
    await _audioPlayer.pause();
    setState(() {
      _isPlaying = false;
      _isPaused = true;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Música')),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _canciones.isEmpty
                  ? const Center(child: Text('No se encontraron canciones'))
                  : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 4 / 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _canciones.length,
                itemBuilder: (context, index) {
                  var cancion = _canciones[index];
                  return GestureDetector(
                    onTap: () {
                      reproducirCancion(cancion['ruta'], cancion['titulo']);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.music_note, size: 40, color: Colors.white),
                          const SizedBox(height: 8),
                          Text(
                            cancion['titulo'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          Text(
                            cancion['artista'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Reproduciendo: $_cancionActual',
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (_isPlaying) {
                        pausarCancion();
                      } else if (_isPaused) {
                        _audioPlayer.play();
                        setState(() {
                          _isPlaying = true;
                          _isPaused = false;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
