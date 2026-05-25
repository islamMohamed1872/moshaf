import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/controllers/theme/theme_cubit.dart';
import 'package:moshaf/views/rafeq/rafeq_screen.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:moshaf/views/widgets/header.dart';


class RafeqIntroScreen extends StatefulWidget {
  const RafeqIntroScreen({super.key});

  @override
  State<RafeqIntroScreen> createState() => _RafeqIntroScreenState();
}

class _RafeqIntroScreenState extends State<RafeqIntroScreen>
    with TickerProviderStateMixin {
  // ── speech lines that cycle ──────────────────────────────────────────────
  static const _lines = [
    'السلام عليكم ورحمة الله! 🌙',
    'أنا رفيق، مساعدك الإسلامي 🕌',
    'يمكنني مساعدتك في القرآن والأذكار',
    'اسألني عن أي شيء في دينك! 🤲',
    'هيا نبدأ رحلتنا معاً! ✨',
  ];

  int _lineIndex = 0;
  bool _visible = true;

  // animations
  late final AnimationController _floatCtrl;
  late final Animation<double> _floatAnim;
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;
  late final AnimationController _btnCtrl;
  late final Animation<double> _btnAnim;

  Timer? _lineTimer;

  @override
  void initState() {
    super.initState();

    // floating bob animation
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    // glow pulse
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    // button entrance
    _btnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _btnAnim = CurvedAnimation(parent: _btnCtrl, curve: Curves.elasticOut);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _btnCtrl.forward();
    });

    // cycle speech lines
    _lineTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() => _visible = false);
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        setState(() {
          _lineIndex = (_lineIndex + 1) % _lines.length;
          _visible = true;
        });
      });
    });
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _glowCtrl.dispose();
    _btnCtrl.dispose();
    _lineTimer?.cancel();
    super.dispose();
  }

  void _startChat() {
    navigateTo(context, const RafeqScreen());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeCubit.get(context).isDark;
    final gold = AppColors.isGoldMode;

    final btnColor = gold
        ? const Color(AppColors.goldPrimary)
        : const Color(AppColors.mainGreen);

    final subtitleClr = gold
        ? const Color(AppColors.goldText)
        : (isDark ? Colors.white70 : Colors.black54);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Full-screen background ──────────────────────────────────────
          Image.asset(
            'assets/images/chatbot_bg.png',
            fit: BoxFit.cover,
          ),

          // ── Dark/light scrim ────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(isDark ? 0.55 : 0.30),
                  Colors.black.withOpacity(isDark ? 0.75 : 0.50),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 30.h),
                Header(title: "", isDark: isDark),
                // ── App name ─────────────────────────────────────────────
                Text(
                  'مُستقيم',
                  style: AppTextStyles.madB24(context, color: Colors.white),
                ),
                Text(
                  'مساعدك الإسلامي الذكي',
                  style: AppTextStyles.madReg14(
                      context, color: Colors.white70),
                ),

                const Spacer(),

                // ── 3-D model / fallback character ───────────────────────
                _buildModelSection(isDark, gold),

                SizedBox(height: 16.h),

                // ── Speech bubble ────────────────────────────────────────
                _buildSpeechBubble(isDark, gold),

                const Spacer(),

                // ── Feature chips ─────────────────────────────────────────
                _buildFeatureChips(),

                SizedBox(height: 30.h),

                // ── CTA button ───────────────────────────────────────────
                ScaleTransition(
                  scale: _btnAnim,
                  child: GestureDetector(
                    onTap: _startChat,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 40.w),
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      decoration: BoxDecoration(
                        color: btnColor,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: btnColor.withOpacity(0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'ابدأ المحادثة',
                            style: AppTextStyles.madB18(
                                context, color: Colors.white),
                          ),
                          SizedBox(width: 8.w),
                          const Icon(Icons.chat_bubble_outline_rounded,
                              color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 30.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 3-D model (model_viewer_plus) or sprite fallback ─────────────────────
  Widget _buildModelSection(bool isDark, bool gold) {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatAnim, _glowAnim]),
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, _floatAnim.value),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // glow ring
              Container(
                width: 200.w,
                height: 200.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(AppColors.mainGreen)
                          .withOpacity(_glowAnim.value * 0.5),
                      blurRadius: 50,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),

              // ── Option A: 3D model (uncomment after adding package) ──

              // SizedBox(
              //   width: 220.w,
              //   height: 220.w,
              //   child: ModelViewer(
              //     src: 'assets/models/happy.glb',
              //     alt: 'رفيق',
              //     ar: false,
              //     autoRotate: true,
              //     autoRotateDelay: 0,
              //     rotationPerSecond: '20deg',
              //     cameraControls: true,
              //     backgroundColor: Colors.transparent,
              //     shadowIntensity: 0,
              //   ),
              // ),

              // ── Option B: sprite fallback (shown until GLB is added) ──
              GestureDetector(
                onTap: _startChat,
                child: Container(
                  width: 190.w,
                  height: 190.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/rafeq_happy.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              // tap hint
              Positioned(
                bottom: 6,
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'اضغط للتحدث معي 👆',
                    style: AppTextStyles.madReg12(context,
                        color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Animated speech bubble ────────────────────────────────────────────────
  Widget _buildSpeechBubble(bool isDark, bool gold) {
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.15),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 50.w),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            _lines[_lineIndex],
            textAlign: TextAlign.center,
            style: AppTextStyles.madB16(
              context,
              color: const Color(0xff1a3a2a),
            ),
          ),
        ),
      ),
    );
  }

  // ── Quick feature chips ───────────────────────────────────────────────────
  Widget _buildFeatureChips() {
    const features = [
      ('📖', 'القرآن'),
      ('🤲', 'الأذكار'),
      ('🕌', 'الصلاة'),
      ('🧭', 'القبلة'),
      ('📿', 'السبحة'),
      ('📻', 'الإذاعة'),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8.w,
        runSpacing: 8.h,
        children: features.map((f) {
          return Container(
            padding: EdgeInsets.symmetric(
                horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withOpacity(0.25)),
            ),
            child: Text(
              '${f.$1} ${f.$2}',
              style: AppTextStyles.madReg12(context,
                  color: Colors.white),
            ),
          );
        }).toList(),
      ),
    );
  }
}