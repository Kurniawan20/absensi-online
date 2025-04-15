import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../bloc/attendance_recap/attendance_recap_bloc.dart';
import '../bloc/attendance_recap/attendance_recap_event.dart';
import '../bloc/attendance_recap/attendance_recap_state.dart';
import '../models/attendance_record.dart';
import 'package:intl/intl.dart';
import 'home_page.dart';
import 'page_rekap_absensi.dart';

class AttendanceRecapScreen extends StatefulWidget {
  const AttendanceRecapScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceRecapScreen> createState() => _AttendanceRecapScreenState();
}

class _AttendanceRecapScreenState extends State<AttendanceRecapScreen> {
  String selectedYear = DateTime.now().year.toString();
  String selectedMonth = DateTime.now().month.toString().padLeft(2, '0');
  String? npp;
  int _selectedIndex = 1; // Set to 1 since this is the attendance recap screen

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userNpp = prefs.getString('npp');
    if (userNpp != null) {
      setState(() {
        npp = userNpp;
      });
      _loadAttendanceData();
    }
  }

  void _loadAttendanceData() {
    if (npp != null) {
      context.read<AttendanceRecapBloc>().add(
            LoadAttendanceHistory(
              npp: npp!,
              year: int.parse(selectedYear),
              month: int.parse(selectedMonth),
            ),
          );
    }
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      switch (index) {
        case 0:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
          break;
        case 1:
          // Already on attendance recap screen
          break;
        case 2:
          // Add navigation for the third tab if needed
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Recap'),
        backgroundColor: const Color.fromRGBO(1, 101, 65, 1),
        leading: IconButton(
          icon: const Icon(FluentIcons.arrow_left_24_regular),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _showMonthYearPicker(context),
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => _showReportOptions(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadAttendanceData();
        },
        child: BlocBuilder<AttendanceRecapBloc, AttendanceRecapState>(
          builder: (context, state) {
            if (state is AttendanceRecapInitial ||
                state is AttendanceRecapLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is AttendanceRecapError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${state.message}',
                      style: const TextStyle(color: Colors.red),
                    ),
                    ElevatedButton(
                      onPressed: _loadAttendanceData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is AttendanceRecapLoaded) {
              return _buildAttendanceList(state.records);
            }

            return const Center(child: Text('No data available'));
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(FluentIcons.home_24_regular),
            activeIcon: Icon(FluentIcons.home_24_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(FluentIcons.calendar_24_regular),
            activeIcon: Icon(FluentIcons.calendar_24_filled),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(FluentIcons.person_24_regular),
            activeIcon: Icon(FluentIcons.person_24_filled),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromRGBO(1, 101, 65, 1),
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildAttendanceList(List<AttendanceRecord> records) {
    return ListView.builder(
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(
              DateFormat('dd MMMM yyyy').format(record.date),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Check In: ${record.checkInTime}'),
                Text('Check Out: ${record.checkOutTime}'),
                if (record.notes.isNotEmpty && record.notes != '-')
                  Text('Notes: ${record.notes}'),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showMonthYearPicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(int.parse(selectedYear), int.parse(selectedMonth)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        selectedYear = picked.year.toString();
        selectedMonth = picked.month.toString().padLeft(2, '0');
      });
      _loadAttendanceData();
    }
  }

  Future<void> _showReportOptions(BuildContext context) async {
    if (npp == null) return;

    final String? reportType = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Generate Report'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'pdf'),
              child: const Text('PDF Report'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'excel'),
              child: const Text('Excel Report'),
            ),
          ],
        );
      },
    );

    if (reportType != null) {
      context.read<AttendanceRecapBloc>().add(
            GenerateAttendanceReport(
              npp: npp!,
              year: int.parse(selectedYear),
              month: int.parse(selectedMonth),
              reportType: reportType,
            ),
          );
    }
  }
}
