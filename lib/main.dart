import 'package:flutter/material.dart';

import 'package:easy_list/pages/home.dart';
import 'package:easy_list/pages/product_admin.dart';
import './pages/product_details.dart';
import 'package:easy_list/pages/auth.dart';
import 'package:scoped_model/scoped_model.dart';
import './scoped_models/main.dart';
import './models/product.dart';
import 'package:map_view/map_view.dart';


void main() {
  //Initialize maps using our API key
  MapView.setApiKey("AIzaSyAu2Bo8Pvi9Cm7SJWBRDUkKjN_-Z9gWUyA");
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  final MainModel _model = MainModel();
  bool _isAuthenticated = false;

  @override
  void initState() {
    //Attempt to auto authenticate
    _model.autoAuthenticate();
    _model.userSubject.listen((bool isAuthenticated) {
      setState(() {
        _isAuthenticated = isAuthenticated;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //We use our MainModel globally within this build function

    return ScopedModel<MainModel>(
      model: _model,
      child: MaterialApp(
        theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.red,
            accentColor: Colors.lightGreen
        ),
        //If the user is not null (they've been auto authenticated), we directly take them to the main page rather than forcing them to sign in again.
        home: !_isAuthenticated ? AuthenticationPage() : HomePage(_model),
        routes: {
          "/admin" : (BuildContext context) => !_isAuthenticated ? AuthenticationPage() : ProductAdmin(_model),
        },
        onGenerateRoute: (RouteSettings settings) {
          if(!_isAuthenticated){
            return MaterialPageRoute<bool>(builder: (BuildContext context) => AuthenticationPage());
          }
          final List<String> pathElements = settings.name.split("/");

          if(pathElements[0] != ""){
            return null;
          }

          if(pathElements[1] == "product"){
            final String productId = pathElements[2];
            final Product product = _model.allProducts.firstWhere((Product product){
                return product.id == productId;
            });

            return MaterialPageRoute<bool>(
                builder: (BuildContext context) => !_isAuthenticated ? AuthenticationPage(): ProductDetails(product)
            );
          }

          return null;
        },
        onUnknownRoute: (RouteSettings settings) {
          //Called when there is no route handler for the specific route
        },
      ),
    );
  }
}