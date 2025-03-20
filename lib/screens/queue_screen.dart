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
            children: audioService.queue.asMap().entries.map((entry) {
              final index = entry.key;
              final song = entry.value;
              return ListTile(
                key: Key('$index'),
                title: Text(song['titulo']),
                subtitle: Text(song['artista']),
                trailing: IconButton(
                  icon: Icon(Icons.remove_circle_outline),
                  onPressed: () => audioService.removeFromQueue(index),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
