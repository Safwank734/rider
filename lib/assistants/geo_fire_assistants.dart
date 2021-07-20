import 'package:rider_app/models/nearby_available_drivers.dart';

class GeoFireAssistants {
  static List<NearByAvailableDrivers> nearbyAvailableDriversList = [];

  static void removeDriverFromList(String key) {
    int index =
        nearbyAvailableDriversList.indexWhere((element) => element.key == key);
    nearbyAvailableDriversList.removeAt(index);
  }

  static void updateDriverNearbyLocation(NearByAvailableDrivers driver){

    int index =
    nearbyAvailableDriversList.indexWhere((element) => element.key == driver.key);

    nearbyAvailableDriversList[index].latitude==driver.latitude;
    nearbyAvailableDriversList[index].longitude==driver.longitude;
  }
}
