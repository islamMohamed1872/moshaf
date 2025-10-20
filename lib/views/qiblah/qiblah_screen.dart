import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class QiblahCompassScreen extends StatefulWidget {
  const QiblahCompassScreen({Key? key}) : super(key: key);

  @override
  State<QiblahCompassScreen> createState() => _QiblahCompassScreenState();
}

class _QiblahCompassScreenState extends State<QiblahCompassScreen> {
  final _locationStream = FlutterQiblah.qiblahStream;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    // Step 1: Check if location services (GPS) are ON
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      // Prompt user to enable location services
      await Geolocator.openLocationSettings();
      setState(() {
        _hasPermission = false;
      });
      return;
    }

    // Step 2: Check and request app-level permission
    final status = await Permission.locationWhenInUse.request();

    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
      });
    } else if (status.isPermanentlyDenied) {
      // Permanently denied → open settings
      await openAppSettings();
      setState(() {
        _hasPermission = false;
      });
    } else {
      // Denied → show dialog
      setState(() {
        _hasPermission = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'Please enable location access to use the Qiblah compass.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _hasPermission
            ? StreamBuilder<QiblahDirection>(
          stream: _locationStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.green),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: Text("Waiting for Qiblah data..."));
            }

            final qiblahDirection = snapshot.data!;
            final angle = (qiblahDirection.qiblah * (math.pi / 180) * -1);

            return Container(
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Directions
                  Positioned(top: 40, child: _buildDirectionText("شمال")),
                  Positioned(bottom: 40, child: _buildDirectionText("اسفل")),
                  Positioned(left: 40, child: _buildDirectionText("يسار")),
                  Positioned(right: 40, child: _buildDirectionText("يمين")),

                  // Kaaba icon at top
                  Positioned(
                    top: 120,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.green.shade900,
                      child: Image.asset(
                        'assets/images/kaabah.png',
                        width: 50,
                        height: 50,
                      ),
                    ),
                  ),

                  // Compass line and pin
                  Transform.rotate(
                    angle: angle,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 2,
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.shade900, Colors.grey],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            color: Colors.green.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        )
            : Center(
          child: ElevatedButton(
            onPressed: _checkPermission,
            child: const Text("Grant Location Permission"),
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionText(String text) => Text(
    text,
    style: const TextStyle(color: Colors.grey, fontSize: 18),
  );

  @override
  void dispose() {
    FlutterQiblah().dispose();
    super.dispose();
  }
}
