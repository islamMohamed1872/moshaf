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

  // 🎙️ Available radio stations
  final Map<String, String> radioStations = {
    "إذاعة القرآن الكريم - مصر": "https://stream.radiojar.com/8s5u5tpdtwzuv",
    "إذاعة القرآن الكريم - السعودية": "https://stream.radiojar.com/0tpy1h0kxtzuv", // example link
  };

  late String selectedStationName;
  late String selectedStationUrl;

  @override
  void initState() {
    super.initState();
    _player = AudioServices().player;

    selectedStationName = radioStations.keys.first;
    selectedStationUrl = radioStations[selectedStationName]!;

    _player.playingStream.listen((playing) {
      if (mounted) setState(() => isPlaying = playing);
    });

    _player.processingStateStream.listen((state) {
      if (mounted) {
        setState(() {
          isBuffering = (state == ProcessingState.loading ||
              state == ProcessingState.buffering);
          if (state == ProcessingState.ready) isLoading = false;
        });
      }
    });

    _initRadio(selectedStationUrl);
  }

  Future<void> _initRadio(String url) async {
    try {
      setState(() {
        isLoading = true;
      });
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          tag: MediaItem(
            id: 'quran_radio',
            title: selectedStationName,
            artist: "بث مباشر",
          ),
        ),
      );
      await _player.play();
    } catch (e) {
      debugPrint("❌ Error loading radio: $e");
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تعذر تشغيل الإذاعة، تحقق من الاتصال بالإنترنت"),
          ),
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

  void _changeStation(String newStation) async {
    if (selectedStationName == newStation) return;

    setState(() {
      selectedStationName = newStation;
      selectedStationUrl = radioStations[newStation]!;
      isLoading = true;
    });

    await _player.stop();
    await _initRadio(selectedStationUrl);
  }

  @override
  void dispose() {
    _player.stop();
    super.dispose();
  }

  Widget _buildWaveBars(BuildContext context, bool isDark) {
    final totalBars = (40.w).floor();


    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalBars, (index) {
            final opacity = 0.25 + (index / totalBars) * 0.75;
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
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .scaleY(
              begin: 0.3,
              end: 1,
              duration: Duration(milliseconds: 600 + (index % 6) * 100),
              curve: Curves.easeInOut,
            )
                .then(delay: Duration(milliseconds: 80))
                .scaleY(begin: 1, end: 0.3);
          }),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            selectedStationName.contains("السعودية") ? "100" : "98.2",
            style: AppTextStyles.madMd50(context,
                color: isDark ? Colors.white : Colors.black),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);
    print(selectedStationUrl);
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage("assets/images/mosque_background.png"),
              fit: BoxFit.contain,
              opacity: 0.15,
              alignment: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                Header(
                  title: "اذاعة القرآن الكريم",
                  isDark: isDark,
                  onTap: () {
                    _player.stop();
                    Navigator.pop(context);
                  },
                  iconColor: isDark ? Colors.white : Colors.black,
                ),
                SizedBox(height: 50.h),

                // 🔽 Dropdown for station selection
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Color(isDark
                            ? AppColors.containerDarkBorders
                            : AppColors.containerLightBorders)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedStationName,
                      dropdownColor:
                      isDark ? const Color(0xFF1C1C1C) : Colors.white,
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down,
                          color: isDark ? Colors.white : Colors.black),
                      style: AppTextStyles.madB16(context,
                          color: isDark ? Colors.white : Colors.black),
                      items: radioStations.keys.map((name) {
                        return DropdownMenuItem<String>(
                          value: name,
                          child: Text(name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) _changeStation(value);
                      },
                    ),
                  ),
                ),

                SizedBox(height: 40.h),

                Text(
                  selectedStationName,
                  style: AppTextStyles.madB20(context,
                      color: isDark ? Colors.white : Colors.black),
                ),
                SizedBox(height: 10.h),
                Text(
                  "بث مباشر للقرآن الكريم",
                  style: AppTextStyles.madReg14(context,
                      color: Colors.grey.shade500),
                ),
                SizedBox(height: 50.h),

                if (isLoading)
                  const CircularProgressIndicator(color: Colors.greenAccent)
                else if (isPlaying)
                  _buildWaveBars(context, isDark)
                else
                  const SizedBox(height: 60),

                const Spacer(),

                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
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
                  selectedStationName.contains("السعودية")
                      ?"© جميع الحقوق محفوظة - إذاعة القرآن الكريم السعودية\nهيئة الإذاعة والتلفزيون السعودية (SBA)"
                      :  "© جميع الحقوق محفوظة - إذاعة القرآن الكريم المصرية\nهيئة الإذاعة والتلفزيون المصرية",
                  style: AppTextStyles.madReg12(context, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
