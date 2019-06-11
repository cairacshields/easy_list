import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import '../scoped_models/main.dart';
import '../models/auth.dart';


class AuthenticationPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _AuthenticationPageState();
  }
}

class _AuthenticationPageState extends State<AuthenticationPage>{

  final Map<String, dynamic> _formData = {
    'email' : null,
    'password' : null,
    'acceptsTerms': false
  };

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  AuthMode  _authMode = AuthMode.Login;


  @override
  Widget build(BuildContext context) {
    //Get the device screen width
    final double deviceWidth = MediaQuery.of(context).size.width;
    //Determine how wide the form should be based on device screen width
      //If the device's width is greater than 550 pixels, the target should be 500px
      //If the device's width is smalled than 550 pixels, the target should be 95% of the deviceWidth
    final double targetFormWidth = deviceWidth > 550.0 ? 500.0 : deviceWidth * 0.95;

    Widget _buildEmailTextField(){
      return TextFormField(
        decoration: InputDecoration(
          labelText: "Email",
          fillColor: Colors.white,
          filled: true,
        ),
        keyboardType: TextInputType.emailAddress,
        onSaved: (String value) {
          _formData['email'] = value;
        },
        validator: (String value) {
          if(value.isEmpty || !RegExp(r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?").hasMatch(value)){
            return "Email must not be empty and should be valid";
          }
        },
      );
    }

    Widget _buildPasswordTextField() {
      return TextFormField(
        decoration: InputDecoration(
          labelText: "Password",
          fillColor: Colors.white,
          filled: true,
        ),
        controller: _passwordController,
        obscureText: true,
        onSaved: (String value) {
          _formData['password'] = value;
        },
        validator: (String value) {
          if(value.isEmpty || value.length < 5){
            return "Password cannont be empty and must be longer than 5 characters";
          }
        },
      );
    }

    Widget _buildConfirmPasswordTextField() {
      return TextFormField(
        decoration: InputDecoration(
          labelText: "Confirm Password",
          fillColor: Colors.white,
          filled: true,
        ),
        obscureText: true,
        validator: (String value) {
          if(_passwordController.text != value){
            return "Password do not match.";
          }
        },
      );
    }

    void _SubmitForm(Function authenticate) async {
      if(!_formKey.currentState.validate() || ! _formData['acceptsTerms']){
        return;
      }
      _formKey.currentState.save();

      Map<String, dynamic> successData = await authenticate(_formData['email'], _formData['password'], _authMode);

        if(successData['success']){
          //Navigator.pushReplacementNamed(context, "/home");
        }else {
          showDialog(context: context, builder: (BuildContext context) {
            return AlertDialog(
              title: Text("An error occurred!"),
              content: Text(successData['message']),
              actions: <Widget>[
                FlatButton(
                  child: Text('Okay'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          });
        }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Login"),
      ),
      body: Container(
        padding: EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          image: DecorationImage(
            //Make the DecorationImage cover the entire screen
            fit: BoxFit.cover,
            //Add an overlay to the decorationImage with an opacity
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.dstATop),
            //Needs to be referenced from an AssetImage
            image: AssetImage('assets/images/background.jpg'),
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: targetFormWidth,
              child: Form(
                key: _formKey,
                child: Column(
                      children: <Widget> [
                        _buildEmailTextField(),
                        SizedBox(
                          height: 10.0,
                        ),
                        _buildPasswordTextField(),
                        SizedBox(
                          height: 10.0,
                        ),
                        _authMode == AuthMode.Signup ? _buildConfirmPasswordTextField() : Container(),
                        SwitchListTile(
                            value: _formData['acceptsTerms'],
                            onChanged: (bool value) {
                              setState(() {
                                _formData['acceptsTerms'] = value;
                              });
                            },
                            title: Text("Accept Terms"),
                        ),
                        SizedBox(
                          height: 10.0,
                        ),
                        FlatButton(
                          child: Text(
                            'Switch to ${_authMode == AuthMode.Login ? 'Signup' : 'Login'}'
                          ),
                          onPressed: () {
                            setState(() {
                              _authMode = _authMode == AuthMode.Login ? AuthMode.Signup : AuthMode.Login;
                            });
                          },
                        ),
                        SizedBox(
                          height: 10.0,
                        ),
                        ScopedModelDescendant<MainModel>(builder: (BuildContext context, Widget child, MainModel model){
                          return model.isLoading ? CircularProgressIndicator() : RaisedButton(
                            color: Theme.of(context).accentColor,
                            textColor: Colors.white,
                            child: Text(_authMode == AuthMode.Signup ? "SIGNUP" : "LOGIN"),
                            onPressed: () {
                              _SubmitForm(model.authenticate);
                            },
                          );
                        }),
                      ]
                  ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}