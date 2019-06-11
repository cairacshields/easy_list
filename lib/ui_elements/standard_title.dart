import 'package:flutter/material.dart';

class StandardTitle extends StatelessWidget {
  final String title;
  StandardTitle(this.title);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Text(
      title,
      style: TextStyle(
          fontSize: 26.0,
          fontWeight: FontWeight.bold
      ),
    );
  }
}