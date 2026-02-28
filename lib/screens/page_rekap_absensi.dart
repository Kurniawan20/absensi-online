import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../utils/storage_config.dart';

class MonthYearPickerWidget extends StatefulWidget {
  final int initialYear;
  final int initialMonth;
  final Color primaryColor;
  final Function(int year, int month) onChanged;

  const MonthYearPickerWidget({
    super.key,
    required this.initialYear,
    required this.initialMonth,
    required this.primaryColor,
    required this.onChanged,
  });

  @override
  State<MonthYearPickerWidget> createState() => _MonthYearPickerWidgetState();
}

class _MonthYearPickerWidgetState extends State<MonthYearPickerWidget> {
  late int selectedYear;
  late int selectedMonth;

  final List<String> months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
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
                onPressed: selectedYear > 2020
                    ? () {
                        setState(() {
                          selectedYear--;
                          widget.onChanged(selectedYear, selectedMonth);
                        });
                      }
                    : null,
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
                onPressed: selectedYear < DateTime.now().year
                    ? () {
                        setState(() {
                          selectedYear++;
                          widget.onChanged(selectedYear, selectedMonth);
                        });
                      }
                    : null,
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
                onTap: isFutureMonth
                    ? null
                    : () {
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
                        : (isCurrentMonth
                            ? widget.primaryColor.withValues(alpha: 0.1)
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? widget.primaryColor
                          : Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      months[index],
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isFutureMonth
                                ? Colors.grey[400]
                                : Colors.black87),
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
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
  const RekapAbsensi({super.key, required this.id});

  @override
  State<RekapAbsensi> createState() => _RekapAbsensiState();
}

class Data {
  final String userId; // tanggal
  final String id; // jam_masuk
  final String title; // jam_keluar
  final bool isLate; // is_late from API
  final String? batasJamMasuk; // batas_jam_masuk from API
  final String ketAbsensi; // ket_absensi from API
  final String source; // sumber absensi: 'mobile' atau 'fingerprint'

  Data({
    required this.userId,
    required this.id,
    required this.title,
    required this.isLate,
    this.batasJamMasuk,
    this.ketAbsensi = '-',
    this.source = 'mobile',
  });

  /// Cek apakah absensi dari mesin fingerprint
  bool get isFingerprint => source.toLowerCase() == 'fingerprint';

  /// Status bisa ditentukan jika bukan fingerprint, batasJamMasuk ada, dan ketAbsensi bukan '-'
  bool get isStatusKnown =>
      !isFingerprint &&
      batasJamMasuk != null &&
      batasJamMasuk!.isNotEmpty &&
      batasJamMasuk != 'null' &&
      ketAbsensi != '-';

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      userId: json['tanggal']?.toString() ?? '',
      id: json['jam_masuk']?.toString() ?? '--:--',
      title: json['jam_keluar']?.toString() ?? '--:--',
      isLate: json['is_late'] == true || json['is_late'] == 1,
      batasJamMasuk: json['batas_jam_masuk']?.toString(),
      ketAbsensi: json['ket_absensi']?.toString() ?? '-',
      source: json['source']?.toString() ?? 'mobile',
    );
  }
}

class _RekapAbsensiState extends State<RekapAbsensi> {
  final storage = StorageConfig.secureStorage;
  List<Data> data = [];
  List<Data> _paginatedData = [];
  bool _isLoadingOverlay = false;
  late DateTimeRange _dateRange;
  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Tepat Waktu', 'Terlambat'];
  // Extended filter options for the filter modal
  String _statusFilter =
      'All'; // All, On Time, Overdue, No Check-in, No Check-out
  bool _showWeekendOnly = false;
  bool _showWeekdayOnly = false;

  final Color _primaryColor = Color.fromRGBO(1, 101, 65, 1);
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isWeekend(String dateStr) {
    try {
      // Parse date string (format: YYYY-MM-DD)
      final parts = dateStr.split('-');
      if (parts.length != 3) return false;

      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      final date = DateTime(year, month, day);
      final weekday = date.weekday;

      return weekday == DateTime.saturday || weekday == DateTime.sunday;
    } catch (e) {
      return false; // If parsing fails, assume it's not weekend
    }
  }

