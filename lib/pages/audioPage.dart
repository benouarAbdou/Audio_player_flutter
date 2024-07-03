import 'dart:typed_data';
import 'dart:io';
import 'dart:math';
import 'package:audio_player/main.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:uri_to_file/uri_to_file.dart';

class AudioPage extends StatefulWidget {
  final List<SongModel> songs;
  final int currentIndex;
  final String path;

  const AudioPage({
    Key? key,
    required this.songs,
    required this.currentIndex,
    required this.path,
  }) : super(key: key);

  @override
  State<AudioPage> createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = true;
  bool isShuffled = false;
  bool isReplayOnce = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  Uint8List? image;
  late int currentIndex;
  late List<SongModel> shuffledSongs;

  @override
  void initState() {
    super.initState();

    currentIndex = widget.currentIndex;
    shuffledSongs = List.from(widget.songs);
    playAudio();
    art();

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

    _audioPlayer.onPlayerComplete.listen((event) {
      if (isReplayOnce) {
        replayCurrentSong();
      } else {
        nextSong();
      }
    });

    showNotification();
  }

  void art() async {
    try {
      OnAudioQuery audioQuery = OnAudioQuery();
      Uint8List? imageData = await audioQuery.queryArtwork(
        shuffledSongs[currentIndex].id,
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
    cancelNotification(); // Cancel the notification when app is disposed

    super.dispose();
  }

  void playAudio() async {
    File file = await toFile(shuffledSongs[currentIndex].uri!);
    print("path : ${file.path}");
    await _audioPlayer.play(DeviceFileSource(file.path));
  }

  void playPauseAudio() async {
    try {
      if (isPlaying) {
        await _audioPlayer.pause();
      } else {
        _audioPlayer.resume();
      }
      setState(() {
        isPlaying = !isPlaying;
      });
    } on PlatformException catch (e) {
      print('PlatformException: ${e.message}');
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  Future<void> showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'audioId',
      'AudioName',
      importance: Importance.low,
      priority: Priority.high,
      showWhen: false,
      vibrationPattern: null, // Remove vibrations
      enableVibration: false, // Ensure vibration is disabled
      ongoing: true, // Make notification non-dismissible
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Assume shuffledSongs and currentIndex are initialized correctly
    final song = shuffledSongs[currentIndex];

    await flutterLocalNotificationsPlugin.show(
      0,
      'Now Playing',
      song.title,
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  void cancelNotification() async {
    await flutterLocalNotificationsPlugin.cancel(0);
  }

  void seekAudio(double value) {
    final position = Duration(seconds: value.toInt());
    _audioPlayer.seek(position);
  }

  void nextSong() {
    setState(() {
      currentIndex = (currentIndex + 1) % shuffledSongs.length;
      isPlaying = true; // Reset playing status
    });
    playAudio();
    art();
    showNotification();
  }

  void previousSong() {
    setState(() {
      currentIndex =
          (currentIndex - 1 + shuffledSongs.length) % shuffledSongs.length;
      isPlaying = true; // Reset playing status
    });
    playAudio();
    art();
    showNotification();
  }

  void shuffleSongs() {
    setState(() {
      isShuffled = !isShuffled;
      if (isShuffled) {
        // Remove the current song from the list
        SongModel currentSong = shuffledSongs[currentIndex];
        shuffledSongs.removeAt(currentIndex);

        // Shuffle the remaining songs
        shuffledSongs.shuffle();

        // Insert the current song back to its original position
        shuffledSongs.insert(0, currentSong);
        currentIndex = 0;
      } else {
        SongModel currentSong = shuffledSongs[currentIndex];
        shuffledSongs = List.from(widget.songs);
        currentIndex =
            shuffledSongs.indexWhere((song) => song.id == currentSong.id);
      }
    });
  }

  void replayCurrentSong() {
    setState(() {
      isPlaying = true; // Reset playing status
      isReplayOnce = false;
    });
    _audioPlayer.seek(Duration.zero);
    playAudio();
  }

  void toggleReplayOnce() {
    setState(() {
      isReplayOnce = !isReplayOnce;
      print(isReplayOnce);
    });
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        padding: const EdgeInsets.all(40),
        child: Stack(children: [
          Positioned(
            top: 20,
            left: 0,
            child: GestureDetector(
              onTap: () {
                // Handle back button tap here
                Navigator.pop(context);
              },
              child: const Icon(
                Icons.arrow_back_ios_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          Column(
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
              const SizedBox(height: 10),
              Text(
                shuffledSongs[currentIndex].title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                shuffledSongs[currentIndex].artist ?? 'Unknown Artist',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
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
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: shuffleSongs,
                    child: Icon(
                      Icons.shuffle_rounded,
                      color: isShuffled ? Colors.red : Colors.white,
                      size: 24,
                    ),
                  ),
                  GestureDetector(
                    onTap: previousSong,
                    child: const Icon(
                      Icons.skip_previous_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
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
                  GestureDetector(
                    onTap: nextSong,
                    child: const Icon(
                      Icons.skip_next_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  GestureDetector(
                    onTap: toggleReplayOnce,
                    child: Icon(
                      Icons.replay_rounded,
                      color: isReplayOnce ? Colors.red : Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ]),
      ),
    );
  }
}
