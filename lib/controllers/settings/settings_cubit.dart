import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moshaf/components/cache_helper.dart';
import 'package:moshaf/controllers/settings/settings_states.dart';
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
    country = await CacheHelper.getData(key: "country");
    emit(ChangeCountryState());
  }

  List notificationsOptions = [
    "",
  ];
}


