import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';
import 'dart:convert';
import '../widget/dialogs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home_page.dart';

class Login extends StatefulWidget {

  const Login({Key? key}) : super(key: key);
  static const String id = 'login';

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {

  void fireToast(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }
  void fireToast2(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green.shade900,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }

  String token = "";
  String nama = "";

  doLogin(npp, password) async {

    final GlobalKey<State> _keyLoader = GlobalKey<State>();
    Dialogs.loading(context, _keyLoader, "Proses ...");

    try {
      final response = await http.post(
        // Uri.parse("http://10.101.202.28/jectment/public/api/login"),
          Uri.parse("http://10.171.14.243/monitoring-atm-api/public/api/login"),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({
            "npp": npp,
            "password": password,
          }));

      final output = jsonDecode(response.body);
      print(output);

      if (response.statusCode == 200) {

        token = output['access_token'];
        nama = output['user']['nama'];

        Navigator.of(_keyLoader.currentContext!, rootNavigator: false).pop();
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //       content: Text(
        //         'NPP :'+ output['user']['npp'] + '\n' +
        //         'NAMA :'+ output['user']['nama'] + '\n' +
        //         'Token :'+ output['access_token'],
        //         style: const TextStyle(fontSize: 16),
        //       )),
        // );

        if (output['message'] == 'authenticated') {
          saveSession(npp);
        }

      } else {

        Navigator.of(_keyLoader.currentContext!, rootNavigator: false).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                output['message'].toString(),
                style: const TextStyle(fontSize: 16),
              )),
        );
      }
    } catch (e) {
      Navigator.of(_keyLoader.currentContext!, rootNavigator: false).pop();
      Dialogs.popUp(context, '$e');
    }
  }

  // void _validateInputs() {
  //   if (_formKey.currentState!.validate()) {
  //     //If all data are correct then save data to out variables
  //     _formKey.currentState!.save();
  //
  //     doLogin(txtEditEmail.text, txtEditPwd.text);
  //   }
  // }
  var  txtEditEmail = TextEditingController();
  var  txtEditPwd = TextEditingController();

  saveSession(String npp) async {

    SharedPreferences pref = await SharedPreferences.getInstance();

    var _expired = "";

    // _token = pref.getString("token")!;
    Map<String, dynamic> payload = Jwt.parseJwt(token);
    DateTime? expiryDate = Jwt.getExpiryDate(token);

    pref.setString("npp", npp);
    pref.setString("nama", nama);
    pref.setString("token", token);
    pref.setString("expired", expiryDate.toString());
    pref.setBool("is_login", true);

    final getNpp = pref.getString('npp') ?? '';

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => const HomePage(),
      ),
          (route) => false,
    );

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.shade900,
              Colors.green,
              Colors.green.shade400,
            ],
            begin: Alignment.topLeft,
            end: Alignment.centerRight,
          ),
        ),

        child: Column(
          children: [
            /// Login & Welcome back
            Container(
              height: 210,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 35),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  /// LOGIN TEXT
                  Text('Sistem Monitoring ATM', style: TextStyle(color: Colors.white, fontSize: 30.5)),
                  SizedBox(height: 7.5),
                  /// WELCOME
                  Text('Silahkan Login', style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                ),
                child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 60),
                        /// Text Fields
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 25),
                          height: 120,
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.grey.withOpacity(0.4),
                                    blurRadius: 20,
                                    spreadRadius: 10,
                                    offset: const Offset(0, 10)
                                ),
                              ]
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              /// EMAIL
                              TextFormField(
                                  style: TextStyle(fontSize: 15),
                                  decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                      border: InputBorder.none,
                                      hintText: 'NPP',
                                      isCollapsed: false,
                                      hintStyle: TextStyle(fontSize: 14, color: Colors.grey)
                                  ),
                                  controller: txtEditEmail,
                                  onSaved: (String? val) {
                                    txtEditEmail.text = val!;
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Tidak boleh kosong';
                                    }
                                      return null;
                                  }
                              ),
                              Divider(color: Colors.black54, height: 1),
                              /// PASSWORD
                              TextFormField(
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                    border: InputBorder.none,
                                    hintText: 'Password',
                                    isCollapsed: false,
                                    hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                  controller: txtEditPwd,
                                  onSaved: (String? val) {
                                    txtEditPwd.text = val!;
                                  },
                                  obscureText: true,
                                  enableSuggestions: false,
                                  autocorrect: false,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Tidak boleh kosong';
                                    }
                                    return null;
                                  }
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 35),
                        /// LOGIN BUTTON
                        MaterialButton(
                          onPressed: () => doLogin(txtEditEmail.text, txtEditPwd.text),
                          height: 45,
                          minWidth: 240,
                          child: const Text('Login', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),),
                          textColor: Colors.white,
                          color: Colors.green.shade700,
                          shape: const StadiumBorder(),
                        ),
                        const SizedBox(height: 25),
                      ],
                    )
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
