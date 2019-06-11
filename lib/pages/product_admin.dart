import 'package:flutter/material.dart';

import 'package:easy_list/pages/product_edit.dart';
import 'package:easy_list/pages/products_list.dart';
import '../scoped_models/main.dart';
import '../widgets/logout_list_tile.dart';

class ProductAdmin extends StatelessWidget {
  final MainModel model;

  ProductAdmin(this.model);

  @override
  Widget build(BuildContext context) {

    return DefaultTabController(
        length: 2,
        child: Scaffold(
        drawer: Drawer(
          child: Column(
            children: <Widget>[
              AppBar(
                title: Text("Choose"),
              ),
              ListTile(
                leading: Icon(Icons.shopping_basket),
                title: Text("Home"),
                onTap: () {
                  Navigator.pushReplacementNamed(context, "/");
                },
              ),
              Divider(),
              LogoutListTile(),
            ],
          ),
        ),
        appBar: AppBar(
          title: Text("Manage Products"),
          bottom: TabBar(tabs: <Widget>[
            Tab(text: "Create Product", icon: Icon(Icons.create),),
            Tab(text: "My Products", icon: Icon(Icons.list),),
          ],)
        ),
        body: TabBarView(
          //Number of views should be the same number of tabs and length in defaultTabController
            children: <Widget> [
              ProductEditPage(),
              ProductListPage(model),
            ]
        ),
      ),
    );
  }
}