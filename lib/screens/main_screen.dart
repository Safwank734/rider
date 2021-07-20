import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rider_app/assistants/assistant_methods.dart';
import 'package:rider_app/assistants/geo_fire_assistants.dart';
import 'package:rider_app/const/config.dart';
import 'package:rider_app/dataHandler/app_data.dart';
import 'package:rider_app/models/direction_details.dart';
import 'package:rider_app/models/nearby_available_drivers.dart';
import 'package:rider_app/screens/login_screen.dart';
import 'package:rider_app/screens/search_screen.dart';
import 'package:rider_app/widgets/divider.dart';
import 'package:rider_app/widgets/progress_dialog.dart';

class MainScreen extends StatefulWidget {
  static const String idScreen = "main";

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController _newGoogleMapController;

  DirectionDetails tripDirectionDetails;

  //To get map  direction line
  List<LatLng> pLineCoordinates = [];
  Set<Polyline> polylineSet = {};

  //get user current location
  Position currentPosition;
  var geoLocator = Geolocator();

  double bottomPaddingOfMap = 0;

  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};

  double rideDetailsContainerHeight = 0;
  double requestRideContainerHeight = 0;
  double searchContainerHeight = 300.0;

  DatabaseReference rideRequestRef;

  BitmapDescriptor nearByIcon;

  bool nearbyAvailableDriverKeysLoaded = false;

  bool cancel = false;
  bool requestRideDetails = false;

  @override
  void initState() {
    super.initState();
    AssistantMethods.getCurrentOnlineUserInfo();
  }

  void saveRideRequest() {
    rideRequestRef =
        FirebaseDatabase.instance.reference().child("Ride Request").push();
    var pickup = Provider.of<AppData>(context, listen: false).pickUpLocation;
    var dropOff = Provider.of<AppData>(context, listen: false).dropOffLocation;

    Map pickupLocMap = {
      "latitude": pickup.latitude.toString(),
      "longitude": pickup.longitude.toString(),
    };

    Map dropOffLocMap = {
      "latitude": dropOff.latitude.toString(),
      "longitude": dropOff.longitude.toString(),
    };

    Map rideInfoMap = {
      "driver_id": "waiting",
      "payment_method": "cash",
      "pickup": pickupLocMap,
      "dropoff": dropOffLocMap,
      "created_at": DateTime.now().toString(),
      "rider_name": userCurrentInfo.name,
      "rider_phone": userCurrentInfo.phone,
      "pickup_address": pickup.placeName,
      "dropoff_address": dropOff.placeName
    };

    rideRequestRef.set(rideInfoMap);
  }

  //to-do add cancel widget when it true

  //to cancel the map
  resetApp() {
    setState(() {
      cancel = false;
      searchContainerHeight = 300.0;
      rideDetailsContainerHeight = 0;
      requestRideContainerHeight = 0;
      bottomPaddingOfMap = 230.0;

      polylineSet.clear();
      markersSet.clear();
      circlesSet.clear();
      pLineCoordinates.clear();
    });
    locatePosition();
  }

  void cancelRideRequest() {
    rideRequestRef.remove();
  }

  void displayRequestContainer() {
    setState(() {
      requestRideContainerHeight = 250;
      rideDetailsContainerHeight = 0;
      bottomPaddingOfMap = 230;
    });

    saveRideRequest();
  }

  void displayRideDetailsContainer() async {
    await getPlaceDirection();
    setState(() {
      cancel = true;
      searchContainerHeight = 0;
      rideDetailsContainerHeight = 250;
      bottomPaddingOfMap = 230.0;
    });
  }

  void locatePosition() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    currentPosition = position;

    LatLng latLngPosition = LatLng(position.latitude, position.longitude);

    CameraPosition cameraPosition =
        new CameraPosition(target: latLngPosition, zoom: 14);

    _newGoogleMapController
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    //It used to get user location address with the help of position
    String address =
        await AssistantMethods.searchCoordinateAddress(position, context);
    print("Your current address is $address");
    initGeoFireListener();
  }

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    createIconMarkers();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "RiderAPp",
          style: TextStyle(fontFamily: "Signatra"),
        ),
      ),
      drawer: Container(
        color: Colors.white,
        width: 255.0,
        child: Drawer(
          child: ListView(
            children: [
              Container(
                height: 165.0,
                child: DrawerHeader(
                  decoration: BoxDecoration(color: Colors.white),
                  child: Row(
                    children: [
                      Image.asset(
                        "assets/images/user_icon.png",
                        height: 65.0,
                        width: 65,
                      ),
                      SizedBox(
                        width: 16,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Profile Name",
                            style: TextStyle(
                                fontSize: 16, fontFamily: "Brand Bold"),
                          ),
                          SizedBox(
                            height: 6.0,
                          ),
                          Text("Visit Profile")
                        ],
                      )
                    ],
                  ),
                ),
              ),
              DividerWidget(),
              SizedBox(
                height: 12,
              ),
              //  Drawer body
              ListTile(
                leading: Icon(Icons.history),
                title: Text(
                  "History",
                  style: TextStyle(fontSize: 15.0),
                ),
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text(
                  "Visit Profile",
                  style: TextStyle(fontSize: 15.0),
                ),
              ),
              ListTile(
                leading: Icon(Icons.info),
                title: Text(
                  "About",
                  style: TextStyle(fontSize: 15.0),
                ),
              ),
              ListTile(
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                      context, LoginScreen.idScreen, (route) => false);
                },
                leading: Icon(Icons.info),
                title: Text(
                  "Sign out",
                  style: TextStyle(fontSize: 15.0),
                ),
              )
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: bottomPaddingOfMap),
            mapType: MapType.normal,
            myLocationEnabled: true,
            initialCameraPosition: _kGooglePlex,
            myLocationButtonEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            polylines: polylineSet,
            markers: markersSet,
            circles: circlesSet,
            onMapCreated: (GoogleMapController controller) {
              _controllerGoogleMap.complete(controller);
              _newGoogleMapController = controller;
              setState(() {
                bottomPaddingOfMap = 300.0;
              });
              locatePosition();
            },
          ),
          Positioned(
              right: 0,
              left: 0,
              bottom: 0,
              child: AnimatedSize(
                vsync: this,
                curve: Curves.bounceIn,
                duration: new Duration(milliseconds: 160),
                child: Container(
                  height: searchContainerHeight,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(18.0),
                          topRight: Radius.circular(18.0)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black,
                            blurRadius: 16.0,
                            spreadRadius: 0.5,
                            offset: Offset(0.7, 0.7)),
                      ]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 6.0,
                        ),
                        Text(
                          "Hi there,",
                          style: TextStyle(
                            fontSize: 12.0,
                          ),
                        ),
                        Text(
                          "Where to?",
                          style: TextStyle(
                              fontSize: 20.0, fontFamily: "Brand Bold"),
                        ),
                        SizedBox(
                          height: 20.0,
                        ),
                        GestureDetector(
                          onTap: () async {
                            var res = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SearchScreen()));
                            if (res == "obtainDirection") {
                              displayRideDetailsContainer();
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5.0),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black54,
                                      blurRadius: 6.0,
                                      spreadRadius: 0.5,
                                      offset: Offset(0.7, 0.7)),
                                ]),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search,
                                    color: Colors.blueAccent,
                                  ),
                                  SizedBox(
                                    width: 10.0,
                                  ),
                                  Text("Search  Drop off"),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 24,
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.home,
                              color: Colors.grey,
                            ),
                            SizedBox(
                              width: 12.0,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(Provider.of<AppData>(context)
                                            .pickUpLocation !=
                                        null
                                    ? Provider.of<AppData>(context)
                                        .pickUpLocation
                                        .placeName
                                    : "Add Home"),
                                SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  "Your Home Address",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12.0,
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                        SizedBox(
                          height: 10.0,
                        ),
                        DividerWidget(),
                        SizedBox(
                          height: 16.0,
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.work,
                              color: Colors.grey,
                            ),
                            SizedBox(
                              width: 12.0,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Add Work"),
                                SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  "Your Office Address",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12.0,
                                  ),
                                )
                              ],
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              )),
          Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedSize(
                vsync: this,
                curve: Curves.bounceIn,
                duration: new Duration(milliseconds: 160),
                child: Container(
                  height: rideDetailsContainerHeight,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(16),
                        topLeft: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black,
                          blurRadius: 16,
                          spreadRadius: 0.5,
                          offset: Offset(0.7, 0.7),
                        ),
                      ]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 17.0),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          color: Colors.tealAccent,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Image.asset(
                                  "assets/images/taxi.png",
                                  height: 70,
                                  width: 80,
                                ),
                                SizedBox(
                                  width: 16,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Car",
                                      style: TextStyle(
                                          fontSize: 18.0,
                                          fontFamily: "Brand Bold"),
                                    ),
                                    Text(
                                      ((tripDirectionDetails != null)
                                          ? tripDirectionDetails.distanceText
                                          : ""),
                                      style: TextStyle(
                                          fontSize: 18.0, color: Colors.grey),
                                    )
                                  ],
                                ),
                                Expanded(child: Container()),
                                Text(
                                  ((tripDirectionDetails != null)
                                      ? "\$${AssistantMethods.calculateFares(tripDirectionDetails)}"
                                      : ""),
                                  style: TextStyle(
                                      fontSize: 18.0,
                                      fontFamily: "Brand Bold",
                                      color: Colors.grey),
                                )
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 24,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Icon(
                                FontAwesomeIcons.moneyCheck,
                                size: 18,
                                color: Colors.black,
                              ),
                              SizedBox(
                                width: 16,
                              ),
                              Text("Cash"),
                              SizedBox(
                                width: 6,
                              ),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.black54,
                                size: 16,
                              )
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 24,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: ElevatedButton(
                            onPressed: () {
                              displayRequestContainer();
                            },
                            child: Padding(
                              padding: EdgeInsets.all(17),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Request",
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                  Icon(
                                    FontAwesomeIcons.taxi,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: requestRideContainerHeight,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.0),
                      topRight: Radius.circular(16.0)),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black54,
                        spreadRadius: 0.5,
                        blurRadius: 16.0,
                        offset: Offset(0.7, 0.7))
                  ]),
              child: Padding(
                padding: const EdgeInsets.all(13.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 12.0,
                    ),
                    //Animated Text using package
                    SizedBox(
                      width: double.infinity,
                      child: DefaultTextStyle(
                        style: const TextStyle(
                          fontSize: 30.0,
                          fontFamily: 'Brand Bold',
                          color: Colors.black54,
                        ),
                        child: Center(
                          child: AnimatedTextKit(
                            animatedTexts: [
                              TypewriterAnimatedText(
                                'Requesting a Ride...',
                              ),
                              TypewriterAnimatedText('Please wait...'),
                              TypewriterAnimatedText('Finding a Driver...'),
                            ],
                            onTap: () {
                              print("Tap Event");
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    GestureDetector(
                      onTap: () {
                        cancelRideRequest();
                        resetApp();
                      },
                      child: Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(width: 2, color: Colors.grey[300]),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 26,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 22,
                    ),
                    Container(
                      width: double.infinity,
                      child: Text(
                        "Cancel Ride",
                        textAlign: TextAlign.center,
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> getPlaceDirection() async {
    var initialPos =
        Provider.of<AppData>(context, listen: false).pickUpLocation;
    var finalPos = Provider.of<AppData>(context, listen: false).dropOffLocation;

    var pickUpLanLng = LatLng(initialPos.latitude, initialPos.longitude);
    var dropOffLanLng = LatLng(finalPos.latitude, finalPos.longitude);

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return ProgressDialog(
            message: " please wait...",
          );
        });

    var details = await AssistantMethods.obtainPlaceDirectionDetails(
        pickUpLanLng, dropOffLanLng);

    setState(() {
      tripDirectionDetails = details;
    });
    Navigator.pop(context);

    print("this is Encoded points");
    print(details.encodedPoint);

    //map direction to decode
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodePolylinePointResult =
        polylinePoints.decodePolyline(details.encodedPoint);

    pLineCoordinates.clear();

    if (decodePolylinePointResult.isNotEmpty) {
      decodePolylinePointResult.forEach((PointLatLng pointLatLng) {
        pLineCoordinates
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    polylineSet.clear();

    setState(() {
      Polyline polyline = Polyline(
          color: Colors.pink,
          polylineId: PolylineId("PolylineID"),
          jointType: JointType.round,
          points: pLineCoordinates,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true);

      polylineSet.add(polyline);
    });

    LatLngBounds latLngBounds;
    if (pickUpLanLng.latitude > dropOffLanLng.latitude &&
        pickUpLanLng.longitude > dropOffLanLng.longitude) {
      latLngBounds =
          LatLngBounds(southwest: dropOffLanLng, northeast: pickUpLanLng);
    } else if (pickUpLanLng.longitude > dropOffLanLng.longitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(pickUpLanLng.latitude, dropOffLanLng.longitude),
          northeast: LatLng(dropOffLanLng.latitude, pickUpLanLng.longitude));
    } else if (pickUpLanLng.latitude > dropOffLanLng.latitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(dropOffLanLng.latitude, pickUpLanLng.longitude),
          northeast: LatLng(pickUpLanLng.latitude, dropOffLanLng.longitude));
    } else {
      latLngBounds =
          LatLngBounds(southwest: pickUpLanLng, northeast: dropOffLanLng);
    }

    _newGoogleMapController
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

    Marker pickUpMarker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow:
            InfoWindow(title: initialPos.placeName, snippet: "My Location"),
        position: pickUpLanLng,
        markerId: MarkerId("pickUpID"));

    Marker dropOffMarker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow:
            InfoWindow(title: finalPos.placeName, snippet: "Drop off Location"),
        position: dropOffLanLng,
        markerId: MarkerId("dropOffID"));

    setState(() {
      markersSet.add(pickUpMarker);
      markersSet.add(dropOffMarker);
    });

    Circle pickUpCircle = Circle(
        fillColor: Colors.blueAccent,
        center: pickUpLanLng,
        radius: 12,
        strokeWidth: 4,
        strokeColor: Colors.blueAccent,
        circleId: CircleId("pickUpID"));

    Circle dropOffCircle = Circle(
        fillColor: Colors.purple,
        center: dropOffLanLng,
        radius: 12,
        strokeWidth: 4,
        strokeColor: Colors.purpleAccent,
        circleId: CircleId("dropOffID"));

    setState(() {
      circlesSet.add(pickUpCircle);
      circlesSet.add(dropOffCircle);
    });
  }

  void initGeoFireListener() {
    Geofire.initialize("availableDrivers");
    Geofire.queryAtLocation(
            currentPosition.latitude, currentPosition.longitude, 15)
        .listen((map) {
      print(map);
      if (map != null) {
        var callBack = map['callBack'];

        switch (callBack) {
          case Geofire.onKeyEntered:
            NearByAvailableDrivers nearByAvailableDrivers =
                NearByAvailableDrivers();
            nearByAvailableDrivers.key = map["key"];
            nearByAvailableDrivers.latitude = map["latitude"];
            nearByAvailableDrivers.longitude = map["longitude"];
            GeoFireAssistants.nearbyAvailableDriversList
                .add(nearByAvailableDrivers);
            if (nearbyAvailableDriverKeysLoaded == true) {
              updateAvailableDriverOnMap();
            }
            break;

          case Geofire.onKeyExited:
            GeoFireAssistants.removeDriverFromList(map["key"]);
            break;

          case Geofire.onKeyMoved:
            NearByAvailableDrivers nearByAvailableDrivers =
                NearByAvailableDrivers();
            nearByAvailableDrivers.key = map["key"];
            nearByAvailableDrivers.latitude = map["latitude"];
            nearByAvailableDrivers.longitude = map["longitude"];
            GeoFireAssistants.updateDriverNearbyLocation(
                nearByAvailableDrivers);
            updateAvailableDriverOnMap();
            break;

          case Geofire.onGeoQueryReady:
            updateAvailableDriverOnMap();

            break;
        }
      }

      setState(() {});
    });
  }

  void updateAvailableDriverOnMap() {
    setState(() {
      markersSet.clear();
    });

    Set<Marker> tMarkers = Set<Marker>();

    for (NearByAvailableDrivers driver
        in GeoFireAssistants.nearbyAvailableDriversList) {
      LatLng driverAvailablePosition =
          LatLng(driver.latitude, driver.longitude);
      Marker marker = Marker(
        markerId: MarkerId("driver${driver.key}"),
        position: driverAvailablePosition,
        icon: nearByIcon,
        rotation: AssistantMethods.createRandomNumber(360),
      );

      tMarkers.add(marker);
    }
    setState(() {
      markersSet = tMarkers;
    });
  }

  void createIconMarkers(){
    if(nearByIcon==null){
      ImageConfiguration imageConfiguration=createLocalImageConfiguration(context,size: Size(2,2));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "assets/images/car_ios.png").then((value){
        nearByIcon=value;
      });
    }
  }
}
