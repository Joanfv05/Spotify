import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import 'package:provider/provider.dart';

class PlayerScreen extends StatefulWidget {
  final Map<String, dynamic>? initialTrack;
  final List<Map<String, dynamic>> canciones;
  final String playlistName;

  const PlayerScreen({
    super.key,
    required this.playlistName,
    required this.canciones,
    this.initialTrack,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  int currentIndex = 0;
  late List<Map<String, dynamic>> cancionesList;

  @override
  void initState() {
    super.initState();
    cancionesList = widget.canciones;

    if (widget.initialTrack != null && cancionesList.isNotEmpty) {
      final index = cancionesList.indexWhere(
              (song) => song['id'] == widget.initialTrack!['id']
      );
      if (index != -1) currentIndex = index;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (cancionesList.isNotEmpty && currentIndex < cancionesList.length) {
        final audioService = Provider.of<AudioService>(context, listen: false);
        audioService.playSongFromMap(cancionesList[currentIndex]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final audioService = Provider.of<AudioService>(context);
    final currentSong = cancionesList.isNotEmpty && currentIndex < cancionesList.length
        ? cancionesList[currentIndex]
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlistName),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.black,
        child: currentSong == null
            ? Center(
            child: Text('No hay canciones',
                style: TextStyle(color: Colors.white))
        )
            : Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 40),
                    Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          currentSong['imagen']?.toString() ?? '',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[900],
                              child: Icon(Icons.music_note,
                                  size: 100, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Text(
                            currentSong['titulo']?.toString() ?? 'Sin título',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            currentSong['artista']?.toString() ?? 'Desconocido',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.red[200],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (currentSong['album']?.toString()?.isNotEmpty ?? false)
                            Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Text(
                                currentSong['album'].toString(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  StreamBuilder<Duration?>(
                    stream: audioService.durationStream,
                    builder: (context, snapshot) {
                      final totalDuration = snapshot.data ?? Duration.zero;
                      return StreamBuilder<Duration>(
                        stream: audioService.positionStream,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? Duration.zero;
                          return Column(
                            children: [
                              Slider(
                                value: position.inSeconds.toDouble(),
                                min: 0,
                                max: totalDuration.inSeconds.toDouble(),
                                onChanged: (value) {
                                  audioService.seek(Duration(seconds: value.toInt()));
                                },
                                activeColor: Colors.red,
                                inactiveColor: Colors.grey[700],
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')}',
                                      style: TextStyle(color: Colors.grey[400]),
                                    ),
                                    Text(
                                      '${totalDuration.inMinutes}:${(totalDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                                      style: TextStyle(color: Colors.grey[400]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.shuffle,
                            color: audioService.isShuffleMode ? Colors.red : Colors.grey[400]),
                        onPressed: () => audioService.toggleShuffleMode(),
                      ),
                      IconButton(
                        icon: Icon(Icons.skip_previous, size: 40),
                        color: Colors.white,
                        onPressed: () {
                          audioService.playPreviousSong();
                          _updateCurrentIndex(audioService);
                        },
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: IconButton(
                          icon: Icon(
                            audioService.isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 50,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            if (audioService.isPlaying) {
                              audioService.pauseSong();
                            } else if (audioService.currentSong != null) {
                              audioService.resumeSong();
                            } else {
                              audioService.playSongFromMap(currentSong);
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.skip_next, size: 40),
                        color: Colors.white,
                        onPressed: () {
                          audioService.playNextSong();
                          _updateCurrentIndex(audioService);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.repeat,
                            color: audioService.isRepeatMode ? Colors.red : Colors.grey[400]),
                        onPressed: () => audioService.toggleRepeatMode(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${currentIndex + 1} / ${cancionesList.length}',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateCurrentIndex(AudioService audioService) {
    if (audioService.currentSong != null && cancionesList.isNotEmpty) {
      final currentSongId = audioService.currentSong!['id'];
      final index = cancionesList.indexWhere((song) => song['id'] == currentSongId);
      if (index != -1 && mounted) {
        setState(() => currentIndex = index);
      }
    }
  }
}