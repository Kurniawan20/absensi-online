import 'dart:math' show Random;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'Apis.dart';
import 'home_page.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class RekapAbsensi extends StatefulWidget {
  final String id;
  const RekapAbsensi({Key? key, required this.id}) : super(key: key);

  @override
  _RekapAbsensiState createState() => _RekapAbsensiState();
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

class _RekapAbsensiState extends State<RekapAbsensi> {
  final storage = const FlutterSecureStorage();
  List<Data> data = [];
  List<Data> _paginatedData = [];
  bool _isLoadingOverlay = false;
  int _itemsPerPage = 10;
  int _currentPage = 1;
  late DateTimeRange _dateRange;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'On Time', 'Overdue'];
  final List<Color> _avatarColors = [
    Color(0xFFE3F2FD), // Light Blue
    Color(0xFFF3E5F5), // Light Purple
    Color(0xFFFCE4EC), // Light Pink
    Color(0xFFF1F8E9), // Light Green
    Color(0xFFFFF3E0), // Light Orange
  ];
  final Color _primaryColor = Color.fromRGBO(1, 101, 65, 1);
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Color _getAvatarColor(String userId) {
    return _avatarColors[userId.hashCode % _avatarColors.length];
  }

  void _onItemTapped(int index) {
    if (index != 1) {
      switch (index) {
        case 0:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
          break;
        case 2:
          // Add navigation for profile screen when implemented
          break;
      }
    }
  }

  bool _isOnTime(String checkInTime) {
    try {
      final timeParts = checkInTime.split(':');
      final hours = int.parse(timeParts[0]);
      final minutes = int.parse(timeParts[1]);

      // Convert to total minutes for easier comparison
      final totalMinutes = hours * 60 + minutes;
      final cutoffMinutes = 7 * 60 + 45; // 07:45 in minutes

      return totalMinutes <= cutoffMinutes;
    } catch (e) {
      return false; // If there's any error parsing the time, consider it late
    }
  }

  @override
  void initState() {
    super.initState();
    _dateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
    _fetchData(
      _dateRange.start.year.toString(),
      _dateRange.start.month.toString().padLeft(2, '0'),
      _dateRange.end.year.toString(),
      _dateRange.end.month.toString().padLeft(2, '0'),
    );
  }

  void _updatePaginatedData() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    _paginatedData = data.sublist(
      startIndex,
      endIndex > data.length ? data.length : endIndex,
    );
  }

  List<Data> _getFilteredData() {
    if (_selectedFilter == 'All' && _searchQuery.isEmpty) return _paginatedData;

    return _paginatedData.where((item) {
      bool matchesFilter = true;
      if (_selectedFilter != 'All') {
        final isOnTime = _isOnTime(item.id);
        matchesFilter = _selectedFilter == 'On Time' ? isOnTime : !isOnTime;
      }

      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        matchesSearch =
            item.userId.toLowerCase().contains(_searchQuery.toLowerCase());
      }

      return matchesFilter && matchesSearch;
    }).toList();
  }

  Future<void> _loadTokenAndFetchData() async {
    try {
      final token = await storage.read(key: 'auth_token');
      final prefs = await SharedPreferences.getInstance();
      final npp = prefs.getString('npp');

      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi anda telah berakhir. Silakan login kembali.'),
            backgroundColor: Colors.red,
          ),
        );
        // Navigate back to home page
        Navigator.pop(context);
        return;
      }

      // Use Future.microtask to avoid calling setState during build
      if (mounted) {
        Future.microtask(() => _fetchData(
              _dateRange.start.year.toString(),
              _dateRange.start.month.toString().padLeft(2, '0'),
              _dateRange.end.year.toString(),
              _dateRange.end.month.toString().padLeft(2, '0'),
            ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _fetchData(String startYear, String startMonth, String endYear,
      String endMonth) async {
    if (!mounted) return;

    setState(() {
      _isLoadingOverlay = true;
      data = [];
      _paginatedData = [];
      _currentPage = 1;
    });

    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final url = Uri.parse('${ApiConstants.BASE_URL}/getabsen');
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              "npp": widget.id,
              "start_year": startYear,
              "start_month": startMonth,
              "end_year": endYear,
              "end_month": endMonth
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse == null) {
          throw Exception('Empty response from server');
        }

        setState(() {
          try {
            data = (jsonResponse as List)
                .map<Data>((item) => Data.fromJson(item))
                .toList();
            _updatePaginatedData();
          } catch (e) {
            print('Error parsing data: $e');
            data = [];
            _paginatedData = [];
          } finally {
            _isLoadingOverlay = false;
          }
        });
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingOverlay = false;
        data = [];
        _paginatedData = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to load data: ${e.toString()}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ));
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Tanggal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                          surface: Colors.white,
                          background: Colors.white,
                        ),
                  ),
                  child: SfDateRangePicker(
                    view: DateRangePickerView.month,
                    selectionMode: DateRangePickerSelectionMode.range,
                    initialSelectedRange: PickerDateRange(
                      _dateRange.start,
                      _dateRange.end,
                    ),
                    minDate: DateTime(2020),
                    maxDate: DateTime.now(),
                    headerStyle: DateRangePickerHeaderStyle(
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.left,
                      backgroundColor: Colors.white,
                    ),
                    monthCellStyle: DateRangePickerMonthCellStyle(
                      textStyle: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                      disabledDatesTextStyle: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                      ),
                      todayTextStyle: TextStyle(
                        color: _primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      leadingDatesTextStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      trailingDatesTextStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      weekendTextStyle: TextStyle(
                        color: Colors.red[300],
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                      cellDecoration: BoxDecoration(
                        color: Colors.white,
                      ),
                      todayCellDecoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: _primaryColor,
                          width: 1,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    monthViewSettings: DateRangePickerMonthViewSettings(
                      firstDayOfWeek: 1,
                      viewHeaderHeight: 40,
                      viewHeaderStyle: DateRangePickerViewHeaderStyle(
                        textStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      dayFormat: 'EEE',
                      weekendDays: const [6, 7], // Saturday = 6, Sunday = 7
                    ),
                    selectionRadius: 20,
                    rangeSelectionColor: _primaryColor.withOpacity(0.1),
                    rangeTextStyle: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    selectionTextStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    startRangeSelectionColor: _primaryColor,
                    endRangeSelectionColor: _primaryColor,
                    todayHighlightColor: _primaryColor,
                    backgroundColor: Colors.white,
                    onSelectionChanged:
                        (DateRangePickerSelectionChangedArgs args) {
                      if (args.value is PickerDateRange &&
                          args.value.startDate != null) {
                        final startDate = args.value.startDate!;
                        final endDate = args.value.endDate ?? startDate;
                        setState(() {
                          _dateRange = DateTimeRange(
                            start: startDate,
                            end: endDate,
                          );
                        });
                      }
                    },
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, _dateRange);
                          },
                          child: Text(
                            'Submit',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );

    if (picked != null && picked != _dateRange) {
      setState(() {
        _dateRange = picked;
      });
      await _fetchData(
        _dateRange.start.year.toString(),
        _dateRange.start.month.toString().padLeft(2, '0'),
        _dateRange.end.year.toString(),
        _dateRange.end.month.toString().padLeft(2, '0'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(1, 101, 65, 1),
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 80, // Increased height
        flexibleSpace: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/pattern.png'),
              fit: BoxFit.cover,
              opacity: 0.1,
            ),
          ),
        ),
        leading: IconButton(
          padding: EdgeInsets.only(left: 16),
          icon: Icon(
            Icons.chevron_left,
            color: Colors.white,
            size: 32,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Padding(
          padding: EdgeInsets.only(top: 8), // Add some top padding to the title
          child: Text(
            'Absence Management',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _selectDateRange(context),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 12),
                              Text(
                                '${DateFormat('dd MMM yyyy').format(_dateRange.start)} - ${DateFormat('dd MMM yyyy').format(_dateRange.end)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search here....',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      Container(
                        height: 24,
                        width: 1,
                        color: Colors.grey[300],
                        margin: EdgeInsets.symmetric(vertical: 8),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            // Handle filter action
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(
                              Icons.tune,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: _filters.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    final count = filter == 'All'
                        ? _getFilteredData().length.toString()
                        : _getFilteredData()
                            .where((item) {
                              final isOnTime = _isOnTime(item.id);
                              return filter == 'On Time' ? isOnTime : !isOnTime;
                            })
                            .length
                            .toString();

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isSelected
                                    ? Color.fromRGBO(1, 101, 65, 1)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                filter,
                                style: TextStyle(
                                  color: isSelected
                                      ? Color.fromRGBO(1, 101, 65, 1)
                                      : Colors.grey[600],
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              SizedBox(width: 4),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: filter == 'All'
                                      ? Color.fromRGBO(1, 101, 65, 1)
                                      : filter == 'On Time'
                                          ? Color.fromRGBO(1, 101, 65, 1)
                                          : Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  count,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 24), // Increased gap between tabs and cards
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 1, // Added top padding to ListView
                    bottom: 16,
                  ),
                  itemCount: _getFilteredData().length,
                  itemBuilder: (context, index) {
                    final item = _getFilteredData()[index];

                    return Container(
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            offset: Offset(0, 0),
                            blurRadius: 3,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isOnTime(item.id)
                                    ? Color.fromRGBO(1, 101, 65, 0.1)
                                    : Colors.red[50],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.fingerprint,
                                  size: 28,
                                  color: _isOnTime(item.id)
                                      ? Color.fromRGBO(1, 101, 65, 1)
                                      : Colors.red,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            // Name and Position
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.userId,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Hari Kerja',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        size: 14,
                                        color: _isOnTime(item.id)
                                            ? Colors.grey[600]
                                            : Colors.red[400],
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        item.id,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _isOnTime(item.id)
                                              ? Colors.grey[600]
                                              : Colors.red[400],
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Icon(
                                        Icons.schedule,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        item.title == '-' || item.title.isEmpty
                                            ? '--:--'
                                            : item.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Status
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _isOnTime(item.id)
                                    ? Color.fromRGBO(1, 101, 65, 0.1)
                                    : Colors.red[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isOnTime(item.id)
                                          ? Color.fromRGBO(1, 101, 65, 1)
                                          : Colors.red,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    _isOnTime(item.id) ? 'On Time' : 'Overdue',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _isOnTime(item.id)
                                          ? Color.fromRGBO(1, 101, 65, 1)
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (_isLoadingOverlay)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
