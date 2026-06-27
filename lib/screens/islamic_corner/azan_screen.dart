import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AzanScreen extends StatefulWidget {
  const AzanScreen({super.key});

  @override
  State<AzanScreen> createState() => _AzanScreenState();
}

class _AzanScreenState extends State<AzanScreen> {
  static const Color deepNavy = Color(0xFF252A34);
  static const Color sectionBg = Color(0xFF2A303C);
  static const Color teal = Color(0xFF08D9D6);
  static const Color premiumWhite = Color(0xFFEAEAEA);

  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _playingIndex;

  final List<Map<String, String>> azans = [
    {
      'title': 'Makkah Azan',
      'qari': 'Sheikh Ali Mullah',
      'url': 'https://download.quranicaudio.com/adhan/makkah.mp3'
    },
    {
      'title': 'Madina Azan',
      'qari': 'Sheikh Essam Bukhari',
      'url': 'https://download.quranicaudio.com/adhan/madina.mp3'
    },
    {
      'title': 'Al-Aqsa Azan',
      'qari': 'Naji Qazzaz',
      'url': 'https://download.quranicaudio.com/adhan/aqsa.mp3'
    }
  ];

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playPauseAzan(int index, String url) async {
    try {
      if (_playingIndex == index) {
        if (_audioPlayer.playing) {
          await _audioPlayer.pause();
        } else {
          await _audioPlayer.play();
        }
      } else {
        setState(() => _playingIndex = index);
        await _audioPlayer.setUrl(url);
        await _audioPlayer.play();
      }
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Error playing audio')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepNavy,
      appBar: AppBar(
        backgroundColor: deepNavy,
        title: const Text('Azan Audio', style: TextStyle(color: premiumWhite)),
        iconTheme: const IconThemeData(color: teal),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: azans.length,
        itemBuilder: (context, index) {
          final azan = azans[index];
          final isPlaying = _playingIndex == index && _audioPlayer.playing;

          return Card(
            color: sectionBg,
            margin: const EdgeInsets.only(bottom: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: teal.withValues(alpha: 0.2),
                radius: 25,
                child: const Icon(Icons.mosque, color: teal),
              ),
              title: Text(azan['title']!,
                  style: const TextStyle(
                      color: premiumWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              subtitle: Text(azan['qari']!,
                  style: const TextStyle(color: Colors.white70)),
              trailing: IconButton(
                icon: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: teal,
                  size: 40,
                ),
                onPressed: () => _playPauseAzan(index, azan['url']!),
              ),
            ),
          );
        },
      ),
    );
  }
}
