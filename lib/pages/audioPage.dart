import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:uri_to_file/uri_to_file.dart';

class AudioPage extends StatefulWidget {
  final String singerName;
  final String songName;
  final SongModel song;
  final String path;

  const AudioPage({
    Key? key,
    required this.song,
    required this.path,
    required this.singerName,
    required this.songName,
  }) : super(key: key);

  @override
  State<AudioPage> createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  Uint8List? image;

  @override
  void initState() {
    super.initState();
    art(); // Call the async method to fetch image data
    print(widget.song.duration);
    // Set up the listeners
    _audioPlayer.onDurationChanged.listen((newDuration) {
      setState(() {
        duration = newDuration;
      });
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      setState(() {
        position = newPosition;
      });
    });
  }

  void art() async {
    try {
      OnAudioQuery audioQuery = OnAudioQuery();
      Uint8List? imageData = await audioQuery.queryArtwork(
        widget.song.id,
        ArtworkType.AUDIO,
      );
      setState(() {
        image = imageData;
      });
    } catch (e) {
      print('Error fetching artwork: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void playPauseAudio() async {
    try {
      if (isPlaying) {
        await _audioPlayer.pause();
      } else {
        File file = await toFile(widget.path);
        print("path : ${file.path}");
        // Assuming widget.path is a valid URI or file path
        await _audioPlayer.play(DeviceFileSource(file.path));
      }
      setState(() {
        isPlaying = !isPlaying;
      });
    } on PlatformException catch (e) {
      print('PlatformException: ${e.message}');
      // Handle specific platform exceptions if needed
    } catch (e) {
      print('Error playing audio: $e');
      // Handle other exceptions
    }
  }

  void seekAudio(double value) {
    final position = Duration(seconds: value.toInt());
    _audioPlayer.seek(position);
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 250,
              width: 250,
              decoration: BoxDecoration(
                  image: image != null
                      ? DecorationImage(
                          image: MemoryImage(image!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: Colors.redAccent,
                  shape: BoxShape.circle),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              widget.songName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              widget.singerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Slider(
              activeColor: Colors.red,
              inactiveColor: Colors.white,
              value: position.inSeconds.toDouble(),
              max: duration.inSeconds.toDouble(),
              onChanged: seekAudio,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatDuration(position),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                Text(
                  formatDuration(duration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(
                  Icons.shuffle_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const Icon(
                  Icons.skip_previous_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                GestureDetector(
                  onTap: playPauseAudio,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFef3c39),
                    ),
                    child: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                const Icon(
                  Icons.skip_next_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const Icon(
                  Icons.replay_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
