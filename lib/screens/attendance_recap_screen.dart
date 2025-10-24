import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../bloc/attendance_recap/attendance_recap_bloc.dart';
import '../bloc/attendance_recap/attendance_recap_event.dart';
import '../bloc/attendance_recap/attendance_recap_state.dart';
import '../models/attendance_record.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'home_page.dart';
import 'page_rekap_absensi.dart';

class MonthYearPicker extends StatefulWidget {
  final int initialYear;
  final int initialMonth;
  final Function(int year, int month) onChanged;

  const MonthYearPicker({
    Key? key,
    required this.initialYear,
    required this.initialMonth,
    required this.onChanged,
  }) : super(key: key);

  @override
  _MonthYearPickerState createState() => _MonthYearPickerState();
}

class _MonthYearPickerState extends State<MonthYearPicker> {
  late int selectedYear;
  late int selectedMonth;
  
  final List<String> months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    selectedYear = widget.initialYear;
    selectedMonth = widget.initialMonth;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Year Selector
        Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: selectedYear > 2020 ? () {
                  setState(() {
                    selectedYear--;
                    widget.onChanged(selectedYear, selectedMonth);
                  });
                } : null,
                icon: Icon(Icons.chevron_left),
              ),
              Text(
                selectedYear.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color.fromRGBO(1, 101, 65, 1),
                ),
              ),
              IconButton(
                onPressed: selectedYear < DateTime.now().year ? () {
                  setState(() {
                    selectedYear++;
                    widget.onChanged(selectedYear, selectedMonth);
                  });
                } : null,
                icon: Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        Divider(),
        // Month Grid
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final monthIndex = index + 1;
              final isSelected = monthIndex == selectedMonth;
              final isCurrentMonth = selectedYear == DateTime.now().year && 
                                   monthIndex == DateTime.now().month;
              final isFutureMonth = selectedYear == DateTime.now().year && 
                                   monthIndex > DateTime.now().month;
              
              return InkWell(
                onTap: isFutureMonth ? null : () {
                  setState(() {
                    selectedMonth = monthIndex;
                    widget.onChanged(selectedYear, selectedMonth);
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Color.fromRGBO(1, 101, 65, 1)
                        : (isCurrentMonth ? Color.fromRGBO(1, 101, 65, 0.1) : Colors.transparent),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected 
                          ? Color.fromRGBO(1, 101, 65, 1)
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      months[index],
                      style: TextStyle(
                        color: isSelected 
                            ? Colors.white
                            : (isFutureMonth ? Colors.grey[400] : Colors.black87),
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

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
      print('AttendanceRecapScreen: Loading data for NPP: $npp, Year: $selectedYear, Month: $selectedMonth');
      context.read<AttendanceRecapBloc>().add(
            LoadAttendanceHistory(
              npp: npp!,
              year: int.parse(selectedYear),
              month: int.parse(selectedMonth),
            ),
          );
    } else {
      print('AttendanceRecapScreen: NPP is null, cannot load data');
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Attendance Recap'),
            Text(
              '${DateFormat('MMMM yyyy').format(DateTime(int.parse(selectedYear), int.parse(selectedMonth)))}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
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
    print('Building attendance list with ${records.length} records for $selectedYear-$selectedMonth');
    if (records.isNotEmpty) {
      print('First record date: ${records.first.date}');
      print('Last record date: ${records.last.date}');
    }
    
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
    // Initialize with current selected values
    DateTime? selectedDate = DateTime(int.parse(selectedYear), int.parse(selectedMonth));
    
    await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Pilih Bulan dan Tahun',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          content: Container(
            height: 300,
            width: 300,
            child: MonthYearPicker(
              initialYear: int.parse(selectedYear),
              initialMonth: int.parse(selectedMonth),
              onChanged: (year, month) {
                selectedDate = DateTime(year, month);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Batal',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (selectedDate != null) {
                  final newYear = selectedDate!.year.toString();
                  final newMonth = selectedDate!.month.toString().padLeft(2, '0');
                  
                  // Only update and reload if the selection actually changed
                  if (newYear != selectedYear || newMonth != selectedMonth) {
                    print('Month selection changed from $selectedYear-$selectedMonth to $newYear-$newMonth');
                    setState(() {
                      selectedYear = newYear;
                      selectedMonth = newMonth;
                    });
                    print('Loading data for: Year=$selectedYear, Month=$selectedMonth');
                    _loadAttendanceData();
                  } else {
                    print('Month selection unchanged: $selectedYear-$selectedMonth');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromRGBO(1, 101, 65, 1),
                foregroundColor: Colors.white,
              ),
              child: Text('Pilih'),
            ),
          ],
        );
      },
    );
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
