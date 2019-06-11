import 'package:flutter/material.dart';
import 'package:easy_list/widgets/products.dart';
import 'package:scoped_model/scoped_model.dart';
import '../scoped_models/main.dart';
import '../widgets/logout_list_tile.dart';


class HomePage extends StatefulWidget {
  final MainModel model;

  HomePage(this.model);

  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}


class _HomePageState extends State<HomePage> {

  //Called before most other methods in the state
  //Allows us to initialize anything that we need to before 'build()' is called
  @override
  void initState() {
    widget.model.fetchProducts();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    Widget _buildProductList() {
      return ScopedModelDescendant<MainModel>(builder: (BuildContext context, Widget child, MainModel model){
        //Wrapping our page in the refresh indicator will give us pull2refresh capabilities
        return RefreshIndicator(child: model.isLoading ? Center(child:CircularProgressIndicator()) : Products(), onRefresh: model.fetchProducts);
      });
    }

    return  Scaffold(
      //Add drawer to main toolbar
      drawer: Drawer(
        child: Column(
          children: <Widget>[
            AppBar(
              title: Text("Choose"),
              //Remove the implied leading icon
              automaticallyImplyLeading: false,
            ),
            ListTile(
              leading: Icon(Icons.create),
              title: Text("Manage Products"),
              onTap: () {
                Navigator.pushReplacementNamed(context, "/admin");
              },
            ),
            Divider(),
            LogoutListTile(),
          ],
        ),
      ),
        appBar: AppBar(
          title: Text("Easy List"),
          actions: <Widget>[
            ScopedModelDescendant<MainModel>(builder: (BuildContext context, Widget child, MainModel model){
              return IconButton(
                  icon: model.displayFavoritesOnly ? Icon(Icons.favorite): Icon(Icons.favorite_border),
                  onPressed: () {
                    model.toggleDisplayData();
                  },
              );
             }),
          ],
        ),
        body: _buildProductList()
    );
  }
}