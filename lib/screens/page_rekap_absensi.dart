import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:http/http.dart' as http;

import 'Apis.dart';

class RekapAbsensi extends StatefulWidget {
  var id;
  RekapAbsensi({Key? key, required this.id}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _RekapAbsensi();
}

class Data {

  final String userId;
  final String id;
  final String title;

  Data({required this.userId, required this.id, required this.title});

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      userId: json['tanggal'],
      id: json['jam_masuk'],
      title: json['jam_keluar'],
    );
  }
}

class _RekapAbsensi extends State<RekapAbsensi> {

  DateTime? _selected;
  late String month;
  late String year;
  late String nrk;
  late Future _doctorsFuture;
  SharedPreferences? preferences;
  late SharedPreferences _sharedPreferences;

  Future<void> _onPressed({
    required BuildContext context,
    String? locale,
  }) async {
    final localeObj = locale != null ? Locale(locale) : null;
    final selected = await showMonthYearPicker(
      builder:(context, child){return Theme( data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.light(
          primary: Color.fromRGBO(1, 101, 65, 1), // header background color
          onPrimary: Colors.white, // header text color
          onSurface: Color.fromRGBO(1, 101, 65, 1), // body text color
          onTertiary: Color.fromRGBO(1, 101, 65, 1),
          onInverseSurface: Color.fromRGBO(1, 101, 65, 1),
            onPrimaryContainer: Color.fromRGBO(1, 101, 65, 1),
          tertiaryContainer: Color.fromRGBO(1, 101, 65, 1)
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Color.fromRGBO(1, 101, 65, 1), // button text color
          ),
        ),
      ), child: child!
      );},
      context: context,
      initialDate: _selected ?? DateTime.now(),
      firstDate: DateTime(2013),
      lastDate: DateTime(2030),
      locale: localeObj,
    );

    if (selected != null) {
      setState(() {
        _selected = selected;

        var now = _selected;
        var formatter = new DateFormat('yyyy-MM');
        String formattedDate = formatter.format(now!);

        var formatterMonth = new DateFormat('MM');
        String formattedMonth = formatterMonth.format(now);

        var formatterYear = new DateFormat('yyyy');
        String formattedYear = formatterYear.format(now);

        month = formattedMonth;
        year = formattedYear;

        setState(() {
          fetchData(year, month);
        });
        dateinput.text = formattedDate;
      });
    }
  }

  TextEditingController dateinput = TextEditingController();

  void initState() {
    super.initState();

    var now = new DateTime.now();
    var formatter = new DateFormat('yyyy-MM');
    String formattedDate = formatter.format(now);

    var formatterMonth = new DateFormat('MM');
    String formattedMonth = formatterMonth.format(now);

    var formatterYear = new DateFormat('yyyy');
    String formattedYear = formatterYear.format(now);

    month = formattedMonth;
    year = formattedYear;
    dateinput.text = formattedDate;
    // _doctorsFuture = fetchData(year, month);
    fetchData(year,month);
    fetchData2(year,month);
  }
  bool isLoading = true;
  List<Data> data = [];

  final storage = const FlutterSecureStorage();

  Future fetchData(String year,String month) async {
    _sharedPreferences = await SharedPreferences.getInstance();

    var token = await storage.read(key: 'token');

    var url = Uri.parse(ApiConstants.BASE_URL+'/getabsen');
    final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token'
        },

        body: jsonEncode({"npp": "${ _sharedPreferences.getString("npp")}", "year":year,"month":month})

    );

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
        setState(() {
          data = jsonResponse.map((data) => Data.fromJson(data)).toList();
        });
    } else {
      throw Exception('Unexpected error occured!');
    }

    return response;
  }

  Future fetchData2(String year,String month) async {

    _sharedPreferences = await SharedPreferences.getInstance();
    var token = await storage.read(key: 'token');
    var url = Uri.parse(ApiConstants.BASE_URL+'/getabsen');
    final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({"npp": "${ _sharedPreferences.getString("npp")}", "year":year,"month":month})
    );

    return json.decode(utf8.decode(response.bodyBytes));
  }

  @override
  Widget build(BuildContext context) {

    var id = widget.id;
    nrk = widget.id;

    return Scaffold(
        resizeToAvoidBottomInset : false,
        appBar: AppBar(
          title: Text("Rekap Absensi",style: TextStyle(fontSize: 19,fontWeight: FontWeight.w500),),
          backgroundColor: Color.fromRGBO(1, 101, 65, 1),
        ),
        body:
          Padding(
          padding:const EdgeInsets.all(0),
          child: Column(
            children: [
            Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                          padding: const EdgeInsets.all(10),
                          child:
                          SizedBox(
                            width: 150,
                            child:
                            TextField(
                                controller: dateinput, //editing controller of this TextField
                                decoration: InputDecoration(
                                  icon: Icon(Icons.calendar_month,color: Color.fromRGBO(1, 101, 65, 1)), //icon of text field
                                  labelText: "Pilih Tanggal", //label text of field
                                  labelStyle: TextStyle(color: Color.fromRGBO(1, 101, 65, 1)),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Color.fromRGBO(1, 101, 65, 1)),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Color.fromRGBO(1, 101, 65, 1),
                                      width: 1
                                    ),
                                  ),
                                ),
                                // style: ,
                                readOnly: true,  //set it true, so that user will not able to edit text
                                onTap: () => _onPressed(context: context, locale: 'id')
                            ),
                          )
                      )
                    ],
                  ),
            FutureBuilder(
              future: fetchData2(year,month),
              builder: (_,snapshot) {
                // if (snapshot.hasData) {
                print(snapshot.connectionState);
                if (snapshot.connectionState != ConnectionState.done) {
                  return new Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children:[
                      new CircularProgressIndicator (
                              valueColor: new AlwaysStoppedAnimation<Color>(Color.fromRGBO(1,101,65,1)),
                            ),
                      // ),
                    ]
                  );
                } else if (snapshot.hasError) {

                  return new Text('Error: ${snapshot.error}');

                } else {
                  return
                  SizedBox(
                    width: double.infinity,
                    child: SingleChildScrollView(
                      // scrollDirection: Axis.horizontal,
                      // padding: EdgeInsets.all(),
                      child: PaginatedDataTable(
                          source: MyData(data),
                          columns: const [
                            DataColumn(label: Text('Tanggal',style: TextStyle(fontWeight: FontWeight.w600,),textAlign: TextAlign.center,) ),
                            DataColumn(label: Text('Jam Masuk',style: TextStyle(fontWeight: FontWeight.w600),textAlign: TextAlign.center)),
                            DataColumn(label: Text('Jam Keluar',style: TextStyle(fontWeight: FontWeight.w600),textAlign: TextAlign.center))
                          ],
                          // header: const Text('Data Absensi'),
                          // columnSpacing: 10,
                          // horizontalMargin: 50,
                          rowsPerPage: 8,
                          sortAscending: true,
                          // header: Theme(data: ThemeData.of(context)),
                        ),
                    )
                  );
                }
                // else if (snapshot.hasError) {
                //   return Text(snapshot.error.toString());
                // }
                // By default show a loading spinner.
                return Center(
                  child: const CircularProgressIndicator(),
                ) ;
              },
            )
            ],
          )

    )
    );
  }
}

class MyData extends DataTableSource {
  final List<Data> data;
  MyData(this.data);

  @override
  int get rowCount => data.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;

  @override
  DataRow getRow(int index) {
    final Data result = data[index];
    return DataRow.byIndex(index: index, cells: <DataCell>[
      DataCell(Align(child:Text(result.userId.toString(),textAlign: TextAlign.center))),
      DataCell(Align(child:Text(result.id.toString(),textAlign: TextAlign.center))),
      DataCell(Align(child:Text(result.title.toString(),textAlign: TextAlign.center))),
    ]);
  }
}