// lib/views/habit_tracker/habit_tracker_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/controllers/habit/habit_cubit.dart';
import 'package:moshaf/controllers/habit/habit_states.dart';
import 'package:moshaf/controllers/theme/theme_cubit.dart';
import 'package:moshaf/views/widgets/header.dart';

class HabitTrackerScreen extends StatelessWidget {
  const HabitTrackerScreen({super.key});

  static const String rafeqSuccess = 'assets/images/habit_rafeq_success.png';
  static const String rafeqEmpty = 'assets/images/habit_rafeq_empty.png';
  static const String rafeqNotDone = 'assets/images/habit_rafeq_not_done.png';

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit c) => c.isDark);
    final gold = AppColors.isGoldMode;

    final bgColor = gold
        ? const Color(AppColors.goldBackground)
        : isDark
        ? const Color(0xFF151515)
        : Colors.white;

    final textClr = gold
        ? const Color(AppColors.goldText)
        : isDark
        ? Colors.white
        : Colors.black;

    final borderClr = gold
        ? const Color(AppColors.goldBorder)
        : Color(
      isDark
          ? AppColors.containerDarkBorders
          : AppColors.containerLightBorders,
    );

    final accentClr = gold
        ? const Color(AppColors.goldPrimary)
        : Color(AppColors.mainGreen);

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: FloatingActionButton(
        backgroundColor: accentClr,
        onPressed: () => _showAddHabitDialog(
          context,
          textClr,
          borderClr,
          accentClr,
          bgColor,
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Column(
            children: [
              Header(
                title: 'متابعة العادات',
                isDark: isDark,
                iconColor: textClr,
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: BlocBuilder<HabitCubit, HabitStates>(
                  builder: (context, state) {
                    final cubit = HabitCubit.get(context);
                    final todayHabits = cubit.todayHabits;

                    final String rafeqImage = cubit.habits.isEmpty
                        ? rafeqEmpty
                        : cubit.completedTodayCount == todayHabits.length &&
                        todayHabits.isNotEmpty
                        ? rafeqSuccess
                        : rafeqNotDone;

                    final String rafeqMessage = cubit.habits.isEmpty
                        ? 'ابدأ بإضافة أول عادة 🌿'
                        : cubit.completedTodayCount == todayHabits.length &&
                        todayHabits.isNotEmpty
                        ? 'أحسنت! أنجزت عادات اليوم ✨'
                        : 'رفيق معك… كمّل عاداتك اليوم 🤍';

                    return Column(
                      children: [
                        _RafeqHabitHeader(
                          imagePath: rafeqImage,
                          message: rafeqMessage,
                          completed: cubit.completedTodayCount,
                          total: todayHabits.length,
                          progress: cubit.todayProgress,
                          textClr: textClr,
                          borderClr: borderClr,
                          accentClr: accentClr,
                        ),
                        SizedBox(height: 14.h),
                        Expanded(
                          child: todayHabits.isEmpty
                              ? _EmptyHabitsView(
                            imagePath: rafeqEmpty,
                            textClr: textClr,
                            accentClr: accentClr,
                          )
                              : ListView.separated(
                            itemCount: todayHabits.length,
                            separatorBuilder: (_, __) =>
                                SizedBox(height: 10.h),
                            itemBuilder: (context, index) {
                              final habit = todayHabits[index];

                              return _HabitCard(
                                title: habit.title,
                                icon: habit.icon,
                                isDone: habit.isDoneToday(),
                                streak: habit.streak,
                                dailyTarget: habit.dailyTarget,
                                todayProgress: habit.todayProgress(),
                                frequency: habit.frequency,
                                textClr: textClr,
                                borderClr: borderClr,
                                accentClr: accentClr,
                                onPlus: () =>
                                    cubit.incrementToday(habit.id),
                                onMinus: () =>
                                    cubit.decrementToday(habit.id),
                                onDelete: () =>
                                    cubit.deleteHabit(habit.id),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddHabitDialog(
      BuildContext context,
      Color textClr,
      Color borderClr,
      Color accentClr,
      Color bgColor,
      ) async {
    final titleController = TextEditingController();
    final iconController = TextEditingController(text: '🌿');
    final targetController = TextEditingController(text: '1');

    String selectedFrequency = 'everyday';
    List<int> selectedDays = [];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: bgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: borderClr),
              ),
              title: Text(
                'إضافة عادة جديدة',
                style: AppTextStyles.madB16(context, color: textClr),
                textAlign: TextAlign.right,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DialogTextField(
                      controller: titleController,
                      hint: 'اسم العادة',
                      textClr: textClr,
                      borderClr: borderClr,
                    ),
                    SizedBox(height: 10.h),
                    _DialogTextField(
                      controller: targetController,
                      hint: 'الهدف اليومي',
                      textClr: textClr,
                      borderClr: borderClr,
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 10.h),
                    _DialogTextField(
                      controller: iconController,
                      hint: 'Icon / Emoji',
                      textClr: textClr,
                      borderClr: borderClr,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                    ),
                    SizedBox(height: 14.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'التكرار',
                        style: AppTextStyles.madB14(context, color: textClr),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        _FrequencyChip(
                          label: 'كل يوم',
                          value: 'everyday',
                          selectedValue: selectedFrequency,
                          accentClr: accentClr,
                          textClr: textClr,
                          onTap: () => setDialogState(() {
                            selectedFrequency = 'everyday';
                            selectedDays = [];
                          }),
                        ),
                        _FrequencyChip(
                          label: 'أيام الأسبوع',
                          value: 'weekdays',
                          selectedValue: selectedFrequency,
                          accentClr: accentClr,
                          textClr: textClr,
                          onTap: () => setDialogState(() {
                            selectedFrequency = 'weekdays';
                            selectedDays = [];
                          }),
                        ),
                        _FrequencyChip(
                          label: 'الويك إند',
                          value: 'weekends',
                          selectedValue: selectedFrequency,
                          accentClr: accentClr,
                          textClr: textClr,
                          onTap: () => setDialogState(() {
                            selectedFrequency = 'weekends';
                            selectedDays = [];
                          }),
                        ),
                        _FrequencyChip(
                          label: 'مخصص',
                          value: 'custom',
                          selectedValue: selectedFrequency,
                          accentClr: accentClr,
                          textClr: textClr,
                          onTap: () => setDialogState(() {
                            selectedFrequency = 'custom';
                          }),
                        ),
                      ],
                    ),
                    if (selectedFrequency == 'custom') ...[
                      SizedBox(height: 14.h),
                      _WeekDaysSelector(
                        selectedDays: selectedDays,
                        accentClr: accentClr,
                        textClr: textClr,
                        onChanged: (days) {
                          setDialogState(() {
                            selectedDays = days;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'إلغاء',
                    style: AppTextStyles.madReg14(context, color: textClr),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentClr,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final title = titleController.text.trim();
                    final icon = iconController.text.trim();
                    final target =
                        int.tryParse(targetController.text.trim()) ?? 1;

                    if (title.isEmpty) return;

                    if (selectedFrequency == 'custom' &&
                        selectedDays.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('اختر يوم واحد على الأقل'),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext, {
                      'title': title,
                      'icon': icon.isEmpty ? '🌿' : icon,
                      'frequency': selectedFrequency,
                      'customDays': selectedDays,
                      'dailyTarget': target <= 0 ? 1 : target,
                    });
                  },
                  child: Text(
                    'حفظ',
                    style: AppTextStyles.madB14(context, color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    await HabitCubit.get(context).addHabit(
      title: result['title'],
      icon: result['icon'],
      frequency: result['frequency'],
      customDays: List<int>.from(result['customDays']),
      dailyTarget: result['dailyTarget'],
    );
  }
}
class _RafeqHabitHeader extends StatelessWidget {
  final String imagePath;
  final String message;
  final int completed;
  final int total;
  final double progress;
  final Color textClr;
  final Color borderClr;
  final Color accentClr;

  const _RafeqHabitHeader({
    required this.imagePath,
    required this.message,
    required this.completed,
    required this.total,
    required this.progress,
    required this.textClr,
    required this.borderClr,
    required this.accentClr,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderClr),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            accentClr.withOpacity(0.12),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            imagePath,
            width: 105.w,
            height: 105.w,
            fit: BoxFit.contain,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: AppTextStyles.madB16(context, color: textClr),
                ),
                SizedBox(height: 8.h),
                Text(
                  '$completed من $total عادات اليوم',
                  style: AppTextStyles.madReg12(
                    context,
                    color: textClr.withOpacity(0.65),
                  ),
                ),
                SizedBox(height: 10.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 9.h,
                    backgroundColor: borderClr.withOpacity(0.25),
                    color: accentClr,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  '$percent%',
                  style: AppTextStyles.madB12(context, color: accentClr),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHabitsView extends StatelessWidget {
  final String imagePath;
  final Color textClr;
  final Color accentClr;

  const _EmptyHabitsView({
    required this.imagePath,
    required this.textClr,
    required this.accentClr,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            imagePath,
            width: 150.w,
            height: 150.w,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 12.h),
          Text(
            'لا توجد عادات اليوم',
            style: AppTextStyles.madB16(context, color: textClr),
          ),
          SizedBox(height: 5.h),
          Text(
            'اضغط + وأضف عادة جديدة',
            style: AppTextStyles.madReg12(
              context,
              color: textClr.withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Color textClr;
  final Color borderClr;
  final TextInputType? keyboardType;
  final TextAlign textAlign;
  final TextDirection textDirection;

  const _DialogTextField({
    required this.controller,
    required this.hint,
    required this.textClr,
    required this.borderClr,
    this.keyboardType,
    this.textAlign = TextAlign.right,
    this.textDirection = TextDirection.rtl,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textAlign: textAlign,
      textDirection: textDirection,
      style: AppTextStyles.madReg14(context, color: textClr),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.madReg12(
          context,
          color: textClr.withOpacity(0.45),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderClr),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderClr),
        ),
      ),
    );
  }
}

class _FrequencyChip extends StatelessWidget {
  final String label;
  final String value;
  final String selectedValue;
  final Color accentClr;
  final Color textClr;
  final VoidCallback onTap;

  const _FrequencyChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.accentClr,
    required this.textClr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == selectedValue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected ? accentClr : accentClr.withOpacity(0.08),
          border: Border.all(color: accentClr.withOpacity(0.35)),
        ),
        child: Text(
          label,
          style: AppTextStyles.madReg12(
            context,
            color: selected ? Colors.white : textClr,
          ),
        ),
      ),
    );
  }
}

class _WeekDaysSelector extends StatelessWidget {
  final List<int> selectedDays;
  final Color accentClr;
  final Color textClr;
  final ValueChanged<List<int>> onChanged;

  const _WeekDaysSelector({
    required this.selectedDays,
    required this.accentClr,
    required this.textClr,
    required this.onChanged,
  });

  static const days = [
    {'label': 'جمعة', 'value': DateTime.friday},
    {'label': 'سبت', 'value': DateTime.saturday},
    {'label': 'أحد', 'value': DateTime.sunday},
    {'label': 'إثنين', 'value': DateTime.monday},
    {'label': 'ثلاتاء', 'value': DateTime.tuesday},
    {'label': 'أربعاء', 'value': DateTime.wednesday},
    {'label': 'خميس', 'value': DateTime.thursday},
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7.w,
      runSpacing: 7.h,
      children: days.map((day) {
        final value = day['value'] as int;
        final selected = selectedDays.contains(value);

        return GestureDetector(
          onTap: () {
            final updated = List<int>.from(selectedDays);

            if (selected) {
              updated.remove(value);
            } else {
              updated.add(value);
            }

            onChanged(updated);
          },
          child: Container(
            width: 45.w,
            height: 30.w,
            decoration: BoxDecoration(
              // shape: BoxShape.circle,
              color: selected ? accentClr : accentClr.withOpacity(0.08),
              border: Border.all(color: accentClr.withOpacity(0.35)),
              borderRadius: BorderRadius.circular(10)
            ),
            child: Center(
              child: Text(
                day['label'] as String,
                style: AppTextStyles.madB12(
                  context,
                  color: selected ? Colors.white : textClr,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
class _HabitCard extends StatelessWidget {
  final String title;
  final String icon;
  final bool isDone;
  final int streak;
  final int dailyTarget;
  final int todayProgress;
  final String frequency;
  final Color textClr;
  final Color borderClr;
  final Color accentClr;
  final VoidCallback onPlus;
  final VoidCallback onMinus;
  final VoidCallback onDelete;

  const _HabitCard({
    required this.title,
    required this.icon,
    required this.isDone,
    required this.streak,
    required this.dailyTarget,
    required this.todayProgress,
    required this.frequency,
    required this.textClr,
    required this.borderClr,
    required this.accentClr,
    required this.onPlus,
    required this.onMinus,
    required this.onDelete,
  });

  String get frequencyLabel {
    switch (frequency) {
      case 'everyday':
        return 'كل يوم';
      case 'weekdays':
        return 'أيام الأسبوع';
      case 'weekends':
        return 'الويك إند';
      case 'custom':
        return 'أيام مخصصة';
      default:
        return 'كل يوم';
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = dailyTarget == 0 ? 0.0 : todayProgress / dailyTarget;

    return GestureDetector(
      onTap: !isDone? onPlus : null,
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDone ? accentClr : borderClr,
            width: isDone ? 1.5 : 1,
          ),
          color: isDone ? accentClr.withOpacity(0.08) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentClr.withOpacity(0.12),
              ),
              child: Center(
                child: Text(icon, style: TextStyle(fontSize: 22.sp)),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.madB14(context, color: textClr),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '$frequencyLabel • $todayProgress / $dailyTarget',
                    style: AppTextStyles.madReg11(
                      context,
                      color: textClr.withOpacity(0.55),
                    ),
                  ),
                  SizedBox(height: 7.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 6.h,
                      backgroundColor: borderClr.withOpacity(0.25),
                      color: accentClr,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    streak > 0 ? '🔥 سلسلة $streak يوم' : 'ابدأ اليوم',
                    style: AppTextStyles.madReg11(
                      context,
                      color: textClr.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Column(
              children: [
                IconButton(
                  onPressed: !isDone?onPlus:null,
                  icon: Icon(
                    isDone
                        ? Icons.check_circle_rounded
                        : Icons.add_circle_outline_rounded,
                    color: accentClr,
                  ),
                ),
                IconButton(
                  onPressed: onMinus,
                  icon: Icon(
                    Icons.remove_circle_outline_rounded,
                    color: textClr.withOpacity(0.45),
                  ),
                ),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red.withOpacity(0.8),
                    size: 22.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}