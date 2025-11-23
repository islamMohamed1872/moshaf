// podcast_player_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/controllers/theme/theme_cubit.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../models/episode_model.dart';
import '../widgets/header.dart';

class PodcastPlayerScreen extends StatefulWidget {
  final Episode episode;
  const PodcastPlayerScreen({required this.episode});

  @override
  State<PodcastPlayerScreen> createState() => _PodcastPlayerScreenState();
}

class _PodcastPlayerScreenState extends State<PodcastPlayerScreen> {
  late YoutubePlayerController controller;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayerController.convertUrlToId('https://www.youtube.com/watch?v=${widget.episode.videoId}') ?? widget.episode.videoId;
    print(videoId);
    controller = YoutubePlayerController(
      params: YoutubePlayerParams(
        mute: false,
        showControls: true,
        showFullscreenButton: true,
        enableCaption: true,
        origin: 'https://www.youtube-nocookie.com',
      ),
    );
    controller.loadVideoById(videoId: widget.episode.videoId);

  }

  @override
  void dispose() {
    controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeCubit.get(context).isDark;
    final textClr = AppColors.getTextColor(isDark: isDark);

    return YoutubePlayerScaffold(
      controller: controller,
      aspectRatio: 16 / 9,
      builder: (context, player) {
        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Header(
                    title: widget.episode.title,
                    isDark: isDark,
                    iconColor: textClr,
                  ),
                  SizedBox(height: 10.h),
                  player,
                  SizedBox(height: 18.h),
                  Text(widget.episode.title, style: AppTextStyles.madB16(context, color: textClr)),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      if (widget.episode.publishedAt != null)
                        Text(widget.episode.publishedAt!, style: AppTextStyles.madReg12(context, color: textClr)),
                      const Spacer(),
                      Text(widget.episode.durationReadable, style: AppTextStyles.madReg12(context, color: textClr)),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(widget.episode.description, style: AppTextStyles.madReg14(context, color: textClr).copyWith(height: 1.6)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
