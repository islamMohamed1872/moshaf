import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:moshaf/components/cache_helper.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/controllers/settings/settings_states.dart';
import 'package:moshaf/controllers/prayer_times/prayer_times_cubit.dart';
import 'package:moshaf/views/landing/landing_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:islamic_events/islamic_events.dart';

class SettingsCubit extends Cubit<SettingsStates>{
  SettingsCubit() : super(SettingsInitialState());
  static SettingsCubit get(context) => BlocProvider.of(context);


  void shareApp()async {
    String message = "📖 تطبيق مستقيم - اقرأ واستمع للقرآن الكريم.\nيمكنك تحميله من هنا:\n";

    if (Platform.isAndroid) {
      message += "https://play.google.com/store/apps/details?id=com.afaqalspl.moshaf";
    } else if (Platform.isIOS) {
      message += "https://apps.apple.com/eg/app/mostakeem-%D9%85%D8%B3%D8%AA%D9%82%D9%8A%D9%85/id6754695857";
    } else {
      message += "https://yourwebsite.com/moshaf"; // fallback for web or desktop
    }

    SharePlus.instance.share(
      ShareParams(
        text: message,
        subject: "🌙 تطبيق مستقيم - للقراءة والاستماع للقرآن الكريم",
      ),
    );
  }

  String country = "مصر";
  List<String> countries = [
    "مصر",
    "المملكة العربية السعودية",
    "الإمارات العربية المتحدة",
    "الكويت",
    ];

  void changeCountry(String value){
    country = value;
    CacheHelper.saveData(key: 'country', value: value);
    emit(ChangeCountryState());
  }
  void getCountry()async{
    country = await CacheHelper.getData(key: "country")??"مصر";
    emit(ChangeCountryState());
  }

  String azanSound = "اذان الحرم المكي";
  List<String> azanSoundList = [
    "اذان الحرم المكي",
    "عبد الباسط عبد الصمد",
    "ناصر القطامي",
    "صالح الجعفراوي",
  ];

  void changeAzanSound(String value,context)async{
    azanSound = value;
    CacheHelper.saveData(key: 'azanSound', value: value);
    await PrayerTimesCubit.get(context).scheduleAllPrayerNotifications();
   if(Platform.isAndroid){
     String audioFileName = "";

     switch(azanSound){
       case "اذان الحرم المكي":
         audioFileName = "azan";
         break;
       case "عبد الباسط عبد الصمد":
         audioFileName = "abdullbaset";
         break;
       case "ناصر القطامي":
         audioFileName = "naser_alkatamy";
         break;
       case "صالح الجعفراوي":
         audioFileName = "saleh_algafrawy";
         break;
       default:
         audioFileName = "azan";
         break;
     }
     final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
     FlutterLocalNotificationsPlugin();
     final androidDetails = AndroidNotificationDetails(
       'prayer_channel_$audioFileName',
       'Prayer Times ($audioFileName)',
       channelDescription: 'Prayer time notifications',
       importance: Importance.max,
       priority: Priority.high,
       playSound: true,
       sound: RawResourceAndroidNotificationSound(audioFileName),
     );
     final notifDetails = NotificationDetails(android: androidDetails);
     await flutterLocalNotificationsPlugin.show(
       DateTime.now().hashCode,
       'وقت الصلاة',
       'حان الآن موعد الصلاة',
       notifDetails,
     );
   }
    emit(ChangeAzanSoundState());
  }
  void getAzanSound()async{
    azanSound = await CacheHelper.getData(key: "azanSound")??"اذان الحرم المكي";
    emit(ChangeAzanSoundState());
  }

  List<String> notificationsOptions = [
    "جميع الاشعارات",
    "صلاة الفجر",
    "صلاة الظهر",
    "صلاة العصر",
    "صلاة المغرب",
    "صلاة العشاء",
    "ادعية",
    "تذكير بالمصحف",
  ];
  List<String> mutedNotifications = [];
  bool get isAllMuted => mutedNotifications.contains(notificationsOptions[0]);

  void muteNotification(String value,context) async {
    if (mutedNotifications.contains(value)) {
      /// case all notifications are turned on
      if(value == notificationsOptions[0])
        {
          mutedNotifications.clear();

        }
      else{
        /// case any other notification is turned on
        mutedNotifications.remove(value);
        /// case all notifications options are turned on so turn all all notification switch
        if(mutedNotifications[0] == notificationsOptions[0]&&mutedNotifications.length==1){
          mutedNotifications.clear();
        }
      }

    } else {
      /// case all notifications are turned off so turn off all the notifications switches
      if(value == notificationsOptions[0]){
        mutedNotifications = List.from(notificationsOptions);
      }
      else{
        /// case any notification is turned off then turn off all the notification option switch
        if(!mutedNotifications.contains(notificationsOptions[0])){
          mutedNotifications.add(notificationsOptions[0]);
        }
        mutedNotifications.add(value);
      }
    }
    CacheHelper.saveData(key: "mutedNotifications", value: mutedNotifications);
    PrayerTimesCubit.get(context).scheduleAllPrayerNotifications();
    PrayerTimesCubit.get(context).scheduleDoaaNotifications();
    emit(MuteNotificationState());
  }

  void getNotificationsState() async {
    final data = await CacheHelper.getData(key: "mutedNotifications")??[];
    print(data);

    if (data != null && data is List) {
      mutedNotifications = data.map((e) => e.toString()).toList();
    } else {
      mutedNotifications = [];
    }

    emit(GetNotificationState());
  }

