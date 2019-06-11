import 'package:scoped_model/scoped_model.dart';
//By using the 'as' keyword, we can specify how to call anything inside of the given package
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:rxdart/subjects.dart';
import '../models/location_model.dart';

import '../models/product.dart';
import '../models/user.dart';
import '../models/auth.dart';

mixin ConnectedProductsModel on Model {
  List<Product> _products = [];
  String _selProductId;
  User _authenticatedUser;
  bool _isLoading = false;

  Future<bool> addProduct(String title, String description, LocationData location, File image, double price) async{
    _isLoading = true;
    notifyListeners();

    final uploadData = await uploadImage(image);

    if(uploadData == null){
      print('Upload Failed');
      return false;
    }

    final Map<String, dynamic> product = {
      'title': title,
      'description': description,
      'location_lat': location.latitude,
      'location_lng': location.longitude,
      'address': location.address,
      'imagePath' : uploadData['imagePath'],
      'imageUrl' : uploadData['imageUrl'],
      'price': price,
      'userEmail': _authenticatedUser.email,
      'userId': _authenticatedUser.id,
    };
    return http.post('https://flutter-products-bcfdd.firebaseio.com/products.json?auth=${_authenticatedUser.token}',
        body: json.encode(product)).then((http.Response response) {
          if(response.statusCode != 200 && response.statusCode != 201){
            _isLoading = false;
            notifyListeners();
            return false;
          }else {
            //We can get the response from the server by using the 'future' with .then() which returns an http.Response value
            //Note that any code that rely's on the response of a post request should be put inside of the future callback
            final Map<String, dynamic> responseData = json.decode(
                response.body);
            Product newProduct = Product(
                id: responseData['name'],
                title: title,
                description: description,
                location_lat: location.latitude,
                location_lng: location.longitude,
                address: location.address,
                image: uploadData['imageUrl'],
                imagePath: uploadData['imagePath'],
                price: price,
                userEmail: _authenticatedUser.email,
                userId: _authenticatedUser.id
            );
            _products.add(newProduct);
            _selProductId = null;
            _isLoading = false;
            //This method is provided by scope-model and is pretty much used to replace setState() which we don't use when we're relying on ScopeModel.
            //Calling this method will essentially tell any ScopeModelDescendants to redraw whatever is encapsulated inside of them.
            //We should call this inside of our model, whenever we've made a change that should be reflected on the UI.
            notifyListeners();
            return true;
          }
    });
  }

  Future<Map<String, dynamic>> uploadImage(File image, {String imagePath}) async {
    final mimeTypeData = lookupMimeType(image.path).split('/');
    final imageUploadRequest = http.MultipartRequest('POST', Uri.parse('https://us-central1-flutter-products-bcfdd.cloudfunctions.net/storeImage'));
    final file = await http.MultipartFile.fromPath(
      'image',
      image.path,
      contentType: MediaType(
        mimeTypeData[0],
        mimeTypeData[1],
      )
    );
    imageUploadRequest.files.add(file);
    if(imagePath != null){
      imageUploadRequest.fields['imagePath'] = Uri.encodeComponent(imagePath);
    }
    imageUploadRequest.headers['authorization'] = 'Bearer ${_authenticatedUser.token}';

    try {
      final streamedResponse = await imageUploadRequest.send();
      final response = await http.Response.fromStream(streamedResponse);

      if(response.statusCode != 200 || response.statusCode != 201){
        print('Something went wrong');
        print(json.decode(response.body));
        return null;
      }

      final responseData = json.decode(response.body);
      return responseData;
    }catch (error){
      print(error);
      return null;
    }
  }
}


/*
  Our Products Scoped-model
 */
mixin ProductsModel on ConnectedProductsModel {
  bool _showFavorites = false;

  //We don't want to return the actual list being managed here, so instead we
  // pretty much pass a copy using List.from() which creates a new list from another one
  List<Product> get allProducts {
    return List.from(_products);
  }

  List<Product> get displayProducts {
    if (_showFavorites) {
      //the .where() goes through each item in a list and only returns the item if the provided function returns true;
      // In our case, we'll only return the products that have isFavorited as true
      return _products.where((Product product) => product.isFavorite).toList();
    }
    return List.from(_products);
  }

  String get selectedProductId {
    return _selProductId;
  }

  Product get selectedProduct {
    if (_selProductId == null) {
      return null;
    }
    return _products.firstWhere((Product product) {
      return product.id == _selProductId;
    });
  }

  int get selectedProductIndex {
    return  _products.indexWhere((Product product) {
      return product.id == _selProductId;
    });
  }

  bool get displayFavoritesOnly {
    return _showFavorites;
  }

  Future<Null> fetchProducts({onlyForUser = false}) {
    _isLoading = true;
    notifyListeners();
    //Create a 'get' request to the server to retrieve all of our products... we must append the token from the authenticated user if our rules require authentication
    return http.get('https://flutter-products-bcfdd.firebaseio.com/products.json?auth=${_authenticatedUser.token}')
        .then<Null>((http.Response response) {
      final List<Product> fetchedProductList = [];
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (responseData == null) {
        //We've got no items :( Update loading variable to cancel spinners
        _isLoading = false;
        //Update any associated UI's/widgets
        notifyListeners();
      } else {
          //Time to parse the responseData and store it
          //We simply use a forEach loop to iterate through each value returned by the response
          //Be sure to know what structure your data is in, for us, our 'dynamic' productData is actually a Map which holds each of the product fields
          responseData.forEach((String productId, dynamic productData) {
            final Product product = Product(
                id: productId,
                title: productData['title'],
                description: productData['description'],
                location_lat: productData['location_lat'],
                location_lng: productData['location_lng'],
                address: productData['address'],
                image: productData['imageUrl'],
                imagePath: productData['imagePath'],
                price: productData['price'],
                userEmail: productData['userEmail'],
                userId: productData['userId'],
                isFavorite: productData['wishlistUsers'] == null ? false : (productData['wishlistUsers'] as Map<String, dynamic>).containsKey(_authenticatedUser.id)
            );

            fetchedProductList.add(product);
          });

        //If we only want the products created by the authenticated user, we have to return a filtered list using 'where', otherwise just return the full list of products
        _products = onlyForUser ? fetchedProductList.where((Product product) {
          return product.userId == _authenticatedUser.id;
        })  : fetchedProductList;

        //Now we assign the global products list, to the newly fetched list
        _products = fetchedProductList;
        //Update loading variable to cancel spinners
        _isLoading = false;
        //Update any associated UI's/widgets
        notifyListeners();
        _selProductId = null;
      }
    }).catchError((error){
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<bool> updateProduct(String title, String description, LocationData location,
      String image, double price) {

    _isLoading = true;
    notifyListeners();

    final Map<String, dynamic> updatedProduct = {
      'title' : title,
      'description': description,
      'location_lat': location.latitude,
      'location_lng': location.longitude,
       'address': location.address,
      'image': 'https://www.sciencenewsforstudents.org/sites/default/files/2016/11/main/articles/860_main_milkchocolate.png',
      'price': price,
      'userEmail': _authenticatedUser.email,
      'userId': _authenticatedUser.id,
    };

    return http.put('https://flutter-products-bcfdd.firebaseio.com/products/${selectedProduct.id}.json?auth=${_authenticatedUser.token}', body: json.encode(updatedProduct))
    .then((http.Response response) {
        _isLoading = false;
        Product updatedProduct = Product(
            id: selectedProduct.id,
            title: title,
            description: description,
            location_lat: location.latitude,
            location_lng: location.longitude,
            address: location.address,
            image: image,
            price: price,
            userEmail: selectedProduct.userEmail,
            userId: selectedProduct.userId
        );
      _products[selectedProductIndex] = updatedProduct;
      notifyListeners();
      return true;
    }).catchError((error){
      _isLoading = false;
      notifyListeners();
      return false;
    });
  }

  Future<bool> deleteProduct() {
    _isLoading = true;
    final deletedProductId = selectedProduct.id;
    _products.removeAt(selectedProductIndex);
    _selProductId = null;
    notifyListeners();

    return http.delete('https://flutter-products-bcfdd.firebaseio.com/products/${deletedProductId}.json?auth=${_authenticatedUser.token}')
      .then((http.Response response) {
        _isLoading = false;
        notifyListeners();
        return true;
      }).catchError((error){
        _isLoading = false;
        notifyListeners();
        return false;
      });
  }

  void toggleProductFavoriteStatus() async {
    final bool isCurrentlyFavorited = selectedProduct.isFavorite;
    final bool newFavoriteStatus = !isCurrentlyFavorited;

    //Update the favorite status immediately locally for a fast experience... can possibly be rolled back if the actual db request fails though
    final Product updatedProduct = Product(
        id: selectedProduct.id,
        title: selectedProduct.title,
        description: selectedProduct.description,
        location_lat: selectedProduct.location_lat,
        location_lng: selectedProduct.location_lng,
        address: selectedProduct.address,
        price: selectedProduct.price,
        image: selectedProduct.image,
        imagePath: selectedProduct.imagePath,
        userEmail: selectedProduct.userEmail,
        userId: selectedProduct.userId,
        isFavorite: newFavoriteStatus
    );
    _products[selectedProductIndex] = updatedProduct;
    notifyListeners();

    //Actually attempt to store the user favorite status on the db
    http.Response response;
    if(newFavoriteStatus) {
      // send request to add user to the wishlist node in db
      response = await http.put('https://flutter-products-bcfdd.firebaseio.com/products/${selectedProduct.id}/wishlistUsers/${_authenticatedUser.id}.json?auth=${_authenticatedUser.token}',
          body: json.encode(true));

    }else {
      response = await http.delete('https://flutter-products-bcfdd.firebaseio.com/products/${selectedProduct.id}/wishlistUsers/${_authenticatedUser.id}.json?auth=${_authenticatedUser.token}');
    }

    //If the db request failed... roll back the local favorite
    if(response.statusCode != 200 && response.statusCode != 201) {
      final Product updatedProduct = Product(
          id: selectedProduct.id,
          title: selectedProduct.title,
          description: selectedProduct.description,
          location_lat: selectedProduct.location_lat,
          location_lng: selectedProduct.location_lng,
          address: selectedProduct.address,
          price: selectedProduct.price,
          image: selectedProduct.image,
          imagePath: selectedProduct.imagePath,
          userEmail: selectedProduct.userEmail,
          userId: selectedProduct.userId,
          isFavorite: !newFavoriteStatus
      );
      _products[selectedProductIndex] = updatedProduct;
      notifyListeners();
    }
  }

  void updateSelectedProductId(String id) {
    _selProductId = id;
    if (id != null) {
      notifyListeners();
    }
  }

  void toggleDisplayData() {
    _showFavorites = !_showFavorites;
    notifyListeners();
  }
}

/*
    User Scope Model
 */
mixin UserModel on ConnectedProductsModel {
  Timer _authTimer;
  PublishSubject<bool> _userSubject = PublishSubject();

  User get user {
    return _authenticatedUser;
  }

  PublishSubject<bool> get userSubject {
    return _userSubject;
  }

  Future<Map<String, dynamic>> authenticate(String email, String password, [AuthMode mode = AuthMode.Login]) async {

    _isLoading = true;
    notifyListeners();

    final Map<String, dynamic> userData = {
      'email' : email,
      'password' : password,
      'returnSecureToken': true
    };

    http.Response response;

    if(mode == AuthMode.Login){
      //Using async-await is the same as using .then() for http calls... await ensures that we pause any code after the http call until a response is returned
      response = await http.post('https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyPassword?key=AIzaSyAWTAEi0iYVLX52-klgFHWh4OgmsAXWSi8',
          body: json.encode(userData),
          headers: {'Content-Type': 'application/json'}
      );
    } else {
      response = await http.post('https://www.googleapis.com/identitytoolkit/v3/relyingparty/signupNewUser?key=AIzaSyAWTAEi0iYVLX52-klgFHWh4OgmsAXWSi8',
          body: json.encode(userData),
          headers: {'Content-Type': 'application/json'}
      );
    }

    //This code will not run until await has received a response
    final Map<String, dynamic> responseData = json.decode(response.body);
    bool hasError = true;
    String message = "Something went wrong";

    if(responseData.containsKey('idToken')){
      hasError = false;
      message = "Authentication Succeeded";
      _authenticatedUser = User(id: responseData['localId'], email: email, token: responseData['idToken']);

      //We get the time in which the token expires in the 'expiresIn' value
      setAuthTimeout(int.parse(responseData['expiresIn']));

      //emmit our rxDart publishSubject, this time it will be true as we are authenticated
      _userSubject.add(true);

      //Get the current time
      final DateTime now = DateTime.now();
      //add to the current time to get a time in the future
      final DateTime expiryTime = now.add(Duration(seconds:int.parse(responseData['expiresIn'])));


      final SharedPreferences preferences = await SharedPreferences.getInstance();
      preferences.setString('token', responseData['idToken']);
      preferences.setString('userEmail', email);
      preferences.setString('userId', responseData['localId']);
      //store the expiry time as a string in preferences
      preferences.setString('expiryTime', expiryTime.toIso8601String());

    } else if (responseData['error']['message'] == 'EMAIL_EXISTS'){
      message = "Email arleady taken";
    }else if (responseData['error']['message'] == 'EMAIL_NOT_FOUND'){
      message = "Email not registered";
    } else if (responseData['error']['message'] == 'INVALID_PASSWORD'){
      message = "Password is invalid.";
    }

    _isLoading = false;
    notifyListeners();
    return {'success': !hasError, 'message': message};
  }


  void logout() async {
    _authenticatedUser = null;
    _authTimer.cancel();

    //After auto logging out, we should emmit that information using our rxDart publishSubject
    //This code will add an event of our declared type (boolean), false will indicate that the user is logged out
    _userSubject.add(false);

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.remove("token");
    preferences.remove("userEmail");
    preferences.remove("userId");
  }

  void setAuthTimeout(int time) {
    _authTimer = Timer(Duration(seconds: time), () {
      logout();
    });
  }


  //Method used to detect if there user saved in sharedPreferences in order to auto authenticate them
  void autoAuthenticate() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String token = preferences.get("token");
    final String expiryTimeString = preferences.get('expiryTime');

    if(token != null) {
      final DateTime now = DateTime.now();
      final DateTime parsedExpiryTime = DateTime.parse(expiryTimeString);
      if(parsedExpiryTime.isBefore(now)){
        //Token is expired
        _authenticatedUser = null;
        return;
      }
      final String userEmail = preferences.get("userEmail");
      final String userId = preferences.get("userId");

      //Now that we know the token isn't expired (since we've reached this code), we should get ahold of how much time is left till the token does expire
      final int tokenLifespan = parsedExpiryTime.difference(now).inSeconds;

      _authenticatedUser = User(
        id: userId,
        email: userEmail,
        token: token
      );

      //emmit our rxDart publishSubject, this time it will be true as we are authenticated
      _userSubject.add(true);
      //update the autoLogout timer with the new token lifespan
      setAuthTimeout(tokenLifespan);
      notifyListeners();
    }
  }
}

/*
  Utility class holds methods and fields for completing utility tasks
 */

mixin UtilityModel on ConnectedProductsModel {
  bool get isLoading {
    return _isLoading;
  }
}