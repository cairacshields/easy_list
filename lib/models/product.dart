import 'package:flutter/material.dart';
/*
  Product Object Class
 */
class Product {
  final String id;
  final String title;
  final String description;
  final double location_lat;
  final double location_lng;
  final String address;
  final double price;
  final String image;
  final String imagePath;
  final bool isFavorite;
  final String userEmail;
  final String userId;

  Product({
    @required this.id,
    @required this.title,
    @required this.description,
    @required this.location_lat,
    @required this.location_lng,
    @required this.address,
    @required this.price,
    @required this.image,
    @required this.imagePath,
    @required this.userEmail,
    @required this.userId,
    this.isFavorite = false});
}