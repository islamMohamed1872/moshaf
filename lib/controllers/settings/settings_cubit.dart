// ── settings_cubit.dart ──────────────────────────────────────────────────────
//
// Custom sound flow:
//   1. User picks audio file via FilePicker
//   2. File is copied to app Documents (privatePath) for audioplayers preview
//   3. Native MethodChannel inserts the file into MediaStore Notifications
//      collection → returns a content:// URI the system can always read
//   4. That content:// URI is stored and used in UriAndroidNotificationSound
//   5. On remove → contentResolver.delete() cleans up MediaStore entry
//
// This means notification sound works reliably on ALL Android versions
// without any filesystem permissions, exactly like a res/raw sound would.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:bloc/bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:moshaf/components/cache_helper.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/constants/app_colors.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/controllers/prayer_times/prayer_times_cubit.dart';
import 'package:moshaf/controllers/settings/settings_states.dart';
import 'package:moshaf/views/landing/landing_screen.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../main.dart';

class SettingsCubit extends Cubit<SettingsStates> {
  SettingsCubit() : super(SettingsInitialState());
  static SettingsCubit get(context) => BlocProvider.of(context);

  // ── Method channel to MainActivity.kt ─────────────────────────────────────
  static const _channel = MethodChannel('com.afaqalspl.moshaf/audio');

  // ── Built-in sounds ───────────────────────────────────────────────────────
  static const List<String> _builtInSounds = [
    "اذان الحرم المكي",
    "عبد الباسط عبد الصمد",
    "ناصر القطامي",
    "صالح الجعفراوي",
  ];

  static const Map<String, String> _builtInAssetMap = {
    "اذان الحرم المكي":      "azan",
    "عبد الباسط عبد الصمد": "abdullbaset",
    "ناصر القطامي":          "naser_alkatamy",
    "صالح الجعفراوي":       "saleh_algafrawy",
  };

  // ── Custom sounds ─────────────────────────────────────────────────────────
  // Each entry: {
  //   "name":        display name,
  //   "privatePath": copy in app Documents (audioplayers source),
  //   "contentUri":  content:// URI from MediaStore (notification source),
  // }
  List<Map<String, String>> customSounds = [];

  List<String> get azanSoundList =>
      [..._builtInSounds, ...customSounds.map((e) => e['name']!)];

  String azanSound = "اذان الحرم المكي";

  // Audio player for immediate demo preview
  final AudioPlayer _player = AudioPlayer();

