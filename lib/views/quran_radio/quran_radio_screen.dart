import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audio_session/audio_session.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/views/widgets/header.dart';
import '../../components/audio_service.dart';
import '../../controllers/theme/theme_cubit.dart';

class QuranRadioScreen extends StatefulWidget {
  const QuranRadioScreen({Key? key}) : super(key: key);

  @override
  State<QuranRadioScreen> createState() => _QuranRadioScreenState();
}

class _QuranRadioScreenState extends State<QuranRadioScreen> {
  late AudioPlayer _player;
  bool isPlaying = false;
  bool isLoading = true;
  bool isBuffering = false;

  final String radioUrl = "https://stream.radiojar.com/8s5u5tpdtwzuv"; // إذاعة القرآن الكريم مصر

  @override
  void initState() {
    super.initState();
    _player = AudioServices().player;

    // Listen to playback state changes
    _player.playingStream.listen((playing) {
      if (mounted) setState(() => isPlaying = playing);
    });

    // Listen to processing state - hide loader when ready
    _player.processingStateStream.listen((state) {
      if (mounted) {
        setState(() {
          isBuffering = (state == ProcessingState.loading || state == ProcessingState.buffering);

          // Hide loading indicator when player is ready to play
          if (state == ProcessingState.ready) {
            isLoading = false;
          }
        });
      }
    });

    _initRadio();
  }

  Future<void> _initRadio() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      if (_player.audioSource == null) {
        await _player.setAudioSource(
          AudioSource.uri(
            Uri.parse(radioUrl),
            tag: const MediaItem(
              id: 'quran_radio',
              title: 'إذاعة القرآن الكريم',
              artist: 'من القاهرة - بث مباشر',
            ),
          ),
        );
        _player.play();
      } else {
        if (!_player.playing) await _player.play();
      }
    } catch (e) {
      debugPrint("❌ Error loading radio: $e");
      if (mounted) {
        setState(() => isLoading = false); // Hide loader on error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تعذر تشغيل الإذاعة، تحقق من الاتصال بالإنترنت")),
        );
      }
    }
  }

  void _togglePlayPause() async {
    if (isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildWaveBars(BuildContext context, bool isDark) {
    final totalBars = (40.w).floor();

    return Stack(
      alignment: Alignment.center,
      children: [
        // 🎵 Animated Bars
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalBars, (index) {
            // Smooth fade left → right
            final opacity = 0.25 + (index / totalBars) * 0.75;

            // Dynamic bar height
            final baseHeight = 10.h;
            final waveHeight = (index % 5) * 18.h + baseHeight;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 4.w,
              height: waveHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(AppColors.mainGreen).withOpacity(opacity),
                    Color(AppColors.mainGreen).withOpacity(opacity * 0.6),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Color(AppColors.mainGreen)
                        .withOpacity(opacity * 0.3),
                    blurRadius: 6,
                    spreadRadius: 0.5,
                    offset: const Offset(0, 1),
                  )
                ],
              ),
            )
            // 🔄 Continuous bounce
                .animate(onPlay: (controller) => controller.repeat())
                .scaleY(
              begin: 0.3,
              end: 1,
              duration:
              Duration(milliseconds: 600 + (index % 6) * 100),
              curve: Curves.easeInOut,
            )
                .then(delay: Duration(milliseconds: 80))
                .scaleY(begin: 1, end: 0.3);
          }),
        ),

        // 🔢 Frequency Text
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            "98.2",
            style: AppTextStyles.madMd50(
              context,
              color: isDark ? Colors.white : Colors.black,
            ),
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .then(delay: 100.ms)
              .scaleXY(begin: 0.9, end: 1, curve: Curves.easeOutBack),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark,);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: [
              Header(title: "اذاعة القرآن الكريم", isDark: isDark,onTap: () {
                _player.stop();
                Navigator.pop(context);
              },),
              SizedBox(height: 50.h),
              Text(
                "إذاعة القرآن الكريم",
                style: AppTextStyles.madB20(context,color: isDark?Colors.white:Colors.black),
              ),
              SizedBox(height: 10.h),
              Text(
                "من القاهرة - بث مباشر",
                style: AppTextStyles.madReg14(context,color: Colors.grey),
              ),
              SizedBox(height: 50.h),

              // 🔉 Wave animation or loader
              if (isLoading)
                const CircularProgressIndicator(color: Colors.greenAccent)
              else if (isPlaying)
                _buildWaveBars(context,isDark)
              else
                const SizedBox(height: 60),

              SizedBox(height: 150.h),

              // ▶️ Control buttons
              Container(
                padding: EdgeInsets.all(20.w),
                decoration:  BoxDecoration(
                  color: Color(AppColors.mainGreen),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  iconSize: 45.sp,
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: isLoading ? null : _togglePlayPause,
                ),
              ),

              const Spacer(),
              Text(
                "بث مباشر - إذاعة القرآن الكريم المصرية",
                style: AppTextStyles.madReg12(context,color: Colors.grey),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
