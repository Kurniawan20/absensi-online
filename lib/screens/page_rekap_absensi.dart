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
import '../utils/storage_config.dart';

class MonthYearPickerWidget extends StatefulWidget {
  final int initialYear;
  final int initialMonth;
  final Color primaryColor;
  final Function(int year, int month) onChanged;

  const MonthYearPickerWidget({
    Key? key,
    required this.initialYear,
    required this.initialMonth,
    required this.primaryColor,
    required this.onChanged,
  }) : super(key: key);

  @override
  _MonthYearPickerWidgetState createState() => _MonthYearPickerWidgetState();
}

class _MonthYearPickerWidgetState extends State<MonthYearPickerWidget> {
  late int selectedYear;
  late int selectedMonth;
  
  final List<String> months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
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
                icon: Icon(Icons.chevron_left, color: widget.primaryColor),
              ),
              Text(
                selectedYear.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: widget.primaryColor,
                ),
              ),
              IconButton(
                onPressed: selectedYear < DateTime.now().year ? () {
                  setState(() {
                    selectedYear++;
                    widget.onChanged(selectedYear, selectedMonth);
                  });
                } : null,
                icon: Icon(Icons.chevron_right, color: widget.primaryColor),
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
                        ? widget.primaryColor
                        : (isCurrentMonth ? widget.primaryColor.withOpacity(0.1) : Colors.transparent),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected 
                          ? widget.primaryColor
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
  final storage = StorageConfig.secureStorage;
  List<Data> data = [];
  List<Data> _paginatedData = [];
  bool _isLoadingOverlay = false;
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
    final now = DateTime.now();
    // Initialize with current month only
    _dateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month, 1),
    );
    print('RekapAbsensi: Initializing with month ${now.month}/${now.year}');
    _fetchData(
      now.year.toString(),
      now.month.toString().padLeft(2, '0'),
      now.year.toString(),
      now.month.toString().padLeft(2, '0'),
    );
  }

  void _updatePaginatedData() {
    // Show all data instead of paginating
    _paginatedData = data;
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

    print('RekapAbsensi: _fetchData called with startYear=$startYear, startMonth=$startMonth, endYear=$endYear, endMonth=$endMonth');

    setState(() {
      _isLoadingOverlay = true;
      data = [];
      _paginatedData = [];
    });

    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final url = Uri.parse('${ApiConstants.BASE_URL}/getabsen');
      final requestBody = {
        "npp": widget.id,
        "year": startYear,
        "month": startMonth,
        "timestamp": DateTime.now().millisecondsSinceEpoch.toString(),
      };
      
      print('RekapAbsensi: API Request URL: $url');
      print('RekapAbsensi: Request Body: $requestBody');
      
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
              'Cache-Control': 'no-cache, no-store, must-revalidate',
              'Pragma': 'no-cache',
              'Expires': '0',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      print('RekapAbsensi: Response Status: ${response.statusCode}');
      print('RekapAbsensi: Response Headers: ${response.headers}');
      print('RekapAbsensi: Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse == null) {
          throw Exception('Empty response from server');
        }
        
        print('RekapAbsensi: Parsed JSON Response Length: ${(jsonResponse as List).length}');
        if ((jsonResponse as List).isNotEmpty) {
          print('RekapAbsensi: First 3 records:');
          for (int i = 0; i < (jsonResponse as List).length && i < 3; i++) {
            final record = (jsonResponse as List)[i];
            print('  Record $i: ${record['tanggal']} - ${record['jam_masuk']} - ${record['jam_keluar']}');
          }
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
    // Initialize with current selected values
    DateTime? selectedDate = _dateRange.start;
    
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
            child: MonthYearPickerWidget(
              initialYear: _dateRange.start.year,
              initialMonth: _dateRange.start.month,
              primaryColor: _primaryColor,
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
                  final newYear = selectedDate!.year;
                  final newMonth = selectedDate!.month;
                  
                  // Only update and reload if the selection actually changed
                  if (newYear != _dateRange.start.year || newMonth != _dateRange.start.month) {
                    setState(() {
                      _dateRange = DateTimeRange(
                        start: selectedDate!,
                        end: selectedDate!,
                      );
                    });
                    print('Loading data for: Year=$newYear, Month=$newMonth');
                    _fetchData(
                      newYear.toString(),
                      newMonth.toString().padLeft(2, '0'),
                      newYear.toString(),
                      newMonth.toString().padLeft(2, '0'),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text('Pilih'),
            ),
          ],
        );
      },
    );
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromRGBO(1, 101, 65, 1),
                Color.fromRGBO(1, 101, 65, 0.8),
              ],
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Absence Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${DateFormat('MMMM yyyy').format(_dateRange.start)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
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
                    // Calculate count based on filter only (ignore current search)
                    final count = _paginatedData
                        .where((item) {
                          // Apply search filter if there's a search query
                          bool matchesSearch = true;
                          if (_searchQuery.isNotEmpty) {
                            matchesSearch = item.userId.toLowerCase().contains(_searchQuery.toLowerCase());
                          }
                          
                          // Apply tab filter
                          bool matchesFilter = true;
                          if (filter != 'All') {
                            final isOnTime = _isOnTime(item.id);
                            matchesFilter = filter == 'On Time' ? isOnTime : !isOnTime;
                          }
                          
                          return matchesSearch && matchesFilter;
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