  // ─────────────────────────────────────────────────────────────────────────
  //  Persistence
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> loadCustomSounds() async {
    final raw = await CacheHelper.getData(key: 'customSounds');
    print("RAW: $raw");

    if (raw == null) {
      customSounds = [];
    }

    // ✅ Case 1: already List
    else if (raw is List) {
      customSounds =
          raw.map((e) => Map<String, String>.from(e)).toList();
    }

    // ✅ Case 2: String (JSON)
    else if (raw is String) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        customSounds =
            decoded.map((e) => Map<String, String>.from(e)).toList();
      } catch (_) {
        customSounds = [];
      }
    }

    // ✅ Fallback
    else {
      customSounds = [];
    }

    emit(ChangeAzanSoundState());
  }

  Future<void> _saveCustomSounds() async {
    await CacheHelper.saveData(
        key: 'customSounds', value: jsonEncode(customSounds));
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Add custom sound
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> addCustomSound(BuildContext context) async {
    // 1. Pick audio file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final pickedFile = result.files.single;
    if (pickedFile.path == null) return;

    // 2. Ask display name
    final name = await _askForSoundName(context, pickedFile.name);
    if (name == null || name.trim().isEmpty) return;

    if (azanSoundList.contains(name.trim())) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("الاسم \"${name.trim()}\" مستخدم بالفعل")),
        );
      }
      return;
    }

    final trimmedName = name.trim();
    final ext = p.extension(pickedFile.path!);

    // 3. Copy to private Documents (for audioplayers — this always works)
    final docsDir = await getApplicationDocumentsDirectory();
    final privateFile = File(
        p.join(docsDir.path, 'custom_azans', '$trimmedName$ext'));
    await privateFile.parent.create(recursive: true);
    await File(pickedFile.path!).copy(privateFile.path);

    // 4. Insert into MediaStore via native channel → get content:// URI
    String contentUri = '';
    if (Platform.isAndroid) {
      try {
        final uri = await _channel.invokeMethod<String>(
          'insertNotificationSound',
          {'filePath': privateFile.path, 'displayName': trimmedName},
        );
        contentUri = uri ?? '';
        debugPrint('✅ MediaStore URI: $contentUri');
      } on PlatformException catch (e) {
        debugPrint('⚠️ MediaStore insert failed: ${e.message}');
        // contentUri stays empty — notification will use default sound
      }
    }

    // 5. Persist
    customSounds.add({
      'name':        trimmedName,
      'privatePath': privateFile.path,
      'contentUri':  contentUri,
    });
    await _saveCustomSounds();

    // 6. Select + demo
    azanSound = trimmedName;
    await CacheHelper.saveData(key: 'azanSound', value: azanSound);

    // Show notification banner (with sound if contentUri available)
    if (context.mounted) {
      await _fireDemoNotification(trimmedName, contentUri, context);
    }
    await printAudioDuration(privateFile.path);
    emit(ChangeAzanSoundState());
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Remove custom sound
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> removeCustomSound(String name, BuildContext context) async {
    final entry = customSounds.firstWhere(
          (e) => e['name'] == name,
      orElse: () => {},
    );
    if (entry.isEmpty) return;

    // Delete private copy
    try {
      final f = File(entry['privatePath'] ?? '');
      if (await f.exists()) await f.delete();
    } catch (_) {}

    // Remove from MediaStore
    final contentUri = entry['contentUri'] ?? '';
    if (Platform.isAndroid && contentUri.isNotEmpty) {
      try {
        await _channel.invokeMethod('removeNotificationSound',
            {'contentUri': contentUri});
      } on PlatformException catch (e) {
        debugPrint('⚠️ MediaStore delete failed: ${e.message}');
      }
    }

    customSounds.removeWhere((e) => e['name'] == name);
    await _saveCustomSounds();

    if (azanSound == name) {
      azanSound = _builtInSounds.first;
      await CacheHelper.saveData(key: 'azanSound', value: azanSound);
      if (context.mounted) {
        await PrayerTimesCubit.get(context).scheduleAllPrayerNotifications();
      }
    }

    emit(ChangeAzanSoundState());
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Change selected sound
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> changeAzanSound(String value, BuildContext context) async {
    azanSound = value;
    await CacheHelper.saveData(key: 'azanSound', value: value);
    await PrayerTimesCubit.get(context).scheduleAllPrayerNotifications();

    if (Platform.isAndroid) {
      final isBuiltIn = _builtInAssetMap.containsKey(value);
      if (isBuiltIn) {
        // Built-in: notification plays raw resource sound directly
        await _fireDemoNotification(value, '', context);
      } else {
        // Custom: play file immediately + send notification banner
        final entry = customSounds.firstWhere(
              (e) => e['name'] == value,
          orElse: () => {},
        );
        if (entry.isNotEmpty) {
          if (context.mounted) {
            await _fireDemoNotification(
                value, entry['contentUri'] ?? '', context);
          }
        }
      }
    }

    emit(ChangeAzanSoundState());
  }

  Future<void> getAzanSound() async {
    await loadCustomSounds();

    azanSound =
        await CacheHelper.getData(key: "azanSound") ?? _builtInSounds.first;

    emit(ChangeAzanSoundState());
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Notification sound resolution (used by scheduleAllPrayerNotifications)
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns the resolved ({channelId, sound}) for any sound name.
  /// Built-in → RawResource. Custom with contentUri → Uri. Fallback → default.
  ({String channelId, AndroidNotificationSound sound}) resolveAndroidSound(
      String displayName) {
    if (_builtInAssetMap.containsKey(displayName)) {
      final asset = _builtInAssetMap[displayName]!;
      return (
      channelId: 'prayer_channel_$asset',
      sound: RawResourceAndroidNotificationSound(asset),
      );
    }

    final entry = customSounds.firstWhere(
          (e) => e['name'] == displayName,
      orElse: () => {},
    );
    final contentUri = entry['contentUri'] ?? '';

    if (contentUri.isNotEmpty) {
      return (
      channelId: 'prayer_channel_custom_${contentUri.hashCode}',
      sound: UriAndroidNotificationSound(contentUri),
      );
    }

    // Fallback to default built-in
    return (
    channelId: 'prayer_channel_azan',
    sound: const RawResourceAndroidNotificationSound('azan'),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Private helpers
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> printAudioDuration(String path) async {
    try {
      await _player.setSource(DeviceFileSource(path));

      final duration = await _player.getDuration();

      print("🎧 Duration: ${duration?.inSeconds} seconds");
    } catch (e) {
      print("❌ Error reading duration: $e");
    }
  }
  Future<void> _fireDemoNotification(
      String displayName,
      String contentUri,
      BuildContext context,
      ) async {
    if (!Platform.isAndroid) return;
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.deleteNotificationChannel(
      'prayer_channel_custom_${displayName.hashCode}',
    );
    final plugin = FlutterLocalNotificationsPlugin();
    final isBuiltIn = _builtInAssetMap.containsKey(displayName);

    late AndroidNotificationDetails androidDetails;

    if (isBuiltIn) {
      final asset = _builtInAssetMap[displayName]!;
      androidDetails = AndroidNotificationDetails(
        'prayer_channel_$asset',
        'Prayer Times ($asset)',
        importance: Importance.max,
        priority: Priority.max,
        // autoCancel: true,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(asset),
      );
    } else if (contentUri.isNotEmpty) {
      androidDetails = AndroidNotificationDetails(
        'prayer_channel_custom_${contentUri.hashCode}',
        'Prayer Times ($displayName)',
        importance: Importance.max,
        priority: Priority.max,
        // autoCancel: true,
        playSound: true,
        sound: UriAndroidNotificationSound(contentUri,),
        additionalFlags: Int32List.fromList([4]),
          vibrationPattern: Int64List.fromList([0]),
        enableVibration: false,
          audioAttributesUsage: AudioAttributesUsage.notification
      );
    } else {
      // No URI — audio already played directly; just show a silent banner
      androidDetails = const AndroidNotificationDetails(
        'prayer_channel_preview',
        'Prayer Times Preview',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        // autoCancel: true,
        playSound: false,
      );
    }

    await plugin.show(
      DateTime.now().hashCode,
      'معاينة صوت الأذان',
      'هذا هو صوت $displayName',
      NotificationDetails(android: androidDetails),
    );
  }

  Future<String?> _askForSoundName(
      BuildContext context, String defaultName) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller =
    TextEditingController(text: p.basenameWithoutExtension(defaultName));
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
        isDark ? const Color(AppColors.scaffoldBg) : Colors.white,
        title: Text("اسم الأذان المخصص",
            style: AppTextStyles.madB14(context,
                color: isDark ? Colors.white : Colors.black)),
        content: TextField(
          controller: controller,
          cursorColor: isDark ? Colors.white : Colors.black,
          style: AppTextStyles.madReg12(context,
              color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            labelText: "الاسم",
            labelStyle: AppTextStyles.madReg12(context,
                color: isDark ? Colors.white : Colors.black),
            border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
              const BorderSide(color: Color(AppColors.mainGreen)),
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              foregroundColor: Colors.black,
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text("إلغاء",
                style:
                AppTextStyles.madReg14(context, color: Colors.black)),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: const Color(AppColors.mainGreen),
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(ctx, controller.text.trim());
            },
            child: Text("إضافة",
                style:
                AppTextStyles.madReg14(context, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Unchanged original methods ────────────────────────────────────────────

  void shareApp() async {
    String message =
        "📖 تطبيق مستقيم - اقرأ واستمع للقرآن الكريم.\nيمكنك تحميله من هنا:\n";
    if (Platform.isAndroid) {
      message +=
      "https://play.google.com/store/apps/details?id=com.afaqalspl.moshaf";
    } else if (Platform.isIOS) {
      message +=
      "https://apps.apple.com/eg/app/mostakeem-%D9%85%D8%B3%D8%AA%D9%82%D9%8A%D9%85/id6754695857";
    } else {
      message += "https://yourwebsite.com/moshaf";
    }
    SharePlus.instance.share(ShareParams(
      text: message,
      subject: "🌙 تطبيق مستقيم - للقراءة والاستماع للقرآن الكريم",
    ));
  }

  String country = "مصر";
  List<String> countries = [
    "مصر",
    "المملكة العربية السعودية",
    "الإمارات العربية المتحدة",
    "الكويت",
  ];

  void changeCountry(String value) {
    country = value;
    CacheHelper.saveData(key: 'country', value: value);
    emit(ChangeCountryState());
  }

  void getCountry() async {
    country = await CacheHelper.getData(key: "country") ?? "مصر";
    emit(ChangeCountryState());
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

  void muteNotification(String value, context) async {
    if (mutedNotifications.contains(value)) {
      if (value == notificationsOptions[0]) {
        mutedNotifications.clear();
      } else {
        mutedNotifications.remove(value);
        if (mutedNotifications.isNotEmpty &&
            mutedNotifications[0] == notificationsOptions[0] &&
            mutedNotifications.length == 1) {
          mutedNotifications.clear();
        }
      }
    } else {
      if (value == notificationsOptions[0]) {
        mutedNotifications = List.from(notificationsOptions);
      } else {
        if (!mutedNotifications.contains(notificationsOptions[0])) {
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
    final data = await CacheHelper.getData(key: "mutedNotifications") ?? [];
    if (data is List) {
      mutedNotifications = data.map((e) => e.toString()).toList();
    } else {
      mutedNotifications = [];
    }
    emit(GetNotificationState());
  }

  bool isMuted(String option, int index) => mutedNotifications.contains(option);

  Future<void> deleteUserAccount(BuildContext context, bool isDark) async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("⚠️ لم يتم العثور على مستخدم مسجّل الدخول")));
      return;
    }
    try {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()));

      bool reauthenticated = false;
      for (final provider in user.providerData) {
        if (provider.providerId == 'google.com') {
          reauthenticated = true;
          break;
        } else if (provider.providerId == 'apple.com') {
          reauthenticated = true;
          break;
        } else if (provider.providerId == 'password') {
          Navigator.pop(context);
          String? password =
          await _askForPassword(context, user.email ?? '', isDark);
          if (password == null) return;
          final credential = EmailAuthProvider.credential(
              email: user.email!, password: password);
          await user.reauthenticateWithCredential(credential);
          reauthenticated = true;
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) =>
              const Center(child: CircularProgressIndicator()));
          break;
        }
      }

      if (!reauthenticated) {
        throw Exception(
            "تعذر إعادة تسجيل الدخول. يرجى تسجيل الدخول مرة أخرى.");
      }

      await user.delete();
      await auth.signOut();
      await GoogleSignIn.instance.signOut();

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ تم حذف الحساب بنجاح")));
        navigateAndFinish(context, const LandingScreen());
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      final messages = {
        "requires-recent-login": "يجب تسجيل الدخول مجددًا قبل حذف الحساب.",
        "network-request-failed":
        "تحقق من اتصال الإنترنت وحاول مرة أخرى.",
        "user-token-expired":
        "انتهت جلسة تسجيل الدخول، يرجى إعادة تسجيل الدخول.",
        "invalid-credential": "بيانات تسجيل الدخول غير صالحة.",
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(messages[e.code] ?? e.message ?? "حدث خطأ.")));
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ خطأ: ${e.toString()}")));
    }
  }

  Future<String?> _askForPassword(
      BuildContext context, String email, bool isDark) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor:
        isDark ? const Color(AppColors.scaffoldBg) : Colors.white,
        title: Text("أدخل كلمة المرور لحذف الحساب",
            style: AppTextStyles.madB14(context,
                color: isDark ? Colors.white : Colors.black)),
        content: TextField(
          controller: controller,
          obscureText: true,
          cursorColor: isDark ? Colors.white : Colors.black,
          style: AppTextStyles.madReg12(context,
              color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            labelText: "كلمة المرور",
            labelStyle: AppTextStyles.madReg12(context,
                color: isDark ? Colors.white : Colors.black),
            border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
              const BorderSide(color: Color(AppColors.mainGreen)),
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            style: TextButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black,
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(ctx),
            child: Text("إلغاء",
                style:
                AppTextStyles.madReg14(context, color: Colors.black)),
          ),
          TextButton(
            style: TextButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(ctx, controller.text.trim());
            },
            child: Text("تأكيد",
                style:
                AppTextStyles.madReg14(context, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}