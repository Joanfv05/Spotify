import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/music_api.dart';
import '../services/audio_service.dart';
import 'player_screen.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final MusicApi _musicApi = MusicApi();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';
  Timer? _debounceTimer;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _errorMessage = '';
      });
      return;
    }
    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final results = await _musicApi.buscarCancionesConFallback(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error en la búsqueda: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _prepareSongForAudioService(Map<String, dynamic> track) {
    return {
      'titulo': track['title']?.toString() ?? 'Título desconocido',
      'artista': track['artist']?['name']?.toString() ?? 'Artista desconocido',
      'preview': track['preview']?.toString() ?? '',
      'album': track['album']?['title']?.toString() ?? 'Álbum desconocido',
      'imagen': track['album']?['cover_medium']?.toString() ??
          'https://e-cdns-images.dzcdn.net/images/cover/250x250-000000-80-0-0.jpg',
      'id': track['id']?.toString() ?? UniqueKey().toString(),
      'duration': track['duration'] ?? 0,
    };
  }

  void _playSongImmediately(Map<String, dynamic> track, BuildContext context) {
    final audioService = Provider.of<AudioService>(context, listen: false);
    final preparedSong = _prepareSongForAudioService(track);
    audioService.playSongFromMap(preparedSong);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red[700],
        content: Row(
          children: [
            Icon(Icons.play_arrow, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Reproduciendo: ${preparedSong['titulo']}',
                style: TextStyle(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextField(
            focusNode: _searchFocusNode,
            controller: _searchController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar canciones, artistas...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
              suffixIcon: _isLoading
                  ? Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              )
                  : IconButton(
                icon: Icon(Icons.clear, color: Colors.grey[500]),
                onPressed: () {
                  _searchController.clear();
                  _searchFocusNode.unfocus();
                  setState(() {
                    _searchResults = [];
                    _errorMessage = '';
                  });
                },
              ),
            ),
            onChanged: _onSearchChanged,
            onSubmitted: (value) {
              if (value.isNotEmpty) _performSearch(value);
            },
          ),
        ),
      ),
      body: Consumer<AudioService>(
        builder: (context, audioService, child) {
          if (_errorMessage.isNotEmpty) return _buildErrorState();
          if (_isLoading) return _buildLoadingState();
          if (_searchController.text.isEmpty) return _buildEmptyState();
          if (_searchResults.isEmpty) return _buildNoResultsState();
          return _buildResultsList(audioService);
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red),
          SizedBox(height: 20),
          Text('Error',
              style: TextStyle(fontSize: 24, color: Colors.red, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(_errorMessage,
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 16)),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: () {
              final query = _searchController.text;
              if (query.isNotEmpty) _performSearch(query);
            },
            child: Text('REINTENTAR', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.red)),
          SizedBox(height: 20),
          Text('Buscando canciones...', style: TextStyle(color: Colors.white, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 100, color: Colors.grey[700]),
          SizedBox(height: 20),
          Text('Busca tu música favorita',
              style: TextStyle(fontSize: 22, color: Colors.grey[500], fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text('Escribe para buscar canciones, artistas o álbumes',
              style: TextStyle(color: Colors.grey[600], fontSize: 14), textAlign: TextAlign.center),
          SizedBox(height: 30),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _buildQuickSearchChip('The Weeknd'),
              _buildQuickSearchChip('Bad Bunny'),
              _buildQuickSearchChip('Taylor Swift'),
              _buildQuickSearchChip('Dua Lipa'),
              _buildQuickSearchChip('Kendrick Lamar'),
              _buildQuickSearchChip('Rauw Alejandro'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_off, size: 100, color: Colors.grey[700]),
          SizedBox(height: 20),
          Text('No se encontraron resultados',
              style: TextStyle(fontSize: 22, color: Colors.grey[500], fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text('Intenta con otra búsqueda', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          SizedBox(height: 20),
          Text('"${_searchController.text}"',
              style: TextStyle(color: Colors.red, fontSize: 16, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildResultsList(AudioService audioService) {
    return ListView.builder(
      padding: EdgeInsets.only(top: 16, bottom: 80),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final track = _searchResults[index];
        final preparedSong = _prepareSongForAudioService(track);
        final isCurrent = audioService.isCurrentSong(preparedSong);
        return _buildTrackTile(track, context, isCurrent, audioService.isPlaying);
      },
    );
  }

  Widget _buildQuickSearchChip(String query) {
    return ActionChip(
      label: Text(query, style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.grey[900],
      onPressed: () {
        _searchController.text = query;
        _performSearch(query);
      },
    );
  }

  Widget _buildTrackTile(
      Map<String, dynamic> track, BuildContext context, bool isCurrent, bool isPlaying) {
    final audioService = Provider.of<AudioService>(context);
    final preparedSong = _prepareSongForAudioService(track);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrent ? Colors.red.withOpacity(0.2) : Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  track['album']?['cover_medium']?.toString() ??
                      'https://e-cdns-images.dzcdn.net/images/cover/250x250-000000-80-0-0.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[800],
                    child: Icon(Icons.music_note, color: Colors.grey[600]),
                  ),
                ),
              ),
              if (isCurrent && isPlaying)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(child: Icon(Icons.play_arrow, color: Colors.red, size: 30)),
                ),
            ],
          ),
        ),
        title: Text(preparedSong['titulo'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isCurrent ? Colors.red : Colors.white,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            )),
        subtitle: Text(preparedSong['artista'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: isCurrent ? Colors.red[200] : Colors.grey[400])),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(isCurrent && isPlaying ? Icons.pause : Icons.play_arrow,
                  color: isCurrent ? Colors.red : Colors.grey[400], size: 28),
              onPressed: () {
                if (isCurrent && isPlaying) {
                  audioService.pauseSong();
                } else if (isCurrent && !isPlaying) {
                  audioService.resumeSong();
                } else {
                  _playSongImmediately(track, context);
                }
              },
            ),
            SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.add, color: Colors.grey[500]),
              onPressed: () {
                audioService.addToQueue(preparedSong);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.green[700],
                    content: Row(
                      children: [
                        Icon(Icons.queue_music, color: Colors.white),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text('Añadido a la cola: ${preparedSong['titulo']}',
                              style: TextStyle(color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.more_horiz, color: Colors.grey[500]),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerScreen(
                    initialTrack: preparedSong,
                    canciones: _searchResults.map(_prepareSongForAudioService).toList(),
                    playlistName: 'Resultados de búsqueda',
                  ),
                ),
              ),
            ),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerScreen(
              initialTrack: preparedSong,
              canciones: _searchResults.map(_prepareSongForAudioService).toList(),
              playlistName: 'Resultados de búsqueda',
            ),
          ),
        ),
      ),
    );
  }
}