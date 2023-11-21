
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'absensi.dart';

void main() => runApp(RekapAbsen());

class RekapAbsen extends StatefulWidget {

  @override
  _RekapAbsen createState() => _RekapAbsen();
}

class _RekapAbsen extends State<RekapAbsen> {

  int sortIndex = 0;
  bool isAscending = true;
  List<Absensi> people = [];

  sortData() {
    if (sortIndex == 0) {
      people.sort((a, b) {
        if (isAscending) {
          return a.tanggal
              .toString()
              .toLowerCase()
              .compareTo(b.tanggal.toString().toLowerCase());
        } else {
          return b.jam_masuk
              .toString()
              .toLowerCase()
              .compareTo(a.jam_masuk.toString().toLowerCase());
        }
      });
    } else {
      people.sort((a, b) {
        if (isAscending) {
          return a.jam_pulang
              .toString()
              .toLowerCase()
              .compareTo(b.jam_pulang.toString().toLowerCase());
        } else {
          return b.tanggal
              .toString()
              .toLowerCase()
              .compareTo(a.tanggal.toString().toLowerCase());
        }
      });
    }
  }

  void onSort(columnIndex, ascending) {
    sortIndex = columnIndex;
    isAscending = ascending;
    sortData();
    setState(() {});
  }

  void initState() {
    super.initState();

    getAbsensi("172002","10","2023");
  }

  late List<String> dataAbsensi;

    Future<void>getAbsensi(npp,month,year) async {

    final response = await http.post(
        Uri.parse("http://10.140.224.31/mobile-auth-api/public/api/getabsen"),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          "npp": npp,
          "month": month,
          "year": year
        })
    ).timeout(const Duration(seconds: 10));

    final output = jsonDecode(response.body);

    setState(() {
      for(var i = 0; i < 5; i++){
        people.add( Absensi(tanggal:  output[i]["tanggal"], jam_masuk:output[i]["jam_masuk"],ket_absen:output[i]["ket_absen"],jam_pulang:output[i]["jam_keluar"]));
        print(output[i]["jam_masuk"]);
      }
    });

    print(people);

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold (
      appBar: AppBar(
        title: Text("Rekap Absen"),
        backgroundColor: Color.fromRGBO(1, 101, 65, 1),
      ),
      body:
      Padding(
        padding: EdgeInsets.all(10),
        child:  SizedBox(
            width: double.infinity,
            child: DataTable(
                sortColumnIndex: sortIndex,
                sortAscending: isAscending,
                columns: [
                  DataColumn(label: Text('Tanggal')),
                  DataColumn(label: Text('Jam Masuk')),
                  DataColumn(label: Text('Keterangan')),
                  DataColumn(label: Text('Jam Pulang')),
                ],
                rows: people
                    .map((e) => DataRow(cells: [
                  DataCell(Text(e.tanggal.toString())),
                  DataCell(Text(e.jam_masuk ?? '')),
                  DataCell(Text(e.ket_absen ?? '')),
                  DataCell(Text(e.jam_pulang ?? '')),
                ])).toList()))
      )
    );
  }
}

