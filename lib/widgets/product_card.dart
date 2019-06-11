import 'package:flutter/material.dart';
import './price_tag.dart';
import '../ui_elements/standard_title.dart';
import '../models/product.dart';
import 'package:scoped_model/scoped_model.dart';
import '../scoped_models/main.dart';


class ProductCard extends StatelessWidget {
  final Product product;
  final int productIndex;

  ProductCard(this.product, this.productIndex);

  @override
  Widget build(BuildContext context) {

    return ScopedModelDescendant<MainModel>(builder: (BuildContext context, Widget child, MainModel model) {
      return Card(
        child: Column(
          children: <Widget>[
            FadeInImage(
                height: 300.0,
                fit: BoxFit.cover,
                placeholder: AssetImage('assets/images/food.jpg'),
                image: NetworkImage(product.image)
            ),
            Container(
              padding: EdgeInsets.only(top: 10.0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    StandardTitle(product.title),
                    SizedBox(
                      width: 8.0,
                    ),
                    PriceTag(product.price.toString())
                  ]
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.5),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1.0),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(product.address),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.5),
              child: Text(product.userEmail),
            ),
            ButtonBar(
              alignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.info),
                  color: Theme
                      .of(context)
                      .accentColor,
                  onPressed: () {
                    Navigator.pushNamed<bool>(
                        context, "/product/" + model.allProducts[productIndex].id);
                  },
                ),
                IconButton(
                  icon: model.allProducts[productIndex].isFavorite ? Icon(
                      Icons.favorite) : Icon(Icons.favorite_border),
                  color: Colors.red,
                  onPressed: () {
                    model.updateSelectedProductId(model.allProducts[productIndex].id);
                    model.toggleProductFavoriteStatus();
                  },
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}