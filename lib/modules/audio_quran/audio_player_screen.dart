import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:moshaf/modules/audio_quran/cubit/audio_quran_cubit.dart';
import 'package:moshaf/modules/audio_quran/cubit/audio_quran_states.dart';
import 'package:quran/quran.dart' as quran;

class QuranAudioPlayerScreen extends StatefulWidget {
  const QuranAudioPlayerScreen({Key? key}) : super(key: key);

  @override
  State<QuranAudioPlayerScreen> createState() => _QuranAudioPlayerScreenState();
}

class _QuranAudioPlayerScreenState extends State<QuranAudioPlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AudioQuranCubit, AudioQuranStates>(
      listener: (_, __) {},
      builder: (context, state) {
        final cubit = AudioQuranCubit.get(context);

        // Pause/Resume disc rotation based on playback state
        if (cubit.isPlaying && !cubit.isPaused) {
          _rotationController.repeat();
        } else {
          _rotationController.stop();
        }

        return Scaffold(
          backgroundColor: HexColor("#fdeddc"),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 40),
                _buildSurahInfo(cubit),
                const Spacer(),
                _buildProgressBar(cubit),
                const SizedBox(height: 30),
                _buildControls(cubit),
                const SizedBox(height: 50),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            color: HexColor("#303030"),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            "مشغل القرآن",
            style: TextStyle(
              color: HexColor("#303030"),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSurahInfo(AudioQuranCubit cubit) {
    final arabicName = quran.getSurahNameArabic(cubit.sorahNumber);
    final place = quran.getPlaceOfRevelation(cubit.sorahNumber) == "Makkah"
        ? "مكية"
        : "مدنية";
    final verses = quran.getVerseCount(cubit.sorahNumber);

    return Column(
      children: [
        RotationTransition(
          turns: _rotationController,
          child: CircleAvatar(
            radius: 60,
            backgroundColor: HexColor("#f3eee7"),
            child: Icon(Icons.library_music, size: 50, color: HexColor("#303030")),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          arabicName,
          style: TextStyle(
            color: HexColor("#303030"),
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "$place - $verses آيات",
          style: TextStyle(
            color: HexColor("#303030").withOpacity(0.7),
            fontSize: 16,
          ),
        ),
        // const SizedBox(height: 16),
        // _buildVolumeBars(cubit),
      ],
    );
  }

  // Widget _buildVolumeBars(AudioQuranCubit cubit) {
  //   return SizedBox(
  //     height: 30,
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: List.generate(5, (i) {
  //         return AnimatedContainer(
  //           duration: const Duration(milliseconds: 200),
  //           margin: const EdgeInsets.symmetric(horizontal: 3),
  //           width: 4,
  //           height: cubit.isPlaying && !cubit.isPaused
  //               ? (10 + Random().nextInt(20)).toDouble()
  //               : 10,
  //           decoration: BoxDecoration(
  //             color: HexColor("#303030"),
  //             borderRadius: BorderRadius.circular(4),
  //           ),
  //         );
  //       }),
  //     ),
  //   );
  // }

  Widget _buildProgressBar(AudioQuranCubit cubit) {
    return Column(
      children: [
        Slider(
          activeColor: HexColor("#303030"),
          inactiveColor: HexColor("#f3eee7"),
          value: cubit.position.inSeconds
              .clamp(0, cubit.duration.inSeconds)
              .toDouble(),
          max: cubit.duration.inSeconds.toDouble(),
          onChanged: (value) =>
              cubit.seekTo(Duration(seconds: value.toInt())),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(cubit.formatTime(cubit.position),
                  style: TextStyle(color: HexColor("#303030"))),
              Text(cubit.formatTime(cubit.duration),
                  style: TextStyle(color: HexColor("#303030"))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls(AudioQuranCubit cubit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous, size: 36),
          color: HexColor("#303030"),
          onPressed: cubit.canGoPrev ? cubit.prevSurah : null,
        ),
        const SizedBox(width: 30),
        GestureDetector(
          onTap: cubit.play,
          child: CircleAvatar(
            radius: 35,
            backgroundColor: HexColor("#303030"),
            child: Icon(
              cubit.isPlaying && !cubit.isPaused
                  ? Icons.pause
                  : Icons.play_arrow,
              color: HexColor("#fdeddc"),
              size: 40,
            ),
          ),
        ),
        const SizedBox(width: 30),
        IconButton(
          icon: const Icon(Icons.skip_next, size: 36),
          color: HexColor("#303030"),
          onPressed: cubit.canGoNext ? cubit.nextSurah : null,
        ),
      ],
    );
  }
}
