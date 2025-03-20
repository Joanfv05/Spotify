import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../audio_service.dart';

class QueueScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AudioService>(
      builder: (context, audioService, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Current Queue'),
            backgroundColor: Colors.red[900],
          ),
          body: ReorderableListView(
            onReorder: (oldIndex, newIndex) {
              audioService.reorderQueue(oldIndex, newIndex);
            },
            children: audioService.queue.map((song) {
              return ListTile(
                key: Key(song['titulo'] ?? 'no-title-${audioService.queue.indexOf(song)}'), // Usa un identificador único
                title: Text(song['titulo'] ?? 'Unknown Title'),
                subtitle: Text(song['artista'] ?? 'Unknown Artist'), // Asegúrate de que 'artista' esté disponible
                trailing: IconButton(
                  icon: Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    // Elimina la canción de la cola según su índice actual
                    final songIndex = audioService.queue.indexOf(song);
                    audioService.removeFromQueue(songIndex);
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}