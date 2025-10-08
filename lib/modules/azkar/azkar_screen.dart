import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:moshaf/components/const.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'azkar_details_screen.dart';
import 'cubit/azkar_cubit.dart';
import 'cubit/azkar_states.dart';

class AzkarScreen extends StatelessWidget {
  const AzkarScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AzkarCubit, AzkarStates>(
      listener: (context, state) {
      },
      builder: (context, state) {
        final cubit = AzkarCubit.get(context);
        return Scaffold(
          appBar: AppBar(
            title:  Text('الأذكار',
              style: TextStyle(
                  fontFamily: "hafs",
                  fontSize: 25,
                  color: mainTextColor
              ),
            ),

            backgroundColor: HexColor('#fdeddc'),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ),
          backgroundColor: HexColor('#fdeddc'),
          body: Skeletonizer(
            enabled: state is AzkarErrorState || state is AzkarLoadingState ,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText: 'بحث عن ذكر...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) => cubit.searchAzkar(value),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cubit.filteredAzkar.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final cat = Map<String, dynamic>.from(cubit.filteredAzkar[index]);
                      final title = cat['category'] ?? cat['title'] ?? 'أذكار';
                      final items = (cat['array'] as List).cast<Map<String, dynamic>>();
                      final preview = items.take(2).toList();

                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        color: HexColor('#fffbf7'),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                title,
                                style:  TextStyle(
                                    fontFamily: "hafs",
                                    fontSize: 18, fontWeight: FontWeight.bold,
                                    color: mainTextColor
                                ),
                                textAlign: TextAlign.right,
                              ),
                              const SizedBox(height: 10),
                              ...preview
                                  .map((it) => _buildPreviewRow(context, it, cubit))
                                  .toList(),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Spacer(),
                                  MaterialButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AzkarDetailScreen(
                                            title: title,
                                            items: items,
                                            azkarCubit: cubit,
                                          ),
                                        ),
                                      );
                                    },
                                    color: HexColor("#795546"),
                                    minWidth: 20,
                                    height: 30,
                                    child: Text('عرض الكل',
                                      style: TextStyle(
                                          fontSize: 15.sp,
                                          fontFamily:  "hafs",
                                          color: HexColor("#fdeddc"),
                                          fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewRow(
      BuildContext context, Map<String, dynamic> item, AzkarCubit cubit) {
    final rel = (item['audio'] ?? '').toString();
    final full = rel.isEmpty ? '' : cubit.fullAudioUrl(rel);
    final isPlaying =
        full.isNotEmpty && cubit.playingUrl == full && cubit.isPlaying;

    return BlocBuilder<AzkarCubit,AzkarStates>(
        builder: (context,state) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item['text'] ?? '',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                        fontFamily: "hafs",
                        fontSize: 16.sp
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_circle : Icons.play_circle,
                    color: HexColor('#303030'),
                  ),
                  onPressed: rel.isEmpty ? null : ()async {
                    await cubit.playAudio(rel);
                    cubit.refresh();
                  },
                )
              ],
            ),
          );
        }
    );
  }
}
