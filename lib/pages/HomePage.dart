import 'package:audio_player/pages/audioPage.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _songs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      _listFiles();
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _listFiles() async {
    setState(() {
      _loading = true;
    });

    // Query all audio files
    List<SongModel> songs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    // Filter out non-song audio files (you may adjust this based on your criteria)
    List<SongModel> filteredSongs =
        songs.where((song) => song.duration! > 60000).toList();

    setState(() {
      _songs = filteredSongs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "What do you want to listen to?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1c1c1f),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                onTapOutside: (event) {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                decoration: const InputDecoration(
                  hintText: "Search song..",
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _songs.length,
                      itemBuilder: (context, index) {
                        var song = _songs[index];
                        return AudioBox(song: song, path: song.uri!);
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}

class AudioBox extends StatelessWidget {
  final SongModel song;
  final String path;

  const AudioBox({
    super.key,
    required this.song,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AudioPage(
              song: song,
              path: path,
              singerName: song.artist!,
              songName: song.title,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            QueryArtworkWidget(
              id: song.id,
              type: ArtworkType.AUDIO,
              nullArtworkWidget: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 200,
                  child: Text(
                    song.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        overflow: TextOverflow.ellipsis,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  song.artist ?? "Unknown Artist",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
