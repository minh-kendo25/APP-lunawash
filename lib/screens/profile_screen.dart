import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String _fullName = '';
  String _email = '';
  String _phone = '';
  String _address = 'Chưa cập nhật';
  int _points = 0;
  String _tierName = 'ĐỒNG';
  List<dynamic> _cars = [];
  List<dynamic> _membershipTiers = [];

  final List<Map<String, String>> _vehicleTypes = [
    {'id': 'VT-OTO-2C', 'name': 'Ô tô 2 chỗ'},
    {'id': 'VT-OTO-4C', 'name': 'Ô tô 4 chỗ'},
    {'id': 'VT-OTO-7C', 'name': 'Ô tô 7 chỗ'},
    {'id': 'VT-OTO-BT', 'name': 'Xe bán tải'},
    {'id': 'VT-OTO-SUV', 'name': 'SUV'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final profile = await ApiService.getUserProfile();
      final vehicles = await ApiService.getMyVehicles();
      final tiers = await ApiService.getMembershipSettings();

      if (mounted) {
        setState(() {
          if (!profile.containsKey('error')) {
            _fullName = (profile['fullName'] ?? '').toString();
            _email = (profile['email'] ?? '').toString();
            _phone = (profile['phone'] ?? '').toString();
            _address = (profile['address'] ?? 'Chưa cập nhật').toString();
            if (_address.isEmpty) _address = 'Chưa cập nhật';
            _points = (profile['loyalty']?['currentPoints'] as num?)?.toInt() ?? 0;
            _tierName = (profile['loyalty']?['tierName'] ?? 'ĐỒNG').toString();
          }
          _cars = vehicles;
          _membershipTiers = tiers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Hồ sơ của tôi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF8F9FA),
        foregroundColor: const Color(0xFF0F2050),
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
            // Avatar & Name
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFF0F2050),
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(_fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F2050))),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.workspace_premium, size: 16, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text('Thành viên $_tierName', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Điểm tích luỹ
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F2050),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.stars, color: Color(0xFF4EE1F1), size: 28),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Điểm tích luỹ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('$_points pt', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4EE1F1),
                      side: const BorderSide(color: Color(0xFF4EE1F1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Đổi quà', style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildMembershipTable(),
            const SizedBox(height: 24),

            // Thông tin cá nhân
            _buildSectionHeader('Thông tin cá nhân', Icons.edit, 'Chỉnh sửa', _showEditProfilePopup),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Email', _email),
                  const Divider(),
                  _buildInfoRow('Số điện thoại', _phone),
                  const Divider(),
                  _buildInfoRow('Địa chỉ', _address),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quản lý xe
            _buildSectionHeader('Quản lý xe', Icons.add, 'Thêm xe mới', _showAddCarPopup),
            if (_cars.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('Chưa có xe nào được thêm', style: TextStyle(color: Colors.black54))),
              )
            else
              ..._cars.map((car) => _buildCarCard(car)),
              
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Đăng xuất', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData actionIcon, String actionLabel, VoidCallback onAction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F2050))),
          GestureDetector(
            onTap: onAction,
            child: Row(
              children: [
                Icon(actionIcon, size: 16, color: const Color(0xFF0F2050)),
                const SizedBox(width: 4),
                Text(actionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F2050))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildCarCard(dynamic car) {
    String name = (car['name'] ?? car['Name'] ?? car['vehicleModel'] ?? car['make'] ?? '').toString();
    String license = (car['license'] ?? car['License'] ?? car['licensePlate'] ?? 'Chưa có biển số').toString();
    String color = (car['color'] ?? car['Color'] ?? '').toString();
    String typeName = (car['vehicleTypeName'] ?? car['VehicleTypeName'] ?? '').toString();

    String subtitle = typeName;
    if (color.isNotEmpty) subtitle += (subtitle.isNotEmpty ? ' - ' : '') + color;
    if (name.isNotEmpty) subtitle += (subtitle.isNotEmpty ? ' (' : '') + name + (subtitle.isNotEmpty ? ')' : '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.directions_car, color: Colors.blue),
        ),
        title: Text(license, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F2050))),
        subtitle: subtitle.isNotEmpty ? Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 13)),
        ) : null,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.black45),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Xác nhận xóa'),
                content: const Text('Bạn có chắc chắn muốn xóa xe này?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      var carId = car['id'] ?? car['Id'];
                      if (carId != null) {
                        setState(() => _isLoading = true);
                        await ApiService.deleteVehicle(carId.toString());
                        _loadData();
                      }
                    },
                    child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showEditProfilePopup() {
    final nameController = TextEditingController(text: _fullName);
    final emailController = TextEditingController(text: _email);
    final phoneController = TextEditingController(text: _phone);
    final addressController = TextEditingController(text: _address);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text('Chỉnh sửa thông tin', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F2050))),
                const SizedBox(height: 24),
                _buildTextField('Họ và tên', nameController),
                const SizedBox(height: 16),
                _buildTextField('Email', emailController),
                const SizedBox(height: 16),
                _buildTextField('Số điện thoại', phoneController),
                const SizedBox(height: 16),
                _buildTextField('Địa chỉ', addressController),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      setState(() => _isLoading = true);
                      await ApiService.updateProfile(
                        nameController.text,
                        phoneController.text,
                        addressController.text,
                      );
                      _loadData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4EE1F1),
                      foregroundColor: const Color(0xFF0F2050),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Lưu thay đổi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddCarPopup() {
    final nameController = TextEditingController();
    final licenseController = TextEditingController();
    final colorController = TextEditingController();
    String? selectedVehicleTypeId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Text('Thêm thông tin xe mới', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F2050))),
                    const SizedBox(height: 24),
                    _buildTextField('Tên xe (VD: Toyota Vios)', nameController),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Biển số xe', licenseController)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField('Màu xe', colorController)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedVehicleTypeId,
                          hint: const Text('Chọn loại xe', style: TextStyle(color: Colors.black54)),
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                          items: _vehicleTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type['id'],
                              child: Text(type['name']!),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setModalState(() {
                              selectedVehicleTypeId = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified_user_outlined, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Thông tin của bạn sẽ được bảo mật tuyệt đối',
                              style: TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Hủy', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (nameController.text.isNotEmpty && selectedVehicleTypeId != null) {
                                Navigator.pop(context);
                                setState(() => _isLoading = true);
                                await ApiService.addVehicle(
                                  nameController.text,
                                  licenseController.text,
                                  colorController.text,
                                  selectedVehicleTypeId!,
                                );
                                _loadData();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Vui lòng điền đủ tên xe và loại xe')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F2050),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text('LƯU THÔNG TIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ),
                      ],
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

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4EE1F1)),
        ),
      ),
    );
  }

  Widget _buildMembershipTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Điều kiện xét hạng',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F2050),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildTableRow('Hạng thành viên', 'Điều kiện lên hạng', isHeader: true),
              if (_membershipTiers.isEmpty) ...[
                const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
                _buildTableRow('ĐỒNG', 'Mặc định'),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
                _buildTableRow('BẠC', 'Từ 1.000 pt'),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
                _buildTableRow('VÀNG', 'Từ 3.000 pt'),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
                _buildTableRow('PLATINUM', 'Từ 5.000 pt'),
              ] else ..._membershipTiers.map((tier) {
                final String name = ((tier['tierName'] ?? '').toString().toUpperCase()).toString();
                final int points = (tier['minPoints'] as num?)?.toInt() ?? 0;
                final String condition = points <= 0 ? 'Mặc định' : 'Từ ${NumberFormat.decimalPattern('vi_VN').format(points)} pt';
                return Column(
                  children: [
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
                    _buildTableRow(name, condition),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableRow(String col1, String col2, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              col1,
              style: TextStyle(
                fontWeight: isHeader ? FontWeight.bold : FontWeight.w600,
                color: isHeader ? Colors.grey.shade600 : const Color(0xFF0F2050),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              col2,
              style: TextStyle(
                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                color: isHeader ? Colors.grey.shade600 : Colors.black87,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
