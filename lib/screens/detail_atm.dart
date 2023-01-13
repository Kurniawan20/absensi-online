import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../home_page.dart';
import './presence.dart';

class DetailAtm extends StatefulWidget {

  var data;

  // DetailAtm({this.luno = ""});

  DetailAtm({Key? key,required this.data}) : super(key: key);

  @override
  DetailAtmState createState() => DetailAtmState();

}

// Future<DataATM> fetchDataATM() async {
//
//   // DetailAtm luno = DetailAtm();
//   // print(luno.luno);
//
//   final String apiUrl = "http://10.171.14.243/monitoring-atm-api/public/api/atm";
//
//   final response = await http.get(Uri.parse(apiUrl+"/74"));
//
//   if (response.statusCode == 200) {
//     print(jsonDecode(response.body)['data']);
//     return DataATM.fromJson(jsonDecode(response.body)['data']);
//   } else {
//
//     throw Exception('Failed to load data');
//   }
// }

// class DataATM {
//   final String luno;
//   final String id_cab;
//   final String profile;
//   final String internalAccount;
//
//
//   const DataATM({
//     required this.luno,
//     required this.id_cab,
//     required this.profile,
//     required this.internalAccount
//   });
//
//   factory DataATM.fromJson(Map<String, dynamic> json) {
//     return DataATM(
//       luno: json['luno'],
//       id_cab: json['id_cab'],
//       profile: json['profile'],
//       internalAccount: json['internal_account']
//     );
//   }
// }

class DetailAtmState extends State<DetailAtm>{

  // late Future<DataATM> futureDataATM;
  String luno = "";

  @override
  void initState() {
    super.initState();
    // futureDataATM = fetchDataATM();
  }

  final formatCurrency = new NumberFormat.simpleCurrency(
      locale: 'id_ID'
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: Text('Detail Project'),
            backgroundColor: Colors.green,
            leading: IconButton(onPressed: () {
              Navigator.pop(context,true);
            }, icon:Icon(Icons.arrow_back)),
          ),
          body:Padding(
            padding: EdgeInsets.all(10.10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Luno : ${widget.data['luno']}',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 17,
                  ),
                ),
                SizedBox(height: 5,),
                Text('Kode Cabang : ${widget.data['id_cabang']}',
                  style: TextStyle(
                    fontSize: 17,
                  ),
                ),
                SizedBox(height: 5,),
                Text('Profile : ${widget.data['profile']} ',
                  style: TextStyle(
                    fontSize: 17,
                  ),
                ),
                SizedBox(height: 5,),
                Text('Internal Account : ${widget.data['internal_account']} ',
                  style: TextStyle(
                    fontSize: 17,
                  ),
                ),
                SizedBox(height: 5,),
                Text('Name : ${widget.data['name']}',
                  style: TextStyle(
                    fontSize: 17,
                  ),
                ),
                SizedBox(height: 5,),
                Text('Balance : ${widget.data['balance']} ',
                // Text('Balance : ${formatCurrency.format(int.parse(widget.data['balance']))} ',
                  style: TextStyle(
                    fontSize: 17,
                  ),
                ),
                SizedBox(height: 5,),
                Text('Last Update : ${( widget.data['last_update'] == null ) ? 0 :  widget.data['last_update'] } ',
                  style: TextStyle(
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
      ),
    );
  }
}