import 'package:flutter/material.dart';
import 'package:rider_app/models/address.dart';

class AppData extends ChangeNotifier {
    late Address pickUpLocation;

  void updatePickUpLocationAddress(Address pickUpAddress) {
    pickUpLocation = pickUpAddress;
    notifyListeners();
  }
}
