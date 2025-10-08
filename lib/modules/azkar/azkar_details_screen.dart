import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:moshaf/modules/azkar/cubit/azkar_states.dart';

import 'cubit/azkar_cubit.dart';


class AzkarDetailScreen extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final AzkarCubit azkarCubit;
  const AzkarDetailScreen({Key? key, required this.title, required this.items,required this.azkarCubit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cubit =azkarCubit;
    return BlocBuilder<AzkarCubit,AzkarStates>(
        builder: (context,state) {
          return Scaffold(
            appBar: AppBar(title: Text(title),centerTitle: true, backgroundColor: HexColor('#fdeddc'),
              surfaceTintColor: Colors.transparent,

            ),
            backgroundColor: HexColor('#fdeddc'),
            body: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final item = items[i];
                final rel = (item['audio'] ?? '').toString(); //relative path or partial URL to the audio
                final full = rel.isEmpty ? '' : cubit.fullAudioUrl(rel); //The full absolute URL to the audio file after combining rel with the base URL via
                final playing = full.isNotEmpty && cubit.playingUrl == full && cubit.isPlaying;

                return Card(
                  color: HexColor('#fffbf7'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(child: Text(item['text'] ?? '',
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                                fontFamily: "hafs",
                                fontSize: 16.sp
                            ),
                            textAlign: TextAlign.right)),
                        IconButton(
                          icon: Icon(playing ? Icons.pause_circle : Icons.play_circle, color: HexColor('#303030')),
                          onPressed: rel.isEmpty ? null : () => cubit.playAudio(rel),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }
    );
  }
}
