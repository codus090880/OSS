import 'package:geolocator/geolocator.dart';

class LocationUtil {
  static Future<Position?> getCurrentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
          return null;
        }
      }

      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      print('[ERROR] getCurrentPosition 실패: $e');
      return null;
    }
  }
}
