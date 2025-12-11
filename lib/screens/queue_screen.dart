import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';

class QueueScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AudioService>(
      builder: (context, audioService, child) {
        final queue = audioService.queue;
        final currentSong = audioService.currentSong;
        final isPlaying = audioService.isPlaying;
        final currentSongId = currentSong?['id'];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Cola de Reproducción', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red[900],
            actions: [
              if (queue.length > 1)
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: audioService.isShuffleMode ? Colors.white : Colors.white70,
                  ),
                  onPressed: () {
                    audioService.toggleShuffleMode();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          audioService.isShuffleMode ? 'Modo aleatorio activado' : 'Modo aleatorio desactivado',
                        ),
                        backgroundColor: Colors.red[900],
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              IconButton(
                icon: Icon(Icons.repeat, color: audioService.isRepeatMode ? Colors.white : Colors.white70),
                onPressed: () => audioService.toggleRepeatMode(),
              ),
            ],
          ),
          body: Container(
            color: Colors.black,
            child: Column(
              children: [
                if (currentSong != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            audioService.currentImage,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[800],
                                child: Icon(Icons.music_note, color: Colors.grey[600]),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reproduciendo ahora',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                audioService.currentSongTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                audioService.currentArtist,
                                style: TextStyle(color: Colors.grey[400], fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                    color: isPlaying ? Colors.red[400] : Colors.green[400],
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isPlaying ? 'En reproducción' : 'Pausado',
                                    style: TextStyle(
                                      color: isPlaying ? Colors.red[400] : Colors.green[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                          onPressed: () {
                            if (isPlaying) {
                              audioService.pauseSong();
                            } else {
                              audioService.resumeSong();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Canciones en cola: ${queue.length}',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      if (queue.isNotEmpty)
                        TextButton(
                          onPressed: () => _showClearQueueDialog(context, audioService),
                          child: Text(
                            'Limpiar cola',
                            style: TextStyle(color: Colors.red[400], fontSize: 14),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: queue.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.queue_music, size: 64, color: Colors.grey[600]),
                        const SizedBox(height: 16),
                        Text('La cola está vacía', style: TextStyle(color: Colors.white70, fontSize: 18)),
                        const SizedBox(height: 8),
                        Text('Añade canciones desde la búsqueda', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      ],
                    ),
                  )
                      : ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: queue.length,
                    onReorder: (oldIndex, newIndex) {
                      if (oldIndex < newIndex) newIndex -= 1;
                      audioService.reorderQueue(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final song = queue[index];
                      final isCurrent = song['id'] == currentSongId;
                      final songId = song['id']?.toString() ?? '${song['titulo']}_$index';

                      return Container(
                        key: Key('queue_item_${songId}_${DateTime.now().millisecondsSinceEpoch}'),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? Colors.red[900]!.withOpacity(0.2)
                              : index.isEven
                              ? Colors.grey[900]!.withOpacity(0.5)
                              : Colors.grey[800]!.withOpacity(0.5),
                          border: isCurrent
                              ? Border(left: BorderSide(color: Colors.red[400]!, width: 4))
                              : null,
                        ),
                        child: Dismissible(
                          key: Key('dismissible_${songId}_$index'),
                          background: Container(
                            color: Colors.red[900],
                            alignment: Alignment.centerLeft,
                            child: const Padding(
                              padding: EdgeInsets.only(left: 16),
                              child: Icon(Icons.delete, color: Colors.white),
                            ),
                          ),
                          secondaryBackground: Container(
                            color: Colors.red[900],
                            alignment: Alignment.centerRight,
                            child: const Padding(
                              padding: EdgeInsets.only(right: 16),
                              child: Icon(Icons.delete, color: Colors.white),
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await _showDeleteDialog(context, song['titulo']?.toString() ?? 'esta canción');
                          },
                          onDismissed: (direction) {
                            audioService.removeFromQueue(index);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Eliminada: ${song['titulo'] ?? 'Canción'}'),
                                backgroundColor: Colors.red[900],
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: isCurrent ? Colors.red[400] : Colors.grey[700],
                              backgroundImage: (song['imagen']?.toString()?.isNotEmpty ?? false)
                                  ? NetworkImage(song['imagen'].toString())
                                  : null,
                              child: (song['imagen']?.toString()?.isEmpty ?? true)
                                  ? Text(
                                '${index + 1}',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              )
                                  : null,
                            ),
                            title: Text(
                              song['titulo']?.toString() ?? 'Título desconocido',
                              style: TextStyle(
                                color: isCurrent ? Colors.red[200] : Colors.white,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: song['artista'] != null
                                ? Text(
                              song['artista']!.toString(),
                              style: TextStyle(
                                color: isCurrent ? Colors.red[100] : Colors.white70,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isCurrent)
                                  Icon(Icons.equalizer, color: Colors.red[400], size: 20),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.play_arrow, color: isCurrent ? Colors.red[400] : Colors.white70),
                                  onPressed: () => audioService.playSongAtIndex(index),
                                ),
                                const Icon(Icons.drag_handle, color: Colors.white30),
                              ],
                            ),
                            onTap: () => audioService.playSongAtIndex(index),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: queue.isNotEmpty
              ? FloatingActionButton(
            backgroundColor: Colors.red[900],
            child: const Icon(Icons.playlist_play, color: Colors.white),
            onPressed: () {
              if (queue.isNotEmpty) {
                audioService.playSongAtIndex(0);
              }
            },
          )
              : null,
        );
      },
    );
  }

  Future<bool> _showDeleteDialog(BuildContext context, String songTitle) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Eliminar canción', style: TextStyle(color: Colors.white)),
        content: Text('¿Eliminar "$songTitle" de la cola?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Eliminar', style: TextStyle(color: Colors.red[400], fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ??
        false;
  }

  void _showClearQueueDialog(BuildContext context, AudioService audioService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Limpiar cola', style: TextStyle(color: Colors.white)),
        content: Text('¿Eliminar todas las canciones de la cola?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              audioService.clearQueue();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cola limpiada'),
                  backgroundColor: Colors.red[900],
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Text('Limpiar', style: TextStyle(color: Colors.red[400], fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}