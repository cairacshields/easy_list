import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';

class ImageInput extends StatefulWidget {
  final Function setImage;
  final Product product;

  ImageInput(this.setImage, this.product);

  @override
  State<StatefulWidget> createState() {
    return _ImageInputState();
  }
}

class _ImageInputState extends State<ImageInput> {
  File _imageFile;

  void _getImage(BuildContext context, ImageSource source) {
    ImagePicker.pickImage(source: source, maxWidth: 400.0).then((File image){
      setState(() {
        _imageFile = image;
      });
      widget.setImage(image);
      Navigator.of(context).pop();
    });
  }



  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 150.0,
            padding: EdgeInsets.all(10.0),
            child: Column(
              children: <Widget>[
                Text(
                  'Pick an image',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 10.0,
                ),
                FlatButton(
                  textColor: Theme.of(context).primaryColor,
                  child: Text('Use Camera'),
                  onPressed: () {
                    _getImage(context, ImageSource.camera);
                  },
                ),
                FlatButton(
                  textColor: Theme.of(context).primaryColor,
                  child: Text('User Gallery'),
                  onPressed: () {
                    _getImage(context, ImageSource.gallery);
                  },
                ),
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        OutlineButton(
          onPressed: () {
            _showImagePicker(context);
          },
          borderSide: BorderSide(
              style: BorderStyle.solid,
              color: Theme.of(context).accentColor,
              width: 2.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.camera_alt,
                color: Theme.of(context).accentColor,
              ),
              SizedBox(
                width: 5.0,
              ),
              Text(
                "Choose Photo",
                style: TextStyle(color: Theme.of(context).accentColor),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.0,),
        _imageFile == null ? Text('Please pick an image.') :
            Image.file(
              _imageFile,
              fit: BoxFit.cover,
              height: 300.0,
              width: MediaQuery.of(context).size.width,
              alignment: Alignment.topCenter,
            ),

      ],
    );
  }
}