  // Check if attendance is on time using isLate field from API
  // Keep method for backward compatibility but now uses Data.isLate
  bool _isOnTimeFromData(Data item) {
    // If no check-in time, consider it not on time
    if (item.id == '--:--' || item.id.isEmpty) {
      return false;
    }
    // Use is_late from API (inverted: isLate = false means on time)
    return !item.isLate;
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
    if (_selectedFilter == 'Semua' &&
        _searchQuery.isEmpty &&
        _statusFilter == 'All' &&
        !_showWeekendOnly &&
        !_showWeekdayOnly) {
      return _paginatedData;
    }

    return _paginatedData.where((item) {
      // Day type filter
      final isWeekendDay = _isWeekend(item.userId);
      if (_showWeekendOnly && !isWeekendDay) return false;
      if (_showWeekdayOnly && isWeekendDay) return false;

      // Status filter (use extended _statusFilter)
      bool matchesFilter = true;
      if (_statusFilter != 'All') {
        if (_statusFilter == 'On Time') {
          // Status harus diketahui, dan weekend atau tepat waktu
          matchesFilter =
              item.isStatusKnown && (isWeekendDay || _isOnTimeFromData(item));
        } else if (_statusFilter == 'Overdue') {
          // Status harus diketahui, bukan weekend, dan terlambat
          matchesFilter =
              item.isStatusKnown && !isWeekendDay && !_isOnTimeFromData(item);
        } else if (_statusFilter == 'No Check-in') {
          // No check-in: jam_masuk is empty or --:--
          matchesFilter = item.id == '--:--' || item.id.isEmpty;
        } else if (_statusFilter == 'No Check-out') {
          // No check-out: jam_keluar is empty or --:--
          matchesFilter = item.title == '--:--' || item.title.isEmpty;
        }
      } else if (_selectedFilter != 'Semua') {
        // Fallback to tab filter if no extended filter
        if (_selectedFilter == 'Tepat Waktu') {
          // Status harus diketahui, dan weekend atau tepat waktu
          matchesFilter =
              item.isStatusKnown && (isWeekendDay || _isOnTimeFromData(item));
        } else if (_selectedFilter == 'Terlambat') {
          // Status harus diketahui, bukan weekend, dan terlambat
          matchesFilter =
              item.isStatusKnown && !isWeekendDay && !_isOnTimeFromData(item);
        }
      }

      // Search filter
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        matchesSearch = item.userId.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
      }

      return matchesFilter && matchesSearch;
    }).toList();
  }

  Future<void> _fetchData(
    String startYear,
    String startMonth,
    String endYear,
    String endMonth,
  ) async {
    if (!mounted) return;

    print(
      'RekapAbsensi: _fetchData called with startYear=$startYear, startMonth=$startMonth, endYear=$endYear, endMonth=$endMonth',
    );

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

      final url = Uri.parse(ApiConstants.attendanceHistory);
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

        // Handle API response format: { rcode, message, data }
        List<dynamic> records;
        if (jsonResponse is Map<String, dynamic>) {
          if (jsonResponse['rcode'] == '00') {
            final responseData = jsonResponse['data'];
            // Handle new format: { data: { attendance: [...], statistics: {...} } }
            if (responseData is Map<String, dynamic> &&
                responseData.containsKey('attendance')) {
              records = responseData['attendance'] ?? [];
              // Statistics is available at responseData['statistics'] if needed
            }
            // Handle legacy format: { data: [...] }
            else if (responseData is List) {
              records = responseData;
            } else {
              records = [];
            }
          } else {
            throw Exception(
                jsonResponse['message'] ?? 'Failed to load attendance data');
          }
        } else if (jsonResponse is List) {
          // Fallback for legacy format (direct array)
          records = jsonResponse;
        } else {
          throw Exception('Unexpected response format');
        }

        print('RekapAbsensi: Parsed JSON Response Length: ${records.length}');
        if (records.isNotEmpty) {
          print('RekapAbsensi: First 3 records:');
          for (int i = 0; i < records.length && i < 3; i++) {
            final record = records[i];
            print(
              '  Record $i: ${record['tanggal']} - ${record['jam_masuk']} - ${record['jam_keluar']}',
            );
          }
        }

        setState(() {
          try {
            data = records.map<Data>((item) => Data.fromJson(item)).toList();
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load data: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    // Initialize with current selected values
    DateTime? selectedDate = _dateRange.start;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                'Pilih Bulan dan Tahun',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pilih periode untuk melihat rekap absensi',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 24),
              // Month Year Picker
              Container(
                height: 300,
                child: MonthYearPickerWidget(
                  initialYear: _dateRange.start.year,
                  initialMonth: _dateRange.start.month,
                  primaryColor: _primaryColor,
                  onChanged: (year, month) {
                    selectedDate = DateTime(year, month);
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (selectedDate != null) {
                          final newYear = selectedDate!.year;
                          final newMonth = selectedDate!.month;

                          // Only update and reload if the selection actually changed
                          if (newYear != _dateRange.start.year ||
                              newMonth != _dateRange.start.month) {
                            setState(() {
                              _dateRange = DateTimeRange(
                                start: selectedDate!,
                                end: selectedDate!,
                              );
                            });
                            print(
                              'Loading data for: Year=$newYear, Month=$newMonth',
                            );
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Pilih',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showFilterModal(BuildContext context) {
    // Temporary variables to hold the filter state
    String tempStatusFilter = _statusFilter;
    bool tempShowWeekendOnly = _showWeekendOnly;
    bool tempShowWeekdayOnly = _showWeekdayOnly;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Kehadiran',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Status Filter Section
                  Text(
                    'Status Kehadiran',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip(
                        label: 'Semua',
                        isSelected: tempStatusFilter == 'All',
                        onTap: () =>
                            setModalState(() => tempStatusFilter = 'All'),
                      ),
                      _buildFilterChip(
                        label: 'Tepat Waktu',
                        isSelected: tempStatusFilter == 'On Time',
                        onTap: () =>
                            setModalState(() => tempStatusFilter = 'On Time'),
                        color: _primaryColor,
                      ),
                      _buildFilterChip(
                        label: 'Terlambat',
                        isSelected: tempStatusFilter == 'Overdue',
                        onTap: () =>
                            setModalState(() => tempStatusFilter = 'Overdue'),
                        color: Colors.red,
                      ),
                      _buildFilterChip(
                        label: 'Tidak Masuk',
                        isSelected: tempStatusFilter == 'No Check-in',
                        onTap: () => setModalState(
                          () => tempStatusFilter = 'No Check-in',
                        ),
                        color: Colors.orange,
                      ),
                      _buildFilterChip(
                        label: 'Tidak Pulang',
                        isSelected: tempStatusFilter == 'No Check-out',
                        onTap: () => setModalState(
                          () => tempStatusFilter = 'No Check-out',
                        ),
                        color: Colors.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Day Type Filter Section
                  Text(
                    'Jenis Hari',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip(
                        label: 'Semua Hari',
                        isSelected:
                            !tempShowWeekendOnly && !tempShowWeekdayOnly,
                        onTap: () => setModalState(() {
                          tempShowWeekendOnly = false;
                          tempShowWeekdayOnly = false;
                        }),
                      ),
                      _buildFilterChip(
                        label: 'Hari Kerja',
                        isSelected: tempShowWeekdayOnly,
                        onTap: () => setModalState(() {
                          tempShowWeekdayOnly = true;
                          tempShowWeekendOnly = false;
                        }),
                        color: Colors.blue,
                      ),
                      _buildFilterChip(
                        label: 'Weekend',
                        isSelected: tempShowWeekendOnly,
                        onTap: () => setModalState(() {
                          tempShowWeekendOnly = true;
                          tempShowWeekdayOnly = false;
                        }),
                        color: Colors.teal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              tempStatusFilter = 'All';
                              tempShowWeekendOnly = false;
                              tempShowWeekdayOnly = false;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[600],
                            side: BorderSide(color: Colors.grey[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _statusFilter = tempStatusFilter;
                              _showWeekendOnly = tempShowWeekendOnly;
                              _showWeekdayOnly = tempShowWeekdayOnly;
                              // Sync with the tab filter
                              if (tempStatusFilter == 'All' ||
                                  tempStatusFilter == 'On Time' ||
                                  tempStatusFilter == 'Overdue') {
                                _selectedFilter = tempStatusFilter;
                              } else {
                                _selectedFilter = 'All';
                              }
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('Terapkan Filter'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final effectiveColor = color ?? _primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? effectiveColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? effectiveColor : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
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
          icon: Icon(Icons.chevron_left, color: Colors.white, size: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Rekap Kehadiran',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
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
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
                                DateFormat(
                                  'MMMM yyyy',
                                  'id',
                                ).format(_dateRange.start),
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
                            hintText: 'Cari tanggal....',
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
                              horizontal: 16,
                              vertical: 12,
                            ),
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
                            _showFilterModal(context);
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Stack(
                              children: [
                                Icon(
                                  Icons.tune,
                                  color: (_statusFilter != 'All' ||
                                          _showWeekendOnly ||
                                          _showWeekdayOnly)
                                      ? _primaryColor
                                      : Colors.grey[600],
                                  size: 20,
                                ),
                                // Active filter indicator
                                if (_statusFilter != 'All' ||
                                    _showWeekendOnly ||
                                    _showWeekdayOnly)
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _primaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
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
                            matchesSearch = item.userId.toLowerCase().contains(
                                  _searchQuery.toLowerCase(),
                                );
                          }

                          // Apply tab filter
                          bool matchesFilter = true;
                          if (filter != 'Semua') {
                            final isWeekendDay = _isWeekend(item.userId);
                            if (filter == 'Tepat Waktu') {
                              // Status harus diketahui, dan weekend atau tepat waktu
                              matchesFilter = item.isStatusKnown &&
                                  (isWeekendDay || _isOnTimeFromData(item));
                            } else if (filter == 'Terlambat') {
                              // Status harus diketahui, bukan weekend, dan terlambat
                              matchesFilter = item.isStatusKnown &&
                                  !isWeekendDay &&
                                  !_isOnTimeFromData(item);
                            }
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  filter,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected
                                        ? Color.fromRGBO(1, 101, 65, 1)
                                        : Colors.grey[600],
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              SizedBox(width: 4),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: filter == 'Semua'
                                      ? Color.fromRGBO(1, 101, 65, 1)
                                      : filter == 'Tepat Waktu'
                                          ? Color.fromRGBO(1, 101, 65, 1)
                                          : Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  count,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
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

                    final isWeekendDay = _isWeekend(item.userId);
                    // Cek apakah status bisa ditentukan
                    final isStatusKnown = item.isStatusKnown;
                    // Use is_late from API (weekend always "on time")
                    final isOnTimeStatus =
                        isWeekendDay ? true : _isOnTimeFromData(item);

                    return Container(
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
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
                                color: isWeekendDay
                                    ? Colors.blue[100]
                                    : !isStatusKnown
                                        ? Colors.grey[200]
                                        : isOnTimeStatus
                                            ? Color.fromRGBO(1, 101, 65, 0.1)
                                            : Colors.red[50],
                              ),
                              child: Center(
                                child: Icon(
                                  isWeekendDay
                                      ? Icons.weekend
                                      : Icons.fingerprint,
                                  size: 28,
                                  color: isWeekendDay
                                      ? Colors.blue[800]
                                      : !isStatusKnown
                                          ? Colors.grey[600]
                                          : isOnTimeStatus
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
                                  Row(
                                    children: [
                                      Text(
                                        item.userId,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      if (isWeekendDay) ...[
                                        SizedBox(width: 8),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[100],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            'Weekend',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.blue[800],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    isWeekendDay ? 'Hari Libur' : 'Hari Kerja',
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
                                        color: isWeekendDay
                                            ? Colors.blue[600]
                                            : isOnTimeStatus
                                                ? Colors.grey[600]
                                                : Colors.red[400],
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        item.id,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isWeekendDay
                                              ? Colors.blue[600]
                                              : isOnTimeStatus
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
                            // Status - hanya tampil jika weekend atau status diketahui
                            if (isWeekendDay || isStatusKnown)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isWeekendDay
                                      ? Colors.blue[100]
                                      : isOnTimeStatus
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
                                        color: isWeekendDay
                                            ? Colors.blue[800]
                                            : isOnTimeStatus
                                                ? Color.fromRGBO(1, 101, 65, 1)
                                                : Colors.red,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      isWeekendDay
                                          ? 'Weekend'
                                          : (isOnTimeStatus
                                              ? 'Tepat Waktu'
                                              : 'Terlambat'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isWeekendDay
                                            ? Colors.blue[800]
                                            : isOnTimeStatus
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
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(child: CircularProgressIndicator()),
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
