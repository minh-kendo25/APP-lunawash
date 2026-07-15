import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'main_layout.dart';
import '../services/api_service.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _currentStep = 1;
  final ScrollController _scrollController = ScrollController();

  int _selectedBranchIndex = 0;
  String _selectedMainServiceId = '';
  List<String> _selectedAddOnIds = [];

  int _selectedTimeSlotIndex = -1;
  DateTime _selectedDate = DateTime.now();
  int _selectedStationIndex = 0;
  int _selectedSavedVehicleIndex = 0;
  int _selectedVehicleIndex = 1;
  String _paymentMethod = 'vnpay';
  Map<String, dynamic>? _selectedVoucher;

  Set<int> _occupiedSlots = {};
  bool _isLoadingSlots = false;

  List<dynamic> _mainPackages = [];
  List<dynamic> _addOnServices = [];
  bool _isLoadingServices = true;
  bool _isFindingLocation = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadVehicles();
    _fetchOccupiedSlots();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      final data = await ApiService.fetchServices();
      if (mounted) {
        setState(() {
          _mainPackages = data
              .where(
                (s) => s['serviceType'] == 'Package' && s['isActive'] == true,
              )
              .toList();
          _addOnServices = data
              .where(
                (s) => s['serviceType'] == 'AddOn' && s['isActive'] == true,
              )
              .toList();
          if (_mainPackages.isNotEmpty) {
            _selectedMainServiceId = _mainPackages[0]['id'];
          }
          _isLoadingServices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingServices = false);
      }
    }
  }

  Future<void> _loadVehicles() async {
    final vehicles = await ApiService.getVehicles();
    if (mounted) {
      setState(() {
        _savedVehicles = vehicles;
        if (_savedVehicles.isNotEmpty) {
          _selectedSavedVehicleIndex = 0;
        }
      });
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double r = 6371; // Bán kính trái đất km
    final double dLat = (lat2 - lat1) * (math.pi / 180);
    final double dLon = (lon2 - lon1) * (math.pi / 180);
    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180)) *
            math.cos(lat2 * (math.pi / 180)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  Future<void> _handleFindNearestBranch() async {
    bool serviceEnabled;
    LocationPermission permission;

    setState(() {
      _isFindingLocation = true;
    });

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.',
        );
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double minDistance = double.infinity;
      int nearestIndex = 0;

      for (int i = 0; i < 5; i++) {
        double dist = _calculateDistance(
          position.latitude,
          position.longitude,
          _getBranchLat(i),
          _getBranchLng(i),
        );
        if (dist < minDistance) {
          minDistance = dist;
          nearestIndex = i;
        }
      }

      if (mounted) {
        setState(() {
          _selectedBranchIndex = nearestIndex;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã chọn chi nhánh gần nhất: ${_getBranchName(nearestIndex)} (${minDistance.toStringAsFixed(1)}km)',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không thể lấy vị trí. Vui lòng kiểm tra quyền truy cập.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFindingLocation = false;
        });
      }
    }
  }

  Future<void> _fetchOccupiedSlots() async {
    if (!mounted) return;
    setState(() => _isLoadingSlots = true);

    final branchIds = [
      'BRN-LD-01',
      'BRN-Q1-01',
      'BRN-Q7-01',
      'BRN-TB-01',
      'BRN-TTH-01',
    ];
    final branchId = branchIds[_selectedBranchIndex];
    final washSlotId = '$branchId-WS-0${_selectedStationIndex + 1}';
    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    final data = await ApiService.getOccupiedSlots(dateStr, washSlotId);

    if (!mounted) return;

    Set<int> blocked = {};

    for (var booking in data) {
      try {
        DateTime startD = DateTime.parse(booking['startTime']).toLocal();
        DateTime endD = DateTime.parse(booking['endTime']).toLocal();
        int startTotal = startD.hour * 60 + startD.minute;
        int endTotal = endD.hour * 60 + endD.minute;

        for (int i = 0; i < 20; i++) {
          int tm = 240 + (i * 45);
          if (tm >= startTotal && tm < endTotal) blocked.add(i);
        }
      } catch (e) {}
    }

    setState(() {
      _occupiedSlots = blocked;
      _isLoadingSlots = false;
      if (_occupiedSlots.contains(_selectedTimeSlotIndex)) {
        _selectedTimeSlotIndex = -1;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    double offset = _scrollController.offset;
    double maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    double progress = offset / maxScroll;

    int step = 1;
    if (progress > 0.8)
      step = 4;
    else if (progress > 0.5)
      step = 3;
    else if (progress > 0.2)
      step = 2;

    if (_currentStep != step) {
      setState(() {
        _currentStep = step;
      });
    }
  }

  List<dynamic> _savedVehicles = [];

  final List<Map<String, dynamic>> _vehicleTypes = [
    {
      'name': 'Ô tô 2 chỗ',
      'price': '500.000đ',
      'time': '120 phút',
      'slots': 3,
      'holdTime': '135 phút',
    },
    {
      'name': 'Ô tô 4 chỗ',
      'price': '700.000đ',
      'time': '150 phút',
      'slots': 4,
      'holdTime': '180 phút',
    },
    {
      'name': 'Ô tô 7 chỗ',
      'price': '1.000.000đ',
      'time': '210 phút',
      'slots': 5,
      'holdTime': '225 phút',
    },
    {
      'name': 'Xe bán tải',
      'price': '1.100.000đ',
      'time': '240 phút',
      'slots': 6,
      'holdTime': '270 phút',
    },
    {
      'name': 'SUV',
      'price': '1.100.000đ',
      'time': '240 phút',
      'slots': 6,
      'holdTime': '270 phút',
    },
  ];

  int _getStationCount(int branchIndex) {
    if (branchIndex == 0 || branchIndex == 1) return 3; // Linh Đông, Q1
    if (branchIndex == 2) return 2; // Q7
    return 1; // Tân Bình, Tân Thới Hiệp
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng đang được phát triển...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  String _formatDate(DateTime date) {
    String weekday = date.weekday == 7 ? 'CN' : 'Thứ ${date.weekday + 1}';
    return '$weekday, ${date.day} Thg ${date.month}';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeSlotIndex = -1;
      });
      _fetchOccupiedSlots();
    }
  }

  @override
  Widget build(BuildContext context) {
    String selectedVehicleTypeId = 'VT-OTO-4C';
    if (_savedVehicles.isNotEmpty) {
      selectedVehicleTypeId =
          _savedVehicles[_selectedSavedVehicleIndex]['vehicleTypeId']
              ?.toString() ??
          'VT-OTO-4C';
    }

    int totalPrice = 0;
    int requiredSlots = 0;

    if (_selectedMainServiceId.isNotEmpty) {
      try {
        var mainPkg = _mainPackages.firstWhere(
          (p) => p['id'] == _selectedMainServiceId,
        );
        if (mainPkg['prices'] != null) {
          var sp = (mainPkg['prices'] as List).firstWhere(
            (p) => p['vehicleTypeId'] == selectedVehicleTypeId,
          );
          totalPrice += (sp['price'] as num).toInt();
          requiredSlots += ((sp['durationMinutes'] as num).toInt() / 45).ceil();
        }
      } catch (e) {}
    }

    for (var addOnId in _selectedAddOnIds) {
      try {
        var addOn = _addOnServices.firstWhere((a) => a['id'] == addOnId);
        if (addOn['prices'] != null) {
          var sp = (addOn['prices'] as List).firstWhere(
            (p) => p['vehicleTypeId'] == selectedVehicleTypeId,
          );
          totalPrice += (sp['price'] as num).toInt();
          requiredSlots += ((sp['durationMinutes'] as num).toInt() / 45).ceil();
        }
      } catch (e) {}
    }

    if (requiredSlots == 0) requiredSlots = 1;

    String formatCurrency(int amount) {
      String s = amount.toString();
      String res = '';
      for (int i = 0; i < s.length; i++) {
        res += s[i];
        if ((s.length - i - 1) % 3 == 0 && i != s.length - 1) {
          res += '.';
        }
      }
      return res + 'đ';
    }

    String formattedTotal = formatCurrency(totalPrice);
    String formattedOldTotal = formatCurrency(
      totalPrice + 50000,
    ); // Dummy for UI

    String selectedTimeStr = 'Chọn giờ';
    if (_selectedTimeSlotIndex != -1) {
      int totalMins = 240 + (_selectedTimeSlotIndex * 45);
      int h = totalMins ~/ 60;
      int m = totalMins % 60;
      String time =
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
      String dayStr =
          (_selectedDate.year == DateTime.now().year &&
              _selectedDate.month == DateTime.now().month &&
              _selectedDate.day == DateTime.now().day)
          ? 'Hôm nay'
          : '${_selectedDate.day}/${_selectedDate.month}';
      selectedTimeStr = '$time - $dayStr';
    }

    int getSlotState(int idx) {
      int tm = 240 + (idx * 45);
      int hr = tm ~/ 60;
      int min = tm % 60;
      DateTime now = DateTime.now();
      if (_selectedDate.year == now.year &&
          _selectedDate.month == now.month &&
          _selectedDate.day == now.day) {
        if (hr < now.hour || (hr == now.hour && min <= now.minute)) {
          return 1; // Past
        }
      }
      if (_occupiedSlots.contains(idx)) return 2; // Booked
      return 0; // Available
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Horizontal Stepper Custom
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStepItem('1', 'Chi nhánh', _currentStep >= 1),
                _buildStepLine(_currentStep >= 2),
                _buildStepItem('2', 'Trạm', _currentStep >= 2),
                _buildStepLine(_currentStep >= 3),
                _buildStepItem('3', 'Dịch vụ', _currentStep >= 3),
                _buildStepLine(_currentStep >= 4),
                _buildStepItem('4', 'Thời gian', _currentStep >= 4),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Chọn chi nhánh',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: _isFindingLocation
                            ? null
                            : _handleFindNearestBranch,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4EE1F1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF4EE1F1).withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              _isFindingLocation
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF0F2050),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.my_location,
                                      size: 14,
                                      color: Color(0xFF0F2050),
                                    ),
                              const SizedBox(width: 4),
                              Text(
                                _isFindingLocation
                                    ? 'Đang tìm...'
                                    : 'Gợi ý trạm gần nhất',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F2050),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _showBranchPickerBottomSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getBranchName(_selectedBranchIndex),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getBranchAddress(_selectedBranchIndex),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            size: 24,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Thông tin chi nhánh (Box Image + Details)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.network(
                          _getBranchImage(_selectedBranchIndex),
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 140,
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getBranchName(_selectedBranchIndex),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F2050),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getBranchDescription(_selectedBranchIndex),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                              const Divider(height: 24),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Color(0xFF0F2050),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _getBranchAddress(_selectedBranchIndex),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone,
                                    size: 16,
                                    color: Color(0xFF0F172A),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Hotline: 0909 123 456',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.schedule,
                                    size: 16,
                                    color: Color(0xFF0F172A),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Giờ mở cửa: ${_getBranchHours(_selectedBranchIndex)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Gói dịch vụ chính
                  const Text(
                    'Gói dịch vụ chính',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingServices)
                    const Center(child: CircularProgressIndicator())
                  else if (_mainPackages.isEmpty)
                    const Text('Không có gói dịch vụ nào')
                  else
                    ..._mainPackages.map((pkg) {
                      String priceStr = 'N/A';
                      int pts = 0;
                      try {
                        var sp = (pkg['prices'] as List).firstWhere(
                          (p) => p['vehicleTypeId'] == selectedVehicleTypeId,
                        );
                        priceStr = formatCurrency(sp['price'].toInt());
                        pts = sp['pointsRewarded'] ?? 0;
                      } catch (e) {}
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildMainServiceCard(
                          pkg['serviceName'] ?? 'Dịch vụ',
                          pkg['description'] ?? '',
                          priceStr,
                          pts,
                          _selectedMainServiceId == pkg['id'],
                          () => setState(() {
                            _selectedMainServiceId =
                                pkg['id']?.toString() ?? '';
                            _selectedTimeSlotIndex = -1;
                          }),
                        ),
                      );
                    }).toList(),

                  const SizedBox(height: 24),

                  // Thông tin xe
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Thông tin xe',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.black87,
                        ),
                        onPressed: _showComingSoon,
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _showSavedVehiclePicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.directions_car,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _savedVehicles.isEmpty
                                        ? 'Chưa có xe'
                                        : (_savedVehicles[_selectedSavedVehicleIndex]['license']
                                                  ?.toString() ??
                                              'Biển số'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _savedVehicles.isEmpty
                                        ? 'Vui lòng thêm xe'
                                        : '${_savedVehicles[_selectedSavedVehicleIndex]['name'] ?? 'Xe chưa phân loại'}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Dịch vụ thêm
                  const Text(
                    'Dịch vụ thêm (Tùy chọn)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingServices)
                    const Center(child: CircularProgressIndicator())
                  else if (_addOnServices.isEmpty)
                    const Text('Không có dịch vụ thêm nào')
                  else
                    ..._addOnServices.map((addOn) {
                      String priceStr = 'N/A';
                      int pts = 0;
                      try {
                        var sp = (addOn['prices'] as List).firstWhere(
                          (p) => p['vehicleTypeId'] == selectedVehicleTypeId,
                        );
                        priceStr = formatCurrency(sp['price'].toInt());
                        pts = sp['pointsRewarded'] ?? 0;
                      } catch (e) {}
                      bool isSelected = _selectedAddOnIds.contains(addOn['id']);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildAddOnCard(
                          addOn['serviceName'] ?? 'Dịch vụ thêm',
                          priceStr,
                          pts,
                          isSelected,
                          () => setState(() {
                            if (isSelected)
                              _selectedAddOnIds.remove(
                                addOn['id']?.toString() ?? '',
                              );
                            else
                              _selectedAddOnIds.add(
                                addOn['id']?.toString() ?? '',
                              );
                            _selectedTimeSlotIndex = -1;
                          }),
                        ),
                      );
                    }).toList(),

                  const SizedBox(height: 24),

                  // Chọn khung giờ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: List.generate(
                            _getStationCount(_selectedBranchIndex),
                            (index) {
                              bool isSelected = _selectedStationIndex == index;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedStationIndex = index;
                                    _selectedTimeSlotIndex = -1;
                                  });
                                  _fetchOccupiedSlots();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.05,
                                              ),
                                              blurRadius: 4,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    'Trạm ${index + 1}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? Colors.blue.shade700
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _formatDate(_selectedDate),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.black87,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.6,
                        ),
                    itemCount: 27,
                    itemBuilder: (context, index) {
                      int totalMins = 240 + (index * 45);
                      int h = totalMins ~/ 60;
                      int m = totalMins % 60;
                      String time =
                          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

                      int state = getSlotState(index);
                      bool isPast = state == 1;
                      bool isBooked = state == 2;

                      bool isPrimary = index == _selectedTimeSlotIndex;
                      bool isHeld =
                          _selectedTimeSlotIndex != -1 &&
                          index > _selectedTimeSlotIndex &&
                          index < _selectedTimeSlotIndex + requiredSlots;

                      bool canBeClicked = true;
                      if (state != 0) {
                        canBeClicked = false;
                      } else if (index + requiredSlots > 27) {
                        canBeClicked = false;
                      } else {
                        for (int i = 0; i < requiredSlots; i++) {
                          if (getSlotState(index + i) != 0) {
                            canBeClicked = false;
                            break;
                          }
                        }
                      }

                      String statusText = '';
                      Color bgColor = Colors.white;
                      Color borderColor = Colors.grey.shade300;
                      Color slotTextColor = Colors.black54;
                      Color timeTextColor = Colors.black87;

                      if (isPast) {
                        statusText = 'Đã qua';
                        bgColor = Colors.grey.shade100;
                        borderColor = Colors.grey.shade200;
                        slotTextColor = Colors.grey.shade400;
                        timeTextColor = Colors.grey.shade400;
                      } else if (isBooked) {
                        statusText = 'Đã đặt';
                        bgColor = Colors.red.shade50;
                        borderColor = Colors.red.shade200;
                        slotTextColor = Colors.red.shade300;
                        timeTextColor = Colors.red.shade300;
                      } else if (isPrimary) {
                        statusText = 'Bắt đầu';
                        bgColor = const Color(0xFF0F2050);
                        borderColor = const Color(0xFF0F2050);
                        slotTextColor = Colors.white70;
                        timeTextColor = Colors.white;
                      } else if (isHeld) {
                        statusText = 'Đang giữ';
                        bgColor = const Color(0xFFE0FCFF);
                        borderColor = const Color(0xFF4EE1F1);
                        slotTextColor = Colors.black54;
                        timeTextColor = const Color(0xFF0F2050);
                      }

                      return GestureDetector(
                        onTap: () {
                          if (canBeClicked) {
                            setState(() => _selectedTimeSlotIndex = index);
                          }
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Slot ${index + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: slotTextColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                time,
                                style: TextStyle(
                                  color: timeTextColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  decoration: isPast
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                              if (statusText.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isPrimary
                                          ? Colors.white
                                          : (isBooked
                                                ? Colors.red.shade400
                                                : (isPast
                                                      ? Colors.grey.shade400
                                                      : const Color(
                                                          0xFF0F2050,
                                                        ))),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Tổng tiền & Thanh toán
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2050),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  color: Colors.white70,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  selectedTimeStr,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formattedTotal,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  formattedOldTotal,
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () => _showPaymentSummaryPopup(
                            requiredSlots,
                            totalPrice,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4EE1F1),
                            foregroundColor: const Color(0xFF0F2050),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Thanh toán',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String number, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0F2050) : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? const Color(0xFF0F2050) : Colors.black54,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine([bool isActive = false]) {
    return Container(
      width: 40,
      height: 1,
      color: isActive ? const Color(0xFF0F2050) : Colors.grey.shade300,
    );
  }

  void _showPaymentSummaryPopup(int requiredSlots, int originalTotalPrice) {
    if (_selectedTimeSlotIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn khung giờ trước khi thanh toán'),
        ),
      );
      return;
    }

    String formatCurrency(int amount) {
      String s = amount.toString();
      String res = '';
      for (int i = 0; i < s.length; i++) {
        res += s[i];
        if ((s.length - i - 1) % 3 == 0 && i != s.length - 1) {
          res += '.';
        }
      }
      return res + 'đ';
    }

    String branchName = _getBranchName(_selectedBranchIndex);
    String stationName = 'Trạm ${_selectedStationIndex + 1}';

    int totalMinsStart = 240 + (_selectedTimeSlotIndex * 45);
    int hStart = totalMinsStart ~/ 60;
    int mStart = totalMinsStart % 60;
    String startTimeStr =
        '${hStart.toString().padLeft(2, '0')}:${mStart.toString().padLeft(2, '0')}';

    int totalMinsEnd = totalMinsStart + (requiredSlots * 45);
    int hEnd = totalMinsEnd ~/ 60;
    int mEnd = totalMinsEnd % 60;
    String endTimeStr =
        '${hEnd.toString().padLeft(2, '0')}:${mEnd.toString().padLeft(2, '0')}';

    List<String> slotNames = [];
    for (int i = 0; i < requiredSlots; i++) {
      slotNames.add('${_selectedTimeSlotIndex + 1 + i}');
    }
    String slotIndicesStr =
        'Lượt ${slotNames.join(', ')} ($startTimeStr - $endTimeStr)';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xFF0F2050),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tóm tắt dịch vụ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Summary info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tổng thời gian',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          '${requiredSlots * 45} phút',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Số lượng slot đặt',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          '$requiredSlots slot',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 12),

                    const Divider(color: Colors.white24),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Địa điểm & Trạm',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                branchName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.right,
                              ),
                              Text(
                                stationName,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Số Slot',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Expanded(
                          child: Text(
                            slotIndicesStr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Thời gian dự kiến',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          '$startTimeStr - $endTimeStr',
                          style: const TextStyle(
                            color: Color(0xFF4EE1F1),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Mã giảm giá
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'MÃ GIẢM GIÁ',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final rawVouchers =
                                await ApiService.getMyVouchers();
                            final savedVouchers = rawVouchers.map((raw) {
                              final v = raw['voucher'] ?? {};
                              int val =
                                  (v['discountValue'] as num?)?.toInt() ?? 0;
                              return {
                                'code': v['id'] ?? raw['voucherId'] ?? '',
                                'title': v['voucherName'] ?? 'Mã giảm giá',
                                'subtitle': v['description'] ?? '',
                                'discount': val <= 100 ? val : null,
                                'discountAmount': val > 100 ? val : null,
                              };
                            }).toList();

                            if (!mounted) return;
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              builder: (ctx) {
                                return SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text(
                                          'Chọn mã giảm giá',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F2050),
                                          ),
                                        ),
                                      ),
                                      if (savedVouchers.isEmpty)
                                        const Padding(
                                          padding: EdgeInsets.all(32),
                                          child: Text(
                                            'Chưa có mã giảm giá nào được lưu.',
                                          ),
                                        )
                                      else
                                        Flexible(
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: savedVouchers.length,
                                            itemBuilder: (ctx, index) {
                                              final v = savedVouchers[index];
                                              return ListTile(
                                                leading: const Icon(
                                                  Icons.percent,
                                                  color: Color(0xFF4EE1F1),
                                                ),
                                                title: Text(v['title'] ?? ''),
                                                subtitle: Text(v['code'] ?? ''),
                                                onTap: () {
                                                  setModalState(() {
                                                    _selectedVoucher = v;
                                                  });
                                                  Navigator.pop(ctx);
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      if (_selectedVoucher != null)
                                        TextButton(
                                          onPressed: () {
                                            setModalState(() {
                                              _selectedVoucher = null;
                                            });
                                            Navigator.pop(ctx);
                                          },
                                          child: const Text(
                                            'Bỏ chọn mã giảm giá',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          child: const Row(
                            children: [
                              Icon(
                                Icons.local_activity,
                                color: Color(0xFF4EE1F1),
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Chọn mã giảm giá đã lưu',
                                style: TextStyle(
                                  color: Color(0xFF4EE1F1),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_selectedVoucher != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4EE1F1).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF4EE1F1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF4EE1F1),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedVoucher!['code'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _selectedVoucher!['title'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white54,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setModalState(() {
                                  _selectedVoucher = null;
                                });
                              },
                            ),
                          ],
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: const TextField(
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Nhập mã giảm giá...',
                                  hintStyle: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4EE1F1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ÁP MÃ',
                              style: TextStyle(
                                color: Color(0xFF0F2050),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 24),

                    // Payment method
                    const Text(
                      'PHƯƠNG THỨC THANH TOÁN',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setModalState(() => _paymentMethod = 'vnpay'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _paymentMethod == 'vnpay'
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _paymentMethod == 'vnpay'
                                      ? const Color(0xFF4EE1F1)
                                      : Colors.white24,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.qr_code,
                                    color: _paymentMethod == 'vnpay'
                                        ? const Color(0xFF4EE1F1)
                                        : Colors.white70,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'VNPAY',
                                    style: TextStyle(
                                      color: _paymentMethod == 'vnpay'
                                          ? Colors.white
                                          : Colors.white70,
                                      fontWeight: _paymentMethod == 'vnpay'
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setModalState(() => _paymentMethod = 'cash'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _paymentMethod == 'cash'
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _paymentMethod == 'cash'
                                      ? const Color(0xFF4EE1F1)
                                      : Colors.white24,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.money,
                                    color: _paymentMethod == 'cash'
                                        ? const Color(0xFF4EE1F1)
                                        : Colors.white70,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tiền mặt',
                                    style: TextStyle(
                                      color: _paymentMethod == 'cash'
                                          ? Colors.white
                                          : Colors.white70,
                                      fontWeight: _paymentMethod == 'cash'
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Total summary
                    Builder(
                      builder: (context) {
                        int finalPrice = originalTotalPrice;
                        int discountAmount = 0;

                        if (_selectedVoucher != null) {
                          if (_selectedVoucher!['discount'] != null) {
                            int pct = (_selectedVoucher!['discount'] as num)
                                .toInt();
                            discountAmount = (originalTotalPrice * pct / 100)
                                .round();
                          } else if (_selectedVoucher!['discountAmount'] !=
                              null) {
                            discountAmount =
                                (_selectedVoucher!['discountAmount'] as num)
                                    .toInt();
                          }
                          if (discountAmount > originalTotalPrice)
                            discountAmount = originalTotalPrice;
                          finalPrice = originalTotalPrice - discountAmount;
                        }

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Tạm tính',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  Text(
                                    formatCurrency(originalTotalPrice),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              if (discountAmount > 0) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Khuyến mãi',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    Text(
                                      '-${formatCurrency(discountAmount)}',
                                      style: const TextStyle(
                                        color: Color(0xFF4EE1F1),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 12),
                              const Divider(color: Colors.white24),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Tổng cộng',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    formatCurrency(finalPrice),
                                    style: const TextStyle(
                                      color: Color(0xFF4EE1F1),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_selectedTimeSlotIndex == -1) return;

                          // Prepare payload
                          final branchIds = [
                            'BRN-LD-01',
                            'BRN-Q1-01',
                            'BRN-Q7-01',
                            'BRN-TB-01',
                            'BRN-TTH-01',
                          ];
                          final branchId = branchIds[_selectedBranchIndex];
                          final washSlotId =
                              '$branchId-WS-0${_selectedStationIndex + 1}';

                          var activeVeh = _savedVehicles.isNotEmpty
                              ? _savedVehicles[_selectedSavedVehicleIndex]
                              : {};

                          List<String> serviceIds = [];

                          String selectedVehicleTypeId =
                              activeVeh['vehicleTypeId']?.toString() ??
                              'VT-OTO-4C';

                          if (_selectedMainServiceId.isNotEmpty) {
                            try {
                              var mainPkg = _mainPackages.firstWhere(
                                (p) => p['id'] == _selectedMainServiceId,
                              );
                              if (mainPkg['prices'] != null) {
                                var sp = (mainPkg['prices'] as List).firstWhere(
                                  (p) =>
                                      p['vehicleTypeId'] ==
                                      selectedVehicleTypeId,
                                );
                                serviceIds.add(sp['id']?.toString() ?? '');
                              }
                            } catch (e) {}
                          }

                          for (var addOnId in _selectedAddOnIds) {
                            try {
                              var addOn = _addOnServices.firstWhere(
                                (a) => a['id'] == addOnId,
                              );
                              if (addOn['prices'] != null) {
                                var sp = (addOn['prices'] as List).firstWhere(
                                  (p) =>
                                      p['vehicleTypeId'] ==
                                      selectedVehicleTypeId,
                                );
                                serviceIds.add(sp['id']?.toString() ?? '');
                              }
                            } catch (e) {}
                          }

                          int tm = 240 + (_selectedTimeSlotIndex * 45);
                          int hr = tm ~/ 60;
                          int min = tm % 60;
                          DateTime startTime = DateTime(
                            _selectedDate.year,
                            _selectedDate.month,
                            _selectedDate.day,
                            hr,
                            min,
                          );

                          int discountAmount = 0;
                          if (_selectedVoucher != null) {
                            if (_selectedVoucher!['discount'] != null) {
                              int pct = (_selectedVoucher!['discount'] as num)
                                  .toInt();
                              discountAmount = (originalTotalPrice * pct / 100)
                                  .round();
                            } else if (_selectedVoucher!['discountAmount'] !=
                                null) {
                              discountAmount =
                                  (_selectedVoucher!['discountAmount'] as num)
                                      .toInt();
                            }
                            if (discountAmount > originalTotalPrice)
                              discountAmount = originalTotalPrice;
                          }
                          int finalPrice = originalTotalPrice - discountAmount;

                          String mainPackageName = "Dịch vụ rửa xe";
                          if (_selectedMainServiceId.isNotEmpty) {
                            try {
                              mainPackageName =
                                  _mainPackages.firstWhere(
                                    (p) => p['id'] == _selectedMainServiceId,
                                  )['name'] ??
                                  mainPackageName;
                            } catch (e) {}
                          }

                          List<String> addOnNames = [];
                          for (var addOnId in _selectedAddOnIds) {
                            try {
                              var addOn = _addOnServices.firstWhere(
                                (a) => a['id'] == addOnId,
                              );
                              addOnNames.add(addOn['name']?.toString() ?? '');
                            } catch (e) {}
                          }

                          final notesJson = json.encode({
                            "packageName": mainPackageName,
                            "services": addOnNames.join(', '),
                            "totalPrice": finalPrice,
                            "paymentMethod": _paymentMethod,
                            "vehicleInfo":
                                "${activeVeh['name'] ?? ''} • ${activeVeh['license'] ?? ''}",
                            "message": "Đặt qua ứng dụng di động",
                          });

                          final payload = {
                            "BranchId": branchId,
                            "WashSlotId": washSlotId,
                            "VehicleTypeId":
                                activeVeh['vehicleTypeId']?.toString() ??
                                'VT-OTO-4C',
                            "LicensePlate": activeVeh['license'] ?? '',
                            "VehicleBrand": "",
                            "VehicleModel": activeVeh['name'] ?? '',
                            "ScheduledStartTime": startTime
                                .toLocal()
                                .toIso8601String(),
                            "Duration": requiredSlots * 45,
                            "Notes": notesJson,
                            "ServicePriceIds": serviceIds,
                          };

                          // Show loading indicator
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          final res = await ApiService.createBooking(payload);

                          Navigator.pop(context); // Close loading indicator
                          Navigator.pop(context); // Close summary popup

                          if (res['success'] == true) {
                            if (_paymentMethod == 'vnpay' &&
                                res['data'] != null &&
                                res['data']['id'] != null) {
                              String bookingId = res['data']['id'].toString();
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (c) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                              String? url = await ApiService.getVnPayUrl(
                                bookingId,
                              );
                              if (context.mounted) {
                                Navigator.pop(context); // Close loading
                              }

                              if (url != null) {
                                await launchUrl(
                                  Uri.parse(url),
                                  mode: LaunchMode.externalApplication,
                                );
                                if (context.mounted) {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext ctx) {
                                      return PopScope(
                                        canPop: false,
                                        child: _VnPayDialog(
                                          bookingId: bookingId,
                                        ),
                                      );
                                    },
                                  );
                                }
                              } else {
                                await ApiService.hardDeleteBooking(bookingId);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Lỗi tạo link thanh toán, vui lòng thử lại!',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            } else {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: const Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.teal,
                                          size: 28,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Thành công',
                                          style: TextStyle(
                                            color: Color(0xFF0F2050),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    content: const Text(
                                      'Bạn đã đặt lịch rửa xe thành công!',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const MainLayout(
                                                    initialIndex: 1,
                                                  ),
                                            ),
                                            (route) => false,
                                          );
                                        },
                                        child: const Text(
                                          'Xem lịch sử',
                                          style: TextStyle(
                                            color: Color(0xFF4EE1F1),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  res['error']?.toString() ??
                                      'Đã xảy ra lỗi khi đặt lịch',
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4EE1F1),
                          foregroundColor: const Color(0xFF0F2050),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Thanh toán',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBranchCard(String name, String address, bool isSelected) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF0F2050) : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 110,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1545199653-f7725da878bc?auto=format&fit=crop&q=80',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationCard(String title, String status, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF0F2050) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF0F2050) : Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.local_car_wash_outlined,
            color: isSelected ? Colors.white : Colors.black54,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            status,
            style: TextStyle(
              fontSize: 9,
              color: isSelected ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddOnCard(
    String title,
    String price,
    int pointsRewarded,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.add_circle,
                  color: isSelected ? Colors.blue : Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.blue.shade700
                            : Colors.black87,
                      ),
                    ),
                    if (pointsRewarded > 0) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.orange,
                              size: 10,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '+$pointsRewarded',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            Text(
              price,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.blue : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainServiceCard(
    String title,
    String desc,
    String price,
    int pointsRewarded,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F2050) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F2050) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                title == 'Cơ bản'
                    ? Icons.water_drop_outlined
                    : title == 'Nâng cao'
                    ? Icons.auto_fix_high
                    : Icons.diamond_outlined,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                      if (pointsRewarded > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.orange,
                                size: 10,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '+$pointsRewarded',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddonServiceCard(
    String title,
    String price,
    bool isChecked,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isChecked ? Colors.black87 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isChecked ? const Color(0xFF0F2050) : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: isChecked
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStationTab(String title, int index) {
    bool isSelected = _selectedStationIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStationIndex = index;
          _selectedTimeSlotIndex = -1; // Reset slot khi chuyển trạm
        });
        _fetchOccupiedSlots();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? const Color(0xFF0F172A) : Colors.black54,
          ),
        ),
      ),
    );
  }

  String _getBranchName(int index) {
    List<String> names = [
      'LunaWash Linh Đông',
      'LunaWash Quận 1',
      'LunaWash Quận 7',
      'LunaWash Tân Bình',
      'LunaWash Tân Thới Hiệp',
    ];
    return names[index];
  }

  String _getBranchAddress(int index) {
    List<String> addresses = [
      'Thủ Đức, HCM',
      '123 Lê Lợi, Bến Thành',
      '456 Nguyễn Văn Linh',
      '789 Cộng Hòa, Phường 13',
      'Quận 12, HCM',
    ];
    return addresses[index];
  }

  String _getBranchImage(int index) {
    List<String> images = [
      'https://images.unsplash.com/photo-1520340356584-f9917d1eea6f?auto=format&fit=crop&w=400&q=80', // Hình thay thế Linh Đông
      'https://images.unsplash.com/photo-1552930294-6b595f4c2974?auto=format&fit=crop&w=400&q=80', // Quận 1
      'https://images.unsplash.com/photo-1528190336454-13cd56b45b5a?auto=format&fit=crop&w=400&q=80', // Quận 7
      'https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?auto=format&fit=crop&w=400&q=80', // Tân Bình
      'https://images.unsplash.com/photo-1607860108855-64acf2078ed9?auto=format&fit=crop&w=400&q=80', // Tân Thới Hiệp
    ];
    return images[index];
  }

  String _getBranchDescription(int index) {
    List<String> descriptions = [
      'Chi nhánh Linh Đông sở hữu hệ thống rửa xe tự động vòi phun đa điểm hiện đại bậc nhất Thủ Đức, công suất lớn, phòng chờ lạnh và quầy café phục vụ khách.',
      'Vị trí đắc địa ngay trung tâm thành phố. Chi nhánh Quận 1 cung cấp dịch vụ rửa xe kết hợp đánh bóng nhanh và sáp phủ bóng Ceramic cao cấp.',
      'Trạm rửa siêu rộng rãi tại khu đô thị Phú Mỹ Hưng với 3 làn rửa chạy song song, rút ngắn tối đa thời gian chờ đợi của quý khách.',
      'Chi nhánh Cộng Hòa nổi bật với khu vực chăm sóc nội thất chuyên sâu và hệ thống lọc nước RO tiêu chuẩn, bảo vệ tối đa lớp sơn bóng của xe.',
      'Chi nhánh Quận 12 trang bị máy sấy phản lực gió siêu tốc và quy trình rửa gầm chuyên sâu, tối ưu cho dòng xe SUV và xe bán tải.',
    ];
    return descriptions[index];
  }

  double _getBranchLat(int index) {
    List<double> lats = [10.852445, 10.772564, 10.729351, 10.801648, 10.861789];
    return lats[index];
  }

  double _getBranchLng(int index) {
    List<double> lngs = [
      106.748364,
      106.698047,
      106.702983,
      106.640954,
      106.657512,
    ];
    return lngs[index];
  }

  String _getBranchHours(int index) {
    List<String> hours = [
      '06:00 - 22:00',
      '07:00 - 23:00',
      '06:00 - 22:00',
      '06:00 - 22:30',
      '06:00 - 22:00',
    ];
    return hours[index];
  }

  void _showBranchPickerBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chọn chi nhánh',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                itemBuilder: (context, index) {
                  bool isSelected = _selectedBranchIndex == index;
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(_getBranchImage(index)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    title: Text(
                      _getBranchName(index),
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      _getBranchAddress(index),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.black)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedBranchIndex = index;
                        _selectedStationIndex = 0;
                        _selectedTimeSlotIndex = -1;
                      });
                      _fetchOccupiedSlots();
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSavedVehiclePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chọn xe của bạn',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _savedVehicles.length,
                itemBuilder: (context, index) {
                  bool isSelected = _selectedSavedVehicleIndex == index;
                  var vehicle = _savedVehicles[index];
                  var type = vehicle['name'] ?? '';
                  if (type.isEmpty) type = 'Xe chưa phân loại';
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.directions_car,
                        color: isSelected ? Colors.blue : Colors.black54,
                      ),
                    ),
                    title: Text(
                      vehicle['license']?.toString() ??
                          vehicle['plate']?.toString() ??
                          'Biển số',
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      type.toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.blue)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedSavedVehicleIndex = index;
                        _selectedTimeSlotIndex = -1;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.blue,
                ),
                title: const Text(
                  'Thêm xe mới',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoon();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VnPayDialog extends StatefulWidget {
  final String bookingId;
  const _VnPayDialog({required this.bookingId});

  @override
  State<_VnPayDialog> createState() => _VnPayDialogState();
}

class _VnPayDialogState extends State<_VnPayDialog> {
  Timer? _timer;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isChecking) return;
      _isChecking = true;
      try {
        final history = await ApiService.getBookingHistory();
        final booking = history.firstWhere(
          (b) => b['id'] == widget.bookingId,
          orElse: () => null,
        );
        if (booking != null) {
          final status = booking['status'];
          if (status == 'Confirmed' || status == 'Paid') {
            timer.cancel();
            if (mounted) {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainLayout(initialIndex: 1),
                ),
                (route) => false,
              );
            }
          }
        }
      } catch (e) {
        // ignore
      } finally {
        _isChecking = false;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Đang chờ thanh toán',
        style: TextStyle(color: Color(0xFF0F2050)),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            'Vui lòng hoàn tất thanh toán trên cổng VNPAY. Hệ thống sẽ tự động chuyển trang khi thanh toán thành công.',
          ),
          SizedBox(height: 16),
          CircularProgressIndicator(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            _timer?.cancel();
            Navigator.pop(context);
            await ApiService.hardDeleteBooking(widget.bookingId);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Đã hủy giao dịch VNPAY',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text(
            'Hủy thanh toán',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}
