import 'package:flutter/material.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _currentStep = 1;
  final ScrollController _scrollController = ScrollController();
  
  int _selectedBranchIndex = 0;
  int _selectedPackageIndex = 1;
  bool _isInteriorCleanSelected = false;
  int _selectedTimeSlotIndex = -1;
  DateTime _selectedDate = DateTime.now();
  int _selectedStationIndex = 0;
  int _selectedSavedVehicleIndex = 0;
  int _selectedVehicleIndex = 1;
  String _paymentMethod = 'vnpay';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
    if (progress > 0.8) step = 4;
    else if (progress > 0.5) step = 3;
    else if (progress > 0.2) step = 2;

    if (_currentStep != step) {
      setState(() {
        _currentStep = step;
      });
    }
  }

  final List<Map<String, dynamic>> _savedVehicles = [
    {'plate': '51A-123.45', 'typeIndex': 1}, // Ô tô 4 chỗ
    {'plate': '60B-987.65', 'typeIndex': 3}, // Xe bán tải
  ];

  final List<Map<String, dynamic>> _vehicleTypes = [
    {'name': 'Ô tô 2 chỗ', 'price': '500.000đ', 'time': '120 phút', 'slots': 3, 'holdTime': '135 phút'},
    {'name': 'Ô tô 4 chỗ', 'price': '700.000đ', 'time': '150 phút', 'slots': 4, 'holdTime': '180 phút'},
    {'name': 'Ô tô 7 chỗ', 'price': '1.000.000đ', 'time': '210 phút', 'slots': 5, 'holdTime': '225 phút'},
    {'name': 'Xe bán tải', 'price': '1.100.000đ', 'time': '240 phút', 'slots': 6, 'holdTime': '270 phút'},
    {'name': 'SUV', 'price': '1.100.000đ', 'time': '240 phút', 'slots': 6, 'holdTime': '270 phút'},
  ];

  int _getStationCount(int branchIndex) {
    if (branchIndex == 0 || branchIndex == 1) return 3; // Linh Đông, Q1
    if (branchIndex == 2) return 2; // Q7
    return 1; // Tân Bình, Tân Thới Hiệp
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng đang được phát triển...'), duration: Duration(seconds: 1)),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalPrice = 0;
    if (_selectedPackageIndex == 0) totalPrice += 150000;
    if (_selectedPackageIndex == 1) totalPrice += 250000;
    if (_selectedPackageIndex == 2) totalPrice += 500000;
    
    if (_isInteriorCleanSelected) {
      String priceStr = _vehicleTypes[_selectedVehicleIndex]['price'].replaceAll('.', '').replaceAll('đ', '');
      totalPrice += int.tryParse(priceStr) ?? 0;
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
    
    String formattedTotal = formatCurrency(totalPrice);
    String formattedOldTotal = formatCurrency(totalPrice + 50000);
    
    String selectedTimeStr = 'Chọn giờ';
    if (_selectedTimeSlotIndex != -1) {
      int totalMins = 240 + (_selectedTimeSlotIndex * 45);
      int h = totalMins ~/ 60;
      int m = totalMins % 60;
      String time = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
      String dayStr = (_selectedDate.year == DateTime.now().year && _selectedDate.month == DateTime.now().month && _selectedDate.day == DateTime.now().day) ? 'Hôm nay' : '${_selectedDate.day}/${_selectedDate.month}';
      selectedTimeStr = '$time - $dayStr';
    }

    int requiredSlots = 1;
    if (_isInteriorCleanSelected) {
      requiredSlots = _vehicleTypes[_selectedVehicleIndex]['slots'];
    }

    int getSlotState(int idx) {
      int tm = 240 + (idx * 45);
      int hr = tm ~/ 60;
      int min = tm % 60;
      DateTime now = DateTime.now();
      if (_selectedDate.year == now.year && _selectedDate.month == now.month && _selectedDate.day == now.day) {
        if (hr < now.hour || (hr == now.hour && min <= now.minute)) {
          return 1; // Past
        }
      }
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
                  // Chọn chi nhánh
                  const Text('Chọn chi nhánh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _showBranchPickerBottomSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                              Text(_getBranchName(_selectedBranchIndex), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(_getBranchAddress(_selectedBranchIndex), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            ],
                          ),
                          const Icon(Icons.keyboard_arrow_down, size: 24, color: Colors.black45),
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
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
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
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 140,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_getBranchName(_selectedBranchIndex), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F2050))),
                              const SizedBox(height: 8),
                              Text(_getBranchDescription(_selectedBranchIndex), style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4)),
                              const Divider(height: 24),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 16, color: Color(0xFF0F2050)),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(_getBranchAddress(_selectedBranchIndex), style: const TextStyle(fontSize: 12))),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.phone, size: 16, color: Color(0xFF0F172A)),
                                  const SizedBox(width: 8),
                                  const Text('Hotline: 0909 123 456', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.schedule, size: 16, color: Color(0xFF0F172A)),
                                  const SizedBox(width: 8),
                                  Text('Giờ mở cửa: ${_getBranchHours(_selectedBranchIndex)}', style: const TextStyle(fontSize: 12)),
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
                  const Text('Gói dịch vụ chính', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildMainServiceCard('Cơ bản', 'Rửa sạch ngoại thất, làm khô tự động và xịt bóng lốp.', '150k', _selectedPackageIndex == 0, () => setState(() => _selectedPackageIndex = 0)),
                  const SizedBox(height: 12),
                  _buildMainServiceCard('Nâng cao', 'Dịch vụ cơ bản kết hợp vệ sinh gầm và tẩy ố lazang.', '250k', _selectedPackageIndex == 1, () => setState(() => _selectedPackageIndex = 1)),
                  const SizedBox(height: 12),
                  _buildMainServiceCard('Cao cấp', 'Chăm sóc toàn diện với phủ Nano Ceramic bảo vệ sơn xe.', '500k', _selectedPackageIndex == 2, () => setState(() => _selectedPackageIndex = 2)),
                  
                  const SizedBox(height: 24),
                  
                  // Thông tin xe
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Thông tin xe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.black87),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                                child: const Icon(Icons.directions_car, color: Colors.blue),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_savedVehicles[_selectedSavedVehicleIndex]['plate'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(_vehicleTypes[_savedVehicles[_selectedSavedVehicleIndex]['typeIndex']]['name'], style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                ],
                              ),
                            ],
                          ),
                          const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Dịch vụ thêm
                  const Text('Dịch vụ thêm (Tùy chọn)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildInteriorCleaningDetailedOption(),
                  
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
                                onTap: () => setState(() {
                                  _selectedStationIndex = index;
                                  _selectedTimeSlotIndex = -1;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
                                  ),
                                  child: Text('Trạm ${index + 1}', style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.blue.shade700 : Colors.black87)),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Text(_formatDate(_selectedDate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              const SizedBox(width: 6),
                              const Icon(Icons.calendar_today, size: 14, color: Colors.black87),
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
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                      String time = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
                      
                      int state = getSlotState(index);
                      bool isPast = state == 1;
                      bool isBooked = state == 2;
                      
                      bool isPrimary = index == _selectedTimeSlotIndex;
                      bool isHeld = _selectedTimeSlotIndex != -1 && index > _selectedTimeSlotIndex && index < _selectedTimeSlotIndex + requiredSlots;
                      
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
                              Text('Slot ${index + 1}', style: TextStyle(fontSize: 10, color: slotTextColor)),
                              const SizedBox(height: 2),
                              Text(
                                time,
                                style: TextStyle(
                                  color: timeTextColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  decoration: isPast ? TextDecoration.lineThrough : TextDecoration.none,
                                ),
                              ),
                              if (statusText.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(statusText, style: TextStyle(fontSize: 10, color: isPrimary ? Colors.white : (isBooked ? Colors.red.shade400 : (isPast ? Colors.grey.shade400 : const Color(0xFF0F2050))), fontWeight: FontWeight.bold)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                                const Icon(Icons.access_time, color: Colors.white70, size: 14),
                                const SizedBox(width: 4),
                                Text(selectedTimeStr, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(formattedTotal, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Text(formattedOldTotal, style: const TextStyle(color: Colors.white38, fontSize: 10, decoration: TextDecoration.lineThrough)),
                              ],
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () => _showPaymentSummaryPopup(requiredSlots, totalPrice),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4EE1F1),
                            foregroundColor: const Color(0xFF0F2050),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Thanh toán', style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _showPaymentSummaryPopup(int requiredSlots, int totalPrice) {
    if (_selectedTimeSlotIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn khung giờ trước khi thanh toán')),
      );
      return;
    }

    String formattedTotal = '${totalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ';
    
    String branchName = _getBranchName(_selectedBranchIndex);
    String stationName = 'Trạm ${_selectedStationIndex + 1}';
    
    int totalMinsStart = 240 + (_selectedTimeSlotIndex * 45);
    int hStart = totalMinsStart ~/ 60;
    int mStart = totalMinsStart % 60;
    String startTimeStr = '${hStart.toString().padLeft(2, '0')}:${mStart.toString().padLeft(2, '0')}';
    
    int totalMinsEnd = totalMinsStart + (requiredSlots * 45);
    int hEnd = totalMinsEnd ~/ 60;
    int mEnd = totalMinsEnd % 60;
    String endTimeStr = '${hEnd.toString().padLeft(2, '0')}:${mEnd.toString().padLeft(2, '0')}';
    
    List<String> slotNames = [];
    for (int i = 0; i < requiredSlots; i++) {
      slotNames.add('${_selectedTimeSlotIndex + 1 + i}');
    }
    String slotIndicesStr = 'Lượt ${slotNames.join(', ')} ($startTimeStr - $endTimeStr)';
    
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
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  const Text('Tóm tắt dịch vụ', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // Summary info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng thời gian', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      Text('${requiredSlots * 45} phút', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Số lượng slot đặt', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      Text('$requiredSlots slot', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Tổng tiền dịch vụ', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      Text(formattedTotal, style: const TextStyle(color: Color(0xFF4EE1F1), fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Địa điểm & Trạm', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(branchName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                            Text(stationName, style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
                      const Text('Số Slot', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      Expanded(
                        child: Text(
                          slotIndicesStr, 
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Thời gian dự kiến', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      Text('$startTimeStr - $endTimeStr', style: const TextStyle(color: Color(0xFF4EE1F1), fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Mã giảm giá
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('MÃ GIẢM GIÁ', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () {},
                        child: const Row(
                          children: [
                            Icon(Icons.local_activity, color: Color(0xFF4EE1F1), size: 14),
                            SizedBox(width: 4),
                            Text('Xem thêm mã giảm giá', style: TextStyle(color: Color(0xFF4EE1F1), fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                              hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        child: const Text('ÁP MÃ', style: TextStyle(color: Color(0xFF0F2050), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Payment method
                  const Text('PHƯƠNG THỨC THANH TOÁN', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => _paymentMethod = 'vnpay'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _paymentMethod == 'vnpay' ? Colors.white.withOpacity(0.1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _paymentMethod == 'vnpay' ? const Color(0xFF4EE1F1) : Colors.white24),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.qr_code, color: _paymentMethod == 'vnpay' ? const Color(0xFF4EE1F1) : Colors.white70, size: 18),
                                const SizedBox(width: 8),
                                Text('VNPAY', style: TextStyle(color: _paymentMethod == 'vnpay' ? Colors.white : Colors.white70, fontWeight: _paymentMethod == 'vnpay' ? FontWeight.bold : FontWeight.normal)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => _paymentMethod = 'cash'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _paymentMethod == 'cash' ? Colors.white.withOpacity(0.1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _paymentMethod == 'cash' ? const Color(0xFF4EE1F1) : Colors.white24),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.money, color: _paymentMethod == 'cash' ? const Color(0xFF4EE1F1) : Colors.white70, size: 18),
                                const SizedBox(width: 8),
                                Text('Tiền mặt', style: TextStyle(color: _paymentMethod == 'cash' ? Colors.white : Colors.white70, fontWeight: _paymentMethod == 'cash' ? FontWeight.bold : FontWeight.normal)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close popup
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đang chuyển hướng thanh toán...')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4EE1F1),
                        foregroundColor: const Color(0xFF0F2050),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Thanh toán', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        }
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
        border: Border.all(color: isSelected ? const Color(0xFF0F2050) : Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 110,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1545199653-f7725da878bc?auto=format&fit=crop&q=80'),
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
                Text(address, style: const TextStyle(fontSize: 12, color: Colors.black54)),
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
        border: Border.all(color: isSelected ? const Color(0xFF0F2050) : Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(Icons.local_car_wash_outlined, color: isSelected ? Colors.white : Colors.black54, size: 24),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? Colors.white : Colors.black)),
          const SizedBox(height: 2),
          Text(status, style: TextStyle(fontSize: 9, color: isSelected ? Colors.white70 : Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildMainServiceCard(String title, String desc, String price, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F2050) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF0F2050) : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                title == 'Cơ bản' ? Icons.water_drop_outlined : 
                title == 'Nâng cao' ? Icons.auto_fix_high : Icons.diamond_outlined,
                color: isSelected ? Colors.white : Colors.black87
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black)),
                  const SizedBox(height: 4),
                  Text(desc, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white70 : Colors.black54)),
                ],
              ),
            ),
            Text(price, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddonServiceCard(String title, String price, bool isChecked, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isChecked ? Colors.black87 : Colors.grey.shade300),
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
              child: isChecked ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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
      onTap: () => setState(() {
        _selectedStationIndex = index;
        _selectedTimeSlotIndex = -1; // Reset slot khi chuyển trạm
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
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
    List<String> names = ['LunaWash Linh Đông', 'LunaWash Quận 1', 'LunaWash Quận 7', 'LunaWash Tân Bình', 'LunaWash Tân Thới Hiệp'];
    return names[index];
  }

  String _getBranchAddress(int index) {
    List<String> addresses = ['Thủ Đức, HCM', '123 Lê Lợi, Bến Thành', '456 Nguyễn Văn Linh', '789 Cộng Hòa, Phường 13', 'Quận 12, HCM'];
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

  String _getBranchHours(int index) {
    List<String> hours = ['06:00 - 22:00', '07:00 - 23:00', '06:00 - 22:00', '06:00 - 22:30', '06:00 - 22:00'];
    return hours[index];
  }

  void _showBranchPickerBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Chọn chi nhánh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    title: Text(_getBranchName(index), style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    subtitle: Text(_getBranchAddress(index), style: const TextStyle(fontSize: 12)),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.black) : null,
                    onTap: () {
                      setState(() {
                        _selectedBranchIndex = index;
                        _selectedStationIndex = 0;
                        _selectedTimeSlotIndex = -1;
                      });
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

  Widget _buildInteriorCleaningDetailedOption() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isInteriorCleanSelected ? Colors.blue : Colors.grey.shade300, width: _isInteriorCleanSelected ? 2 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.cleaning_services, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text('DỊCH VỤ VỆ SINH NỘI THẤT KÈM THEO', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Dịch vụ bổ sung vệ sinh nội thất chuyên sâu tùy chọn. Hệ thống tự động nhận diện loại xe hiện tại của bạn để áp dụng mức giá và số slot phù hợp.', style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4)),
          const SizedBox(height: 16),
          
          // Bảng thông số chi tiết
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: const [
                      Expanded(flex: 3, child: Text('LOẠI XE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black54))),
                      Expanded(flex: 3, child: Text('GIÁ ĐỀ XUẤT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black54))),
                      Expanded(flex: 2, child: Text('SỐ SLOT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black54), textAlign: TextAlign.right)),
                    ],
                  ),
                ),
                ...List.generate(_vehicleTypes.length, (index) {
                  bool isSelected = _selectedVehicleIndex == index;
                  var v = _vehicleTypes[index];
                  return Container(
                    color: isSelected ? Colors.blue.withOpacity(0.05) : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text(v['name'], style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? Colors.blue.shade700 : Colors.black87, fontSize: 12))),
                        Expanded(flex: 3, child: Text(v['price'], style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.bold, color: isSelected ? Colors.blue.shade700 : Colors.black87, fontSize: 12))),
                        Expanded(flex: 2, child: Text('${v['slots']} slot', style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.blue.shade700 : Colors.black54, fontSize: 12), textAlign: TextAlign.right)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Lưu ý quan trọng
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Lưu ý quan trọng khi chọn dịch vụ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber)),
                      SizedBox(height: 4),
                      Text('Khi chọn thêm dịch vụ vệ sinh nội thất, các slot đặt lịch bắt buộc phải chọn liên tiếp và liền kề nhau.', style: TextStyle(fontSize: 11, color: Colors.black87, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Checkbox Thêm gói
          GestureDetector(
            onTap: () => setState(() {
              _isInteriorCleanSelected = !_isInteriorCleanSelected;
              _selectedTimeSlotIndex = -1;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: _isInteriorCleanSelected ? Colors.blue : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: _isInteriorCleanSelected ? Colors.blue.shade50 : Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isInteriorCleanSelected ? Icons.check_box : Icons.check_box_outline_blank, color: _isInteriorCleanSelected ? Colors.blue : Colors.grey),
                  const SizedBox(width: 8),
                  Text('THÊM GÓI VỆ SINH NỘI THẤT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _isInteriorCleanSelected ? Colors.blue : Colors.black87)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSavedVehiclePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Chọn xe của bạn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _savedVehicles.length,
                itemBuilder: (context, index) {
                  bool isSelected = _selectedSavedVehicleIndex == index;
                  var vehicle = _savedVehicles[index];
                  var type = _vehicleTypes[vehicle['typeIndex']]['name'];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.directions_car, color: isSelected ? Colors.blue : Colors.black54),
                    ),
                    title: Text(vehicle['plate'], style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    subtitle: Text(type, style: const TextStyle(fontSize: 12)),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : null,
                    onTap: () {
                      setState(() {
                        _selectedSavedVehicleIndex = index;
                        _selectedVehicleIndex = vehicle['typeIndex'];
                        _selectedTimeSlotIndex = -1;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: Colors.blue),
                title: const Text('Thêm xe mới', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
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
