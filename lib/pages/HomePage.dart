import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'audioPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _songs = [];
  List<SongModel> _filteredSongs = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _requestPermission();
    await _scanAndListFiles();
  }

  Future<void> _requestPermission() async {
    if (await _audioQuery.checkAndRequest()) {
      // Permission granted, proceed with initialization
      await _audioQuery.permissionsRequest();
    } else {
      // Handle the case when permission is not granted
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _scanAndListFiles() async {
    setState(() {
      _loading = true;
    });

    try {
      // Trigger a media scan
      await _audioQuery.scanMedia('/storage/emulated/0/');

      // Query songs after the scan
      List<SongModel> songs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      List<SongModel> filteredSongs =
          songs.where((song) => song.duration! > 60000).toList();

      setState(() {
        _songs = filteredSongs;
        _filteredSongs = _songs;
        _loading = false;
      });
    } catch (e) {
      print("Error scanning and querying songs: $e");
      setState(() {
        _loading = false;
      });
    }
  }

  void _filterSongs(String searchText) {
    searchText = searchText.toLowerCase();
    setState(() {
      _filteredSongs = _songs
          .where((song) =>
              song.title.toLowerCase().contains(searchText) ||
              song.artist!.toLowerCase().contains(searchText))
          .toList();
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
            const SizedBox(height: 15),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1c1c1f),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                onTapOutside: (event) {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                controller: _searchController,
                onChanged: _filterSongs,
                decoration: const InputDecoration(
                  hintText: "Search a song..",
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Skeletonizer(
                enabled: _loading,
                child: ListView.builder(
                  padding: const EdgeInsets.all(0),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _loading
                      ? 10
                      : _filteredSongs
                          .length, // Show 10 skeleton items when loading
                  itemBuilder: (context, index) {
                    if (_loading) {
                      return _buildSkeletonItem();
                    }
                    return AudioBox(
                      songs: _filteredSongs,
                      currentIndex: index,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonItem() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 200,
                height: 15,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 4),
              Container(
                width: 150,
                height: 15,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AudioBox extends StatelessWidget {
  final List<SongModel> songs;
  final int currentIndex;

  const AudioBox({
    super.key,
    required this.songs,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    var song = songs[currentIndex];
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AudioPage(
              songs: songs,
              currentIndex: currentIndex,
              path: song.uri!,
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
                child: const Center(
                  child: Icon(
                    Icons.music_note,
                    color: Colors.white,
                  ),
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
