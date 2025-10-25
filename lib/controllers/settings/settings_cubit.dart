import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moshaf/components/cache_helper.dart';
import 'package:moshaf/controllers/settings/settings_states.dart';
import 'package:moshaf/modules/prayer_times/cubit/prayer_times_cubit.dart';
import 'package:share_plus/share_plus.dart';

class SettingsCubit extends Cubit<SettingsStates>{
  SettingsCubit() : super(SettingsInitialState());
  static SettingsCubit get(context) => BlocProvider.of(context);


  void shareApp() {
    String message = "📖 تطبيق مستقيم - اقرأ واستمع للقرآن الكريم.\nيمكنك تحميله من هنا:\n";

    if (Platform.isAndroid) {
      message += "https://play.google.com/store/apps/details?id=com.afaqalspl.moshaf";
    } else if (Platform.isIOS) {
      message += "https://apps.apple.com/app/idXXXXXXXXXX"; // <-- replace with your real App Store ID
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
    final data = await CacheHelper.getData(key: "mutedNotifications");
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

}


