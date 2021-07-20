import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_app/assistants/request_assistants.dart';
import 'package:rider_app/const/config.dart';
import 'package:rider_app/dataHandler/app_data.dart';
import 'package:rider_app/models/address.dart';
import 'package:rider_app/models/place_prediction.dart';
import 'package:rider_app/widgets/divider.dart';
import 'package:rider_app/widgets/progress_dialog.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController pickUpTextController = TextEditingController();
  TextEditingController dropOffTextController = TextEditingController();
  List<PlacePrediction> predictionList = [];

  @override
  Widget build(BuildContext context) {
    //Add this line
    // String placeName=Provider.of<AppData>(context).pickUpLocation.placeName??"Taliparamba";
    String placeName = "Taliparamba";
    pickUpTextController.text = placeName;
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 250,
            decoration: BoxDecoration(color: Colors.white, boxShadow: [
              BoxShadow(
                  color: Colors.black,
                  blurRadius: 6.0,
                  spreadRadius: 0.5,
                  offset: Offset(0.7, 0.7)),
            ]),
            child: Padding(
              padding: EdgeInsets.only(
                  left: 25.0, top: 30.0, right: 25.0, bottom: 20.0),
              child: Column(
                children: [
                  SizedBox(
                    height: 5.0,
                  ),
                  Stack(
                    children: [
                      GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Icon(Icons.arrow_back_ios)),
                      Center(
                        child: Text(
                          "Set Drop off",
                          style: TextStyle(
                              fontSize: 18.0, fontFamily: "Brand Bold"),
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 16.0,
                  ),
                  Row(
                    children: [
                      Image.asset(
                        "assets/images/pickicon.png",
                        height: 30,
                        width: 30,
                      ),
                      SizedBox(
                        width: 18,
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: TextField(
                              controller: pickUpTextController,
                              decoration: InputDecoration(
                                  hintText: "Pickup Location",
                                  fillColor: Colors.grey,
                                  filled: true,
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.only(
                                      left: 11.0, right: 8.0, bottom: 3.0)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    children: [
                      Image.asset(
                        "assets/images/desticon.png",
                        height: 30,
                        width: 30,
                      ),
                      SizedBox(
                        width: 18,
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: TextField(
                              onChanged: (val) {
                                findPlace(val);
                              },
                              controller: dropOffTextController,
                              decoration: InputDecoration(
                                  hintText: "Where to?",
                                  fillColor: Colors.grey,
                                  filled: true,
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.only(
                                      left: 11.0, right: 8.0, bottom: 3.0)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          //  tile for displaying predictions
          (predictionList.length > 0)
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: ListView.separated(
                    padding: EdgeInsets.all(0.0),
                    itemBuilder: (context, index) {
                      return PredictionTile(
                        placePrediction: predictionList[index],
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) =>
                        DividerWidget(),
                    itemCount: predictionList.length,
                    shrinkWrap: true,
                    physics: ClampingScrollPhysics(),
                  ),
                )
              : Container(),
        ],
      ),
    );
  }

  void findPlace(String placeName) async {
    if (placeName.length > 1) {
      String autoCompleteUrl =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=1$placeName&key=$mapKey&sessiontoken=1234567890&components=country:in";

      var res = await RequestAssistants.getRequest(autoCompleteUrl);

      if (res == "failed") {
        return;
      }
      if (res["status"] == "OK") {
        var predictions = res["predictions"];
        var placesList = (predictions as List)
            .map((json) => PlacePrediction.fromJson(json))
            .toList();
        setState(() {
          predictionList = placesList;
        });
      }
    }
  }
}

class PredictionTile extends StatelessWidget {
  final PlacePrediction placePrediction;

  const PredictionTile({Key key, this.placePrediction}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        getPlaceAddressDetails(placePrediction.place_id, context);
      },
      child: Container(
        child: Column(
          children: [
            SizedBox(
              width: 10,
            ),
            Row(
              children: [
                Icon(Icons.add_location),
                SizedBox(
                  width: 14.0,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 38.0,
                      ),
                      Text(
                        placePrediction.main_text ?? "Kannur",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16.0,
                        ),
                      ),
                      SizedBox(
                        height: 3.0,
                      ),
                      Text(
                        placePrediction.secondary_text ?? "Taliparamba",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.0, color: Colors.grey),
                      ),
                      SizedBox(
                        height: 38.0,
                      ),
                    ],
                  ),
                )
              ],
            ),
            SizedBox(
              width: 10,
            ),
          ],
        ),
      ),
    );
  }

  void getPlaceAddressDetails(String placeId, context) async {
    showDialog(
        context: context,
        builder: (BuildContext context) => ProgressDialog(
              message: "Setting DropOff, Please wait..",
            ));
    String placeDetailsUrl =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$mapKey";

    var response = await RequestAssistants.getRequest(placeDetailsUrl);

    Navigator.pop(context);
    if (response == 'failed') { 
      return;
    }

    if (response["status"] == "OK") {
      Address address = Address();
      address.placeName = response["result"]["name"];
      address.placeId = placeId;
      address.latitude = response["result"]["geometry"]["location"]["lat"];
      address.longitude = response["result"]["geometry"]["location"]["log"];

      Provider.of<AppData>(context, listen: false)
          .updateDropOffLocationAddress(address);

      Navigator.pop(context,"obtainDirection");
    }
  }
}
