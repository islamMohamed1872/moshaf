import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:moshaf/components/components.dart';
import 'package:moshaf/views/home/home_screen.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_textstyles.dart';
import '../../controllers/theme/theme_cubit.dart';
import '../widgets/custom_green_button.dart';

class MasjidLocatorScreen extends StatefulWidget {
  const MasjidLocatorScreen({super.key});

  @override
  State<MasjidLocatorScreen> createState() => _MasjidLocatorScreenState();
}

class _MasjidLocatorScreenState extends State<MasjidLocatorScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  String? _nearestMosqueName;
  LatLng? _nearestMosqueLatLng;
  String? _nearestMosquePlaceId;
  BitmapDescriptor? _userMarkerIcon;
  BitmapDescriptor? _mosqueMarkerIcon;
  String? _currentAddress;

  final String _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  final Dio _dio = Dio();

  bool get _isReadyToRender =>
      _currentPosition != null &&
          _userMarkerIcon != null &&
          _mosqueMarkerIcon != null;

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers();
    _checkPermissionAndLocate();
  }

  /// Converts asset to BitmapDescriptor with controlled size
  Future<BitmapDescriptor> _getBytesFromAsset(String path, int width) async {
    final ByteData data = await rootBundle.load(path);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ByteData? byteData =
    await fi.image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Future<void> _loadCustomMarkers() async {
    final userIcon =
    await _getBytesFromAsset("assets/images/user_maps_pin.png", 50);
    final mosqueIcon =
    await _getBytesFromAsset("assets/images/mosque_location_pin.png", 60);

    setState(() {
      _userMarkerIcon = userIcon;
      _mosqueMarkerIcon = mosqueIcon;
    });
  }

  Future<void> _checkPermissionAndLocate() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تفعيل خدمات الموقع (GPS)')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء السماح بالوصول للموقع')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
            Text('تم رفض الإذن بشكل دائم. الرجاء السماح من الإعدادات.')),
      );
      return;
    }

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = LatLng(pos.latitude, pos.longitude);
    });

    try {
      final placemarks =
      await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _currentAddress = "${place.locality ?? ''}, ${place.administrativeArea ?? ''}";
        });
      }
    } catch (e) {
      print("❌ Error fetching address: $e");
    }

    if (_mosqueMarkerIcon == null) {
      await _loadCustomMarkers();
    }

    await _loadNearbyMosques();
  }

  /// Load nearby mosques and compute the real nearest one using distanceBetween
  Future<void> _loadNearbyMosques() async {
    if (_currentPosition == null) return;

    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=${_currentPosition!.latitude},${_currentPosition!.longitude}'
        '&radius=3000&type=mosque&key=$_apiKey';

    try {
      final response = await _dio.get(url);
      final data = response.data;

      if (data["status"] == "OK") {
        final results = List<Map<String, dynamic>>.from(data["results"]);
        final Set<Marker> newMarkers = {};

        double? minDistanceMeters;
        LatLng? minLatLng;
        String? minPlaceId;
        String? minName;

        for (final mosque in results) {
          final location = mosque["geometry"]["location"];
          final name = mosque["name"] as String? ?? "مسجد";
          final lat = (location["lat"] as num).toDouble();
          final lng = (location["lng"] as num).toDouble();
          final placeId = mosque["place_id"] as String? ?? UniqueKey().toString();

          final marker = Marker(
            markerId: MarkerId(placeId),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(title: name),
            icon: _mosqueMarkerIcon ?? BitmapDescriptor.defaultMarker,
          );
          newMarkers.add(marker);

          // compute distance from current position to this mosque
          final dist = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            lat,
            lng,
          );

          if (minDistanceMeters == null || dist < minDistanceMeters) {
            minDistanceMeters = dist;
            minLatLng = LatLng(lat, lng);
            minPlaceId = placeId;
            minName = name;
          }
        }

        setState(() {
          _markers = newMarkers;
          // store true nearest
          _nearestMosqueLatLng = minLatLng;
          _nearestMosquePlaceId = minPlaceId;
          _nearestMosqueName = minName;
        });

        // Optionally: mark nearest with a slightly different marker (e.g. scale or tint)
        if (_nearestMosqueLatLng != null && _nearestMosquePlaceId != null) {
          // remove old nearest if exists, then add highlighted marker (same icon for now)
          final nearestMarker = Marker(
            markerId: MarkerId(_nearestMosquePlaceId!),
            position: _nearestMosqueLatLng!,
            infoWindow: InfoWindow(title: _nearestMosqueName ?? "أقرب مسجد"),
            icon: _mosqueMarkerIcon ?? BitmapDescriptor.defaultMarker,
            // you could use a different icon here if you create one
          );

          // ensure the nearest marker is in the set (replace by ID)
          _markers.removeWhere((m) => m.markerId.value == _nearestMosquePlaceId);
          _markers.add(nearestMarker);
        }
      } else {
        print("❌ Google Places API Error: ${data["status"]}");
      }
    } catch (e) {
      print("❌ Error loading mosques: $e");
    }
  }

  /// Draw route between user and the computed nearest mosque
  Future<void> _showRouteToNearestMosque() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("لم يتم تحديد موقعك بعد")),
      );
      return;
    }
    if (_nearestMosqueLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("لم يتم تحديد أقرب مسجد بعد")),
      );
      return;
    }

    final origin =
        "${_currentPosition!.latitude},${_currentPosition!.longitude}";
    final destination =
        "${_nearestMosqueLatLng!.latitude},${_nearestMosqueLatLng!.longitude}";

    final url =
        "https://maps.googleapis.com/maps/api/directions/json"
        "?origin=$origin&destination=$destination&mode=driving&key=$_apiKey";

    try {
      final response = await _dio.get(url);
      final data = response.data;

      if (data["status"] == "OK" && data["routes"] != null && data["routes"].isNotEmpty) {
        final points = data["routes"][0]["overview_polyline"]["points"] as String;
        final List<LatLng> decodedPolyline = _decodePolyline(points);

        setState(() {
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId("route"),
              points: decodedPolyline,
              color: const Color(0xff0F9D58),
              width: 5,
            ),
          );
        });

        final controller = await _controller.future;
        await controller.animateCamera(
          CameraUpdate.newLatLngBounds(
            _getPolylineBounds(decodedPolyline),
            80,
          ),
        );
      } else {
        print("❌ Directions API error: ${data["status"]}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تعذر عرض الطريق إلى المسجد")),
        );
      }
    } catch (e) {
      print("❌ Dio Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("حدث خطأ أثناء تحميل الطريق")),
      );
    }
  }

  /// Decode Google polyline into LatLng list
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polylineCoordinates = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polylineCoordinates.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polylineCoordinates;
  }

  /// Helper to fit route in screen bounds
  LatLngBounds _getPolylineBounds(List<LatLng> points) {
    double x0 = points.first.latitude;
    double x1 = points.first.latitude;
    double y0 = points.first.longitude;
    double y1 = points.first.longitude;

    for (LatLng latLng in points) {
      if (latLng.latitude > x1) x1 = latLng.latitude;
      if (latLng.latitude < x0) x0 = latLng.latitude;
      if (latLng.longitude > y1) y1 = latLng.longitude;
      if (latLng.longitude < y0) y0 = latLng.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(x0, y0),
      northeast: LatLng(x1, y1),
    );
  }

  Future<void> _goToCurrentLocation() async {
    if (_currentPosition == null) return;
    final controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentPosition!, zoom: 15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.select((ThemeCubit cubit) => cubit.isDark);
    return Scaffold(
      body: !_isReadyToRender
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        alignment: Alignment.center,
        children: [
          /// 🗺 Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition!,
              zoom: 15,
            ),
            markers: _markers
              ..add(
                Marker(
                  markerId: const MarkerId('me'),
                  position: _currentPosition!,
                  icon: _userMarkerIcon ??
                      BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueGreen),
                ),
              ),
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onMapCreated: (controller) {
              _controller.complete(controller);
            },
          ),

          /// 🏠 العودة للرئيسية
          Positioned(
            top: 50.h,
            left: 20.w,
            child: ElevatedButton(
              onPressed: () => navigateAndFinish(context, HomeScreen()),
              style: ElevatedButton.styleFrom(
                backgroundColor:isDark? Colors.black:Colors.white,
                foregroundColor: isDark? Colors.white:Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(
                    color: Color(isDark?AppColors.containerDarkBorders:AppColors.containerLightBorders),
                  ),
                ),
              ),
              child: Text(
                "العودة للرئيسية",
                style: AppTextStyles.madReg14(context,color:isDark? Colors.white:Colors.black),
              ),
            ),
          ),

          /// 🎯 Current location button
          Positioned(
            bottom: 150.h,
            left: 20.w,
            child: InkWell(
              onTap: _goToCurrentLocation,
              borderRadius: BorderRadius.circular(50),
              child: Container(
                width: 45.w,
                height: 45.w,
                decoration: BoxDecoration(
                  color: isDark? Colors.black:Colors.white,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(Icons.my_location, color: isDark? Colors.white:Colors.black),
              ),
            ),
          ),

          /// 🕌 Bottom info container
          Positioned(
            bottom: 40.h,
            left: 20.w,
            right: 20.w,
            child: Container(
              padding: EdgeInsets.all(15.w),
              decoration: BoxDecoration(
                color: isDark? Color(0xff232323):Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child:
              _polylines.isEmpty?
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentAddress ?? "جارٍ تحديد موقعك...",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.madReg16(context,color: isDark?Colors.white:Colors.black),
                  ),
                  SizedBox(height: 10.h),
                  CustomGreenButton(
                    text: "طريق اقرب مسجد",
                    onTap: _showRouteToNearestMosque,
                  ),
                ],
              ):
              Text(
                _nearestMosqueName??"",
                textAlign: TextAlign.center,
                style: AppTextStyles.madReg16(context,color: isDark? Colors.white:Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
