import 'package:flutter/material.dart';
import 'dart:async';
import '../ui_elements/standard_title.dart';
import '../models/product.dart';
import 'package:map_view/map_view.dart';

class ProductDetails extends StatelessWidget {
  final Product product;

  ProductDetails(this.product);

  @override
  Widget build(BuildContext context) {


    void _showDeleteDialog() {
      //Creating an Alert Dialog in Flutter!
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Are you sure?"),
              content: Text("This action cannot be undone!"),
              actions: <Widget>[
                FlatButton(
                  child: Text("DISCARD"),
                  onPressed: () => Navigator.pop(context),
                ),
                FlatButton(
                  child: Text("CONTINUE"),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, true);
                  },
                )
              ],
            );
          }
      );
    }

    void _showMap() {
      final List<Marker> markers = <Marker>[
        Marker('position', 'Position', product.location_lat, product.location_lng),
      ];
      CameraPosition cameraPosition = CameraPosition(Location(product.location_lat, product.location_lng), 14.0);
      final MapView mapView = MapView();
      mapView.show(
          MapOptions(
            initialCameraPosition: cameraPosition,
            mapViewType: MapViewType.normal,
            title: 'Product Location'
          ),
          toolbarActions: [
            ToolbarAction('Close', 1),
          ]
      );

      mapView.onToolbarAction.listen((int id) {
         if (id == 1){
           mapView.dismiss();
         }
      });

      mapView.onMapReady.listen((_) {
        mapView.setMarkers(markers);
      });
    }

    Widget _buildTitleText(String title) {
      return Container(
        padding: EdgeInsets.all(10.0),
        child: StandardTitle(title),
      );
    }

    Widget _buildPriceText(double price) {
      return Container(
        padding: EdgeInsets.all(10.0),
        decoration: BoxDecoration(
            color: Theme.of(context).accentColor,
            borderRadius: BorderRadius.circular(5.0)
        ),
        child: Text(price.toString()),
      );
    }

    Widget _buildDescriptionText(String description) {
      return Container(
        margin: EdgeInsets.only(top: 15.0),
        child: Center(
          child: Text(
            description,
            style: TextStyle(
              fontSize: 20.0,
            ),
          ),
        ),
      );
    }

    Widget _buildLocationText(String location) {
      return Container(
        decoration: BoxDecoration(
            border: Border.all(width: 0),
            borderRadius: BorderRadius.circular(10.0)
        ),
        margin: EdgeInsets.only(top: 15.0, left: 10.0, right: 10.0),
        padding: EdgeInsets.all(5.0),
        child: GestureDetector(
          onTap: _showMap,
          child:Center(
            child: Text(
                location,
                style: TextStyle(
                  fontSize: 20.0,
                ),
              ),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () {
        Navigator.pop(context, false);
        return Future.value(false);
      },
      child:  Scaffold(
            appBar: AppBar(
              title: Text(product.title),
            ),
            body: Column(
              children: <Widget>[
                Image.network(product.image),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    _buildTitleText(product.title),
                    _buildPriceText(product.price),
                  ],
                ),
                _buildDescriptionText(product.description),
                _buildLocationText(product.address),
              ],
            )
        ),
    );
  }
}