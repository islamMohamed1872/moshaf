import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:moshaf/components/cache_helper.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/views/landing/landing_screen.dart';
import 'package:moshaf/views/settings/country_screen.dart';
import 'package:moshaf/views/settings/notifications_control_screen.dart';
import 'package:moshaf/views/settings/widgets/custom_switch.dart';
import 'package:moshaf/views/widgets/header.dart';
import '../../controllers/settings/settings_cubit.dart';
import '../../controllers/settings/settings_states.dart';
import '../../controllers/theme/theme_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        final cubit = SettingsCubit.get(context);
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Header(title: "الاعدادات",isDark: isDark,iconColor: isDark?Colors.white:Colors.black,),
                  SizedBox(
                    height: 15.h,
                  ),
                  /// 🔘 Light / Dark Mode Toggle
                  Container(
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: 4,
                      vertical: 4
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xff1C1C1C)
                          : const Color(0xff767680).withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              ThemeCubit.get(context).toggleTheme();
                            },
                            child: Container(
                              padding: EdgeInsetsDirectional.symmetric(
                                horizontal: 10,
                                vertical: 5
                              ),
                              decoration: BoxDecoration(
                                color: !isDark
                                    ? Color(0xff6C6C71)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "الوضع الفاتح",
                                style: AppTextStyles.madMd14(context,color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              CacheHelper.putBoolean(key: 'isDark', value: true);
                              context.read<ThemeCubit>().setTheme(ThemeMode.dark);
                            },
                            child: Container(
                              padding: EdgeInsetsDirectional.symmetric(
                                  horizontal: 10,
                                  vertical: 5
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "الوضع الداكن",
                                style: AppTextStyles.madMd14(context,color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// ⚙️ Settings Items
                  Expanded(
                    child: ListView(
                      children: [
                        _settingsItem(
                          context,
                          icon: Icons.person_outline,
                          label: () {
                            final user = FirebaseAuth.instance.currentUser;

                            if (user == null) {
                              // 🧘 Guest user
                              return "زائر تقبل الله منك صالح الأعمال";
                            }

                            // 🧩 Case: Apple Sign-In
                            if (user.providerData.any((p) => p.providerId == "apple.com")) {
                              // If user has displayName, use it; otherwise fallback to email
                              return user.displayName?.isNotEmpty == true
                                  ? user.displayName!
                                  : (user.email ?? "مستخدم Apple");
                            }

                            // 🟢 Case: Other sign-ins (email, Google, etc.)
                            return user.displayName?.isNotEmpty == true
                                ? user.displayName!
                                : (user.email ?? "مستخدم");
                          }(),                          isDark: isDark,
                          imagePath: "assets/images/profile.png",
                          onTap: () {

                          },
                        ),
                        _divider(isDark),
                        _settingsItem(
                          context,
                          icon: Icons.notifications_outlined,
                          label: "إشعارات التطبيق",
                          isDark: isDark,
                            imagePath: "assets/images/notifications.png",
                          onTap: () {
                            navigateTo(context, NotificationsControlScreen());
                          },
                        ),
                        _divider(isDark),
                        _settingsItem(
                          context,
                          icon: Icons.share_outlined,
                          label: "مشاركة التطبيق",
                          isDark: isDark,
                            imagePath: "assets/images/share.png",
                          subText: "(الدال على الخير كفاعله)",
                          onTap: () {
                            cubit.shareApp();
                          },
                        ),
                        _divider(isDark),
                        _settingsItem(
                          context,
                          icon: Icons.public_outlined,
                          label: "البلد",
                          isDark: isDark,
                            imagePath: "assets/images/country.png",
                          onTap: () {
                            cubit.getCountry();
                            navigateTo(context, CountryScreen());
                          },
                        ),
                        _divider(isDark),


                        /// ✅ Login
                        _settingsItem(
                          context,
                          icon: Icons.check_circle_outline,
                          label: FirebaseAuth.instance.currentUser==null?"تسجيل الدخول":"تسجيل الخروج",
                          isDark: isDark,
                            imagePath: "assets/images/login.png",
                          onTap: () {
                            if(FirebaseAuth.instance.currentUser!=null){
                              FirebaseAuth.instance.signOut();
                              GoogleSignIn.instance.signOut();
                              navigateAndFinish(context, LandingScreen());
                            }
                            else{
                              navigateTo(context, LandingScreen());
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// --- Helpers ---

  Widget _settingsItem(
      BuildContext context, {
        required IconData icon,
        required String label,
        required bool isDark,
        required String imagePath,
        required GestureTapCallback onTap,
        String? subText
      })
  {
    return InkWell(
      onTap: onTap,
      child: Row(
        spacing: 11,
        children: [
          SizedBox(
            width: 24.w,
            height: 24.w,
            child: Image.asset(imagePath),
          ),
          Text(
            label,
            style: AppTextStyles.madMd16(context,color: isDark?Colors.white:Colors.black)
          ),
          if(subText !=null)
            Text(
                subText,
                style: AppTextStyles.madMd16(context,color: Color(0xff3E3E3E))
            ),

        ],
      ),
    );
  }


  Widget _divider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Divider(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.grey.shade300,
        thickness: 1,
      ),
    );
  }
}