  bool isMuted(String option, int index) {

    // an item is muted if the 'all' flag exists OR the item exists in mutedNotifications
    return  mutedNotifications.contains(option);
  }



  Future<void> deleteUserAccount(BuildContext context,bool isDark) async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ لم يتم العثور على مستخدم مسجّل الدخول")),
      );
      return;
    }

    try {
      // 🔹 Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final uid = user.uid;

      // ✅ STEP 1: Reauthenticate depending on provider
      bool reauthenticated = false;

      for (final provider in user.providerData) {
        final providerId = provider.providerId;

        // 🔸 GOOGLE LOGIN
        if (providerId == 'google.com') {
          try {
            // final googleSignIn = GoogleSignIn.instance;
            //
            // // Initialize with web client ID for Android:
            // await googleSignIn.initialize(
            //   serverClientId: '733056371061-b6gieovfqeh44d1qeac4962hkrcqk309.apps.googleusercontent.com',
            // );
            //
            // // Interactive sign-in:
            // final account = await googleSignIn.authenticate();
            //
            // // Authentication object:
            // final auth = await account.authentication;
            //
            // // Build Firebase credential:
            // final credential = GoogleAuthProvider.credential(
            //   idToken: auth.idToken,
            //   // accessToken: auth.accessToken,
            // );
            // await user.reauthenticateWithCredential(credential);
            reauthenticated = true;
            break;
          } catch (e) {
            debugPrint("Google reauth error: $e");
            throw Exception("فشل إعادة تسجيل الدخول باستخدام Google. حاول مرة أخرى.");
          }
        }

        // 🔸 APPLE LOGIN
        else if (providerId == 'apple.com') {
          try {
            // final appleCredential = await SignInWithApple.getAppleIDCredential(
            //   scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
            // );
            //
            // final oauthCredential = OAuthProvider("apple.com").credential(
            //   idToken: appleCredential.identityToken,
            //   accessToken: appleCredential.authorizationCode,
            // );
            //
            // await user.reauthenticateWithCredential(oauthCredential);
            reauthenticated = true;
            break;
          } catch (e) {
            debugPrint("Apple reauth error: $e");
            throw Exception("فشل إعادة تسجيل الدخول باستخدام Apple. حاول مرة أخرى.");
          }
        }

        // 🔸 EMAIL / PASSWORD LOGIN
        else if (providerId == 'password') {
          Navigator.pop(context); // close loader
          String? password = await _askForPassword(context, user.email ?? '',isDark);
          if (password == null) return;

          try {
            final credential = EmailAuthProvider.credential(
              email: user.email!,
              password: password,
            );
            await user.reauthenticateWithCredential(credential);
            reauthenticated = true;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator()),
            );
            break;
          } catch (e) {
            debugPrint("Password reauth error: $e");
            throw Exception("كلمة المرور غير صحيحة. حاول مرة أخرى.");
          }
        }
      }

      if (!reauthenticated) {
        throw Exception("تعذر إعادة تسجيل الدخول. يرجى تسجيل الدخول مرة أخرى.");
      }

      // ✅ STEP 2: Delete Firestore data (optional)
      // try {
      //   await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      // } catch (e) {
      //   debugPrint("Firestore delete error (ignored): $e");
      // }

      // Delete user
      await user.delete();

      //  Sign out and clean up
      await auth.signOut();
      await GoogleSignIn.instance.signOut();

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ تم حذف الحساب بنجاح")),
        );
        navigateAndFinish(context, const LandingScreen());
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      String message = "حدث خطأ أثناء حذف الحساب.";

      switch (e.code) {
        case "requires-recent-login":
          message = "يجب تسجيل الدخول مجددًا قبل حذف الحساب.";
          break;
        case "network-request-failed":
          message = "تحقق من اتصال الإنترنت وحاول مرة أخرى.";
          break;
        case "user-token-expired":
          message = "انتهت جلسة تسجيل الدخول، يرجى إعادة تسجيل الدخول.";
          break;
        case "invalid-credential":
          message = "بيانات تسجيل الدخول غير صالحة.";
          break;
        default:
          message = e.message ?? message;
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      Navigator.pop(context);
      debugPrint("❌ Delete account error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ خطأ: ${e.toString()}")),
      );
    }
  }

  Future<String?> _askForPassword(BuildContext context, String email,bool isDark) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark? Color(AppColors.scaffoldBg): Colors.white,
        title: Text("أدخل كلمة المرور لحذف الحساب", style: AppTextStyles.madB14(context,color: isDark?Colors.white:Colors.black),),
        content: TextField(
          controller: controller,
          obscureText: true,
          cursorColor: isDark? Colors.white: Colors.black,
          style: AppTextStyles.madReg12(context,color: isDark?Colors.white:Colors.black),
          decoration: InputDecoration(
            labelText: "كلمة المرور",
            labelStyle: AppTextStyles.madReg12(context,color: isDark?Colors.white:Colors.black),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Color(AppColors.mainGreen)
              )
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
            child:  Text("إلغاء", style: AppTextStyles.madReg14(context,color: Colors.black)),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(ctx, controller.text.trim());
            },
            child:  Text("تأكيد", style: AppTextStyles.madReg14(context,color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
}


