import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moshaf/controllers/qiblah/qiblah_states.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_textstyles.dart';

class QiblahCubit extends Cubit<QiblahStates>{
  QiblahCubit() : super(QiblahInitialState());
  static QiblahCubit get(context) => BlocProvider.of(context);

  bool hasPermission = false;
  bool waitingForPermissionResult = false;
  bool isPermanentlyDenied = false;

  Future<void> checkPermission(context,bool isDark) async {
    try{
      emit(CheckPermissionState());
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        waitingForPermissionResult = true;
        return;
      }

      var status = await Permission.locationWhenInUse.status;

      if (!status.isGranted) {
        status = await Permission.locationWhenInUse.request();
        showPermissionDialog(context,isDark);
        return;
      }

      if (status.isGranted) {
        hasPermission = true;
        initializeStream();
        getCurrentAddress();
        emit(GetPermissionSuccessState());
      } else if (status.isDenied) {
        showPermissionDialog(context,isDark);
        emit(ShowPermissionDialogState());
      } else if (status.isPermanentlyDenied) {
        isPermanentlyDenied = true;
        showPermissionDialog(context,isDark);
        emit(ShowPermissionDialogState());
      }
    }catch(e){
      print(e);
    }
  }


  late Stream<QiblahDirection> locationStream;

  void initializeStream() {
    locationStream = FlutterQiblah.qiblahStream;
  }

  void showPermissionDialog(context,bool isDark){
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor:isDark ? const Color(0xFF1E1E1E)   // dark mode dialog color
          : Colors.white,
      title: Text(
          'يتطلب إذن الموقع',
          textAlign: TextAlign.center,
          style: AppTextStyles.madB14(context,color: isDark?Colors.white:Colors.black),
        ),
        content: Text(
          isPermanentlyDenied
              ? 'تم رفض إذن الموقع بشكل نهائي. يرجى فتح الإعدادات وتفعيل إذن الموقع.'
              : 'من فضلك فعّل إذن الوصول إلى الموقع لاستخدام بوصلة القبلة.',
          textAlign: TextAlign.center,
          style: AppTextStyles.madReg12(context,color: isDark?Colors.white:Colors.black),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(
                Color(AppColors.mainGreen),
              ),
              shape: WidgetStateProperty.all(
                ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: Text(
              'فتح الإعدادات',
              style: AppTextStyles.madMd12(context,color: isDark?Colors.white:Colors.black),
            ),
          ),
          if (isPermanentlyDenied)
            TextButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(isDark?Colors.white:Colors.black),
                shape: WidgetStateProperty.all(
                  ContinuousRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إلغاء',
                style: AppTextStyles.madMd12(context, color:isDark?Colors.black: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
  String address = "";

  Future<void> getCurrentAddress() async {
    emit(GetAddressLoadingState());
    try {
      // ✅ Ensure permission is granted before calling this
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
           accuracy:  LocationAccuracy.high,
        ),
      );

      // Get placemarks (address details)
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

          address =
          "${place.locality}, ${place.administrativeArea}";
          print(address);
          emit(GetAddressSuccessState());
      }
    } catch (e) {
      address = "تعذر الحصول على العنوان";
      print(e);
      emit(GetAddressErrorState());
    }
  }


}
