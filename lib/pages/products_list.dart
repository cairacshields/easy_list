import 'package:flutter/material.dart';

import './product_edit.dart';
import 'package:scoped_model/scoped_model.dart';
import '../scoped_models/main.dart';

class ProductListPage extends StatefulWidget {
  final MainModel model;

  ProductListPage(this.model);

  @override
  State<StatefulWidget> createState() {
    return _ProductListPageState();
  }
}

class _ProductListPageState extends State<ProductListPage> {

  @override
  void initState() {
    widget.model.fetchProducts();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    Widget _buildEditButton(BuildContext context, int index, MainModel model) {
      return IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              model.updateSelectedProductId(model.allProducts[index].id);
              Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (BuildContext context) {
                        return ProductEditPage();
                      }
                  )
              ).then((_) {
                model.updateSelectedProductId(null);
              });
            }
        );
    }

    return ScopedModelDescendant<MainModel>(builder: (BuildContext context, Widget child, MainModel model) {
      return ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          return Dismissible(
            //The key for dismissible just needs to be a unique way to identify each item
            key: Key(model.allProducts[index].title),
            background: Container(color: Colors.red,),
            onDismissed: (DismissDirection direction) {
              model.updateSelectedProductId(model.allProducts[index].id);
              //Left to right
              if(direction == DismissDirection.endToStart){
                model.deleteProduct();
              }
            },
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(model.allProducts[index].image),
                  ),
                  title: Text(
                      model.allProducts[index].title
                  ),
                  subtitle: Text(
                      model.allProducts[index].price.toString()
                  ),
                  trailing: _buildEditButton(context, index, model),
                ),
                Divider(),
              ],
            ),
          );
        },
        itemCount: model.allProducts.length,
      );
    });
  }
}