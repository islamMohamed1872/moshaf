import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:moshaf/components/const.dart';
import 'package:moshaf/modules/azkar/cubit/azkar_states.dart';
import 'package:moshaf/modules/text_quran/cubit/text_quran_cubit.dart';
import 'cubit/azkar_cubit.dart';

class AzkarDetailScreen extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final AzkarCubit azkarCubit;

  const AzkarDetailScreen({
    Key? key,
    required this.title,
    required this.items,
    required this.azkarCubit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cubit = azkarCubit;

    return BlocBuilder<AzkarCubit, AzkarStates>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            centerTitle: true,
            backgroundColor: HexColor('#fdeddc'),
            surfaceTintColor: Colors.transparent,
          ),
          backgroundColor: HexColor('#fdeddc'),
          body: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final item = items[i];
              item['originalCount'] ??= (item['count'] ?? 0);

              final rel = (item['audio'] ?? '').toString();
              final full = rel.isEmpty ? '' : cubit.fullAudioUrl(rel);
              final isPlaying =
                  full.isNotEmpty && cubit.playingUrl == full && cubit.isPlaying;

              final int currentCount = (item['count'] ?? 0) as int;
              final int originalCount = (item['originalCount'] ?? 0) as int;

              return Card(
                color: HexColor('#fffbf7'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      // 🔹 Zikr text & audio icon
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item['text'] ?? '',
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontFamily: "arsura",
                                fontSize: 16.sp,
                                height: 1.6,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          if(item['audio']!=null)
                          IconButton(
                            icon: Icon(
                              isPlaying
                                  ? Icons.pause_circle
                                  : Icons.play_circle,
                              color: HexColor('#303030'),
                            ),
                            onPressed: rel.isEmpty
                                ? null
                                : () async {
                              await cubit.playAudio(rel);
                              cubit.refresh();
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // 🔹 Counter + Mirror
                      GestureDetector(
                        onTap: () => cubit.decrementCount(item),
                        child: Column(
                          children: [
                            // Current count container
                            Container(
                              height: 50.h,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color:currentCount==0?Colors.green: mainBackgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  TextQuranCubit.get(context).convertToArabic(currentCount.toString()),
                                  style: TextStyle(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: "nabi",
                                    color: currentCount == 0
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 6.h),

                            // Mirror reflection
                            SizedBox(
                              height: 30.h,
                              width: double.infinity,
                              child: ClipRect(
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: ShaderMask(
                                    shaderCallback: (Rect bounds) {
                                      return ui.Gradient.linear(
                                        Offset(0, 0),
                                        Offset(0, bounds.height),
                                        [
                                          Colors.black.withValues(alpha: 0.4),
                                          Colors.black.withValues(alpha: 0.0),
                                        ],
                                      );
                                    },
                                    blendMode: BlendMode.dstIn,
                                    child: Container(
                                      height: 30.h,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: mainBackgroundColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          TextQuranCubit.get(context).convertToArabic(originalCount.toString()),
                                          style: TextStyle(
                                            fontSize: 30.sp,
                                            fontFamily: "nabi",
                                            color:
                                            Colors.black.withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
