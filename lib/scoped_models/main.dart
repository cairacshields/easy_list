import 'package:scoped_model/scoped_model.dart';

import '../scoped_models/connected_products.dart';


//This MainModel class pretty much combines the contents of every single model listed after the 'with' keyword, we do this by leveraging dart mixins
//By combining each scope model into one mass scope model, we can use all the functionality as if it were in one file
class MainModel extends Model with ConnectedProductsModel ,UserModel, ProductsModel, UtilityModel {}
