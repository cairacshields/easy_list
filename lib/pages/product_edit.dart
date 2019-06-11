import 'package:flutter/material.dart';
import 'dart:io';
import 'package:scoped_model/scoped_model.dart';

import '../models/product.dart';
import '../scoped_models/main.dart';
import '../widgets/location_form_input.dart';
import '../models/location_model.dart';
import '../widgets/image_form_input.dart';

class ProductEditPage extends StatefulWidget {

  @override
  State<StatefulWidget> createState() {
    return _ProductEditPageState();
  }
}

class _ProductEditPageState extends State<ProductEditPage> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final Map<String, dynamic> _formData = {
    'title': null,
    'description': null,
    'price': null,
    'imageUrl':null,
    'location': null,
  };

  Widget _buildTitleInput(Product product) {
    if (product == null && _titleController.text.trim() == ""){
        _titleController.text = "";
    }else if (product != null && _titleController.text.trim() == ""){
      _titleController.text = product.title;
    }
    return TextFormField(
      decoration: InputDecoration(labelText: "Product Title"),
//      initialValue: product == null ? "" : product.title,
      controller: _titleController,
      validator: (String value) {
        if(value.isEmpty || value.length < 5){
          //Only return a value if validation fails, otherwise return nothing
          return "Title cannot be empty and must be longer than 5 characters";
        }
      },
      onSaved: (String value) {
        _formData['title'] = value;
      },
    );
  }

  Widget _buildDescriptionInput(Product product) {
    if (product == null && _descriptionController.text.trim() == ""){
      _descriptionController.text = "";
    }else if (product != null && _descriptionController.text.trim() == ""){
      _descriptionController.text = product.description;
    }

    return TextFormField(
      decoration: InputDecoration(labelText: "Product Description"),
      maxLines: 4,
      //initialValue: product == null ? "" : product.description,
      controller: _descriptionController,
      validator: (String value) {
        if(value.isEmpty || value.length < 10){
          //Only return a value if validation fails, otherwise return nothing
          return "Description cannot be empty and must be longer than 10 characters";
        }
      },
      onSaved: (String value) {
        _formData['description'] = value;
      },
    );
  }

  Widget _buildPriceInput(Product product) {
    return TextFormField(
      decoration: InputDecoration(labelText: "Product Price"),
      keyboardType: TextInputType.number,
      initialValue: product == null ? "" : product.price.toString(),
      validator: (String value) {
        if(value.isEmpty || !RegExp(r'^(?:[1-9]\d*|0)?(?:[.,]\d+)?$').hasMatch(value)){
          return "Price cannot be empty and must be a number";
        }
      },
      onSaved: (String value) {
        _formData['price'] = double.parse(value);
      },
    );
  }

  Widget _buildSubmitButton(){
    //By wrapping any widget that needs product data or functionality (adding, updating, deleting) in a ScopedModelDescendant,
    // We can use the 'Model' object that is given to us to get any values on our particular scoped model.
    //Below, for example, we use the model to get references to our addProduct and updateProduct functions
    return ScopedModelDescendant<MainModel>(builder: (BuildContext context, Widget child, MainModel model){
      return model.isLoading ? Center(child:CircularProgressIndicator()) :
      RaisedButton(
        child: Text("Create Product"),
        color: Theme.of(context).accentColor,
        textColor: Colors.white,
        onPressed: () =>_submitForm(model.addProduct, model.updateProduct, model.updateSelectedProductId, model.selectedProductIndex),
      );
    });
  }

  void _setImage(File file){
    _formData['imageUrl'] = file;
  }

  void _setProductLocation(LocationData locData) {
    _formData['location'] = locData;
  }

  void _submitForm(Function addProduct, Function updateProduct, Function updateSelectedProductId, [int selectedProductIndex]) {
    //We should check if our TextForm Fields are valid before saving state and submitting the form
      //calling validate() will return true if all the formFields pass their setup validation
    if(!_formKey.currentState.validate() ||( _formData['imageUrl'] == null && selectedProductIndex == -1)){
      //If this block returns, nothing after it will be called
      return;
    }

    //We've passed validation let's save the product info....
    //Calling save() on the form state will trigger all of the save methods for each TextFormField
    _formKey.currentState.save();

    if(selectedProductIndex == -1) {
      addProduct(
            _titleController.text,
            _descriptionController.text,
            _formData['location'],
            _formData['imageUrl'],
            _formData['price'],
          ).then((bool success) {
            if (success) {
              print(success);
              //Replace this 'ProductCreatePage' with the 'home' page
              Navigator.pushReplacementNamed(context, '/').then((_) =>
                  updateSelectedProductId(null));
            }else {
              showDialog(
                context: context,
                builder: (BuildContext context){
                  return AlertDialog(
                    title: Text("Something went wrong!"),
                    content: Text("Please try again."),
                    actions: <Widget>[
                      FlatButton(
                        onPressed: (){
                          Navigator.of(context).pop();
                        },
                        child: Text('Okay'),
                      )
                    ],
                  );
                }
              );
            }
          });
    }else{
      updateProduct(
            _titleController.text,
            _descriptionController.text,
            _formData['location'],
            _formData['imageUrl'],
            _formData['price'],
        ).then((_) =>
          //Replace this 'ProductCreatePage' with the 'home' page
          Navigator.pushReplacementNamed(context, '/').then((_) => updateSelectedProductId(null))
        );
    }
  }

  Widget _buildPageContent(BuildContext context, Product product) {
    //Get the device screen width
    final double deviceWidth = MediaQuery.of(context).size.width;
    //Calculate the target width of the form based on device screen width
    final double targetFormWidth = deviceWidth > 550.0 ? 500.0 : deviceWidth * 0.95;
    //Since listView children automatically take full width or height, we would instead need to apply padding to create space
    final double formPadding = deviceWidth - targetFormWidth;

    return GestureDetector(
      onTap: () {
        //We can use this onTap callback to detect any taps outside of the form, so that we can close the keyboard.
        //By default form elements handle their own taps, so this callback will not be triggered when we tap a part of the form... only outside of it.

        //We can clear close the keyboard by passing in an empty FocusNode to requestFocus
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Container(
        margin: EdgeInsets.all(10.0),
        child: Form(
          //The Form needs a key so that we can reference it outside
          key: _formKey,
          child: ListView(
            //We divide by 2 because the padding is supposed to be split evenly on both sides of the form
            padding: EdgeInsets.symmetric(horizontal: formPadding / 2),
            children: <Widget>[
              _buildTitleInput(product),
              _buildDescriptionInput(product),
              _buildPriceInput(product),
              SizedBox(
                height: 10.0,
              ),
              LocationInput(_setProductLocation, product),
              SizedBox(
                height: 10.0,
              ),
              ImageInput(_setImage, product),
              SizedBox(
                height: 10.0,
              ),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<MainModel>(builder: (BuildContext context, Widget child, MainModel model){
      final Widget pageContent = _buildPageContent(context, model.selectedProduct);

      return model.selectedProductIndex == -1 ? pageContent :
      Scaffold(
        appBar: AppBar(
          title: Text("Update Product"),
        ),
        body: pageContent,
      );
    });

  }
}