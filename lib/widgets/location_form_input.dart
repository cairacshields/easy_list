import 'package:flutter/material.dart';
import 'package:map_view/map_view.dart';
import 'package:http/http.dart' as http;
import '../models/location_model.dart';
import 'dart:async';
import 'dart:convert';
import '../models/product.dart';
import 'package:location/location.dart' as geoLocation;

class LocationInput extends StatefulWidget {
  final Function setLocation;
  final Product product;

  LocationInput(this.setLocation, this.product);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _LocationInputState();
  }
}

class _LocationInputState extends State<LocationInput> {
  Uri _staticMapUri;
  LocationData _locationData;
  final FocusNode _addressFocusNode = FocusNode();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    _addressFocusNode.addListener(_updateLocation);
    if(widget.product != null){
      _getStaticMap(widget.product.address, geocode: false);
    }
    super.initState();
  }

  @override
  void dispose() {
    _addressFocusNode.removeListener(_updateLocation);
    super.dispose();
  }

  Future<String> getAddress(double lng, double lat) async {
    final Uri uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json',
        //query params
        {
          'latlng' : '${lat.toString()},${lng.toString()}',
          'key' : 'AIzaSyAu2Bo8Pvi9Cm7SJWBRDUkKjN_-Z9gWUyA',
        }
    );

    final http.Response response = await http.get(uri);
    final decodedResponse = json.decode(response.body);
    print(decodedResponse);
    final formattedAddress = decodedResponse['results'][0]['formatted_address'];

    return formattedAddress;
  }

  void _getUserLocation() async {
    final location = geoLocation.Location();
    final currentLocation = await location.getLocation();
    final address = await getAddress(currentLocation.longitude, currentLocation.latitude);

    _getStaticMap(address, geocode: false, lat: currentLocation.latitude, lng: currentLocation.longitude);
  }

  void _getStaticMap(String address, {bool geocode = true, double lat, double lng}) async {
    if(address.isEmpty){
      setState(() {
        _staticMapUri = null;
      });
      widget.setLocation(null);
      return;
    }

    if(geocode){
      final Uri uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json',
          //query params
          {
            'address' : address,
            'key' : 'AIzaSyAu2Bo8Pvi9Cm7SJWBRDUkKjN_-Z9gWUyA',
          }
      );

      final http.Response response = await http.get(uri);
      final decodedResponse = json.decode(response.body);
      print(decodedResponse);
      final formattedAddress = decodedResponse['results'][0]['formatted_address'];
      final coords = decodedResponse['results'][0]['geometry']['location'];

      _locationData = LocationData(
        latitude: coords['lat'],
        longitude:  coords['lng'],
        address: formattedAddress,
      );
    }else if(lat == null && lng == null){

      _locationData = LocationData(
        latitude: widget.product.location_lat,
        longitude: widget.product.location_lng,
        address: widget.product.address
      );
    } else {
      _locationData = LocationData(
          latitude: lat,
          longitude: lng,
          address: address
      );
    }

    final StaticMapProvider staticMapViewProvider = StaticMapProvider("AIzaSyAu2Bo8Pvi9Cm7SJWBRDUkKjN_-Z9gWUyA");

    final Uri staticMapUri = staticMapViewProvider.getStaticUriWithMarkers([
          Marker('position', 'Position', _locationData.latitude, _locationData.longitude),
       ],
      center: Location(_locationData.latitude, _locationData.longitude),
      width: 500,
      height: 300,
      maptype: StaticMapViewType.roadmap
    );

    widget.setLocation(_locationData);
    setState(() {
      _addressController.text = _locationData.address;
      _staticMapUri = staticMapUri;
    });
  }

  void _updateLocation(){
    if(!_addressFocusNode.hasFocus) {
      //if we lose focus on the address textFormField, we can assume the user has entered the address
      //So we'll extract the text from the field using the textController we've assigned to it
      _getStaticMap(_addressController.text, geocode: true);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      children: <Widget>[
        TextFormField(
          focusNode: _addressFocusNode,
          controller: _addressController,
          decoration: InputDecoration(
            labelText: 'Address',
          ),
          validator: (String value) {
              if(_locationData == null || value.isEmpty){
                return "No valid location found";
              }
          },
        ),
        SizedBox(height: 10.0,),
        FlatButton(
          child: Text("Locate Me"),
          onPressed: _getUserLocation,
        ),
        SizedBox(height: 10.0,),
        _staticMapUri == null ? Container() : Image.network(_staticMapUri.toString()),
      ],
    );
  }
}