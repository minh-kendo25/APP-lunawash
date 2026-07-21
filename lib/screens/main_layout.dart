import 'package:flutter/material.dart';
import 'dart:ui';
import 'home_screen.dart';
import 'booking_screen.dart';
import 'history_screen.dart';
import 'support_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import '../services/api_service.dart';

class MainLayout extends StatefulWidget {
  final int initialIndex;
  
  const MainLayout({super.key, this.initialIndex = 0});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  late final List<Widget> _screens = [
    HomeScreen(onNavigate: _onTabTapped),
    const BookingScreen(),
    const HistoryScreen(),
    const SupportScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 1: return 'Đặt lịch';
      case 2: return 'Lịch sử dịch vụ';
      case 3: return 'Hỗ trợ';
      default: return 'LunaWash';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _currentIndex == 0
            ? Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuBMIHwZp8RLc19nD4KtDTiu2Q4Nfx7irfa6j_R-1Cel5RXbphsnQnvgVnZk42WxpmbzInAHYM11SRsJDI2Vp8k74kreh2jUhGvsm0YkwUKn4m2KbN1qy9siwvSSQUGmk6arV6AcHgzQ2o8l26YiRZdItVWCMkAPPqZORnpv3MSrKdX0mbqFdWa2CiA65ioUN4VlN0bi3leO-qXk8jgudqm56MsW4gVgQXOkH-PScpiJ2aQItKCWjdLS77HETiuOPKOmywUITMCVN9g',
                      height: 32,
                      width: 32,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.water_drop, color: Color(0xFF0F2050)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('LunaWash', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F2050), fontSize: 20)),
                ],
              )
            : Text(_getAppBarTitle(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F2050))),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade300,
                child: const Icon(Icons.person, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      extendBody: true,
      body: _screens[_currentIndex],
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Container(
            height: 65,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Stack(
                  children: [
                    // Base Glass Gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.16),
                            Colors.white.withOpacity(0.04),
                          ],
                        ),
                      ),
                    ),
                    // Specular Highlight (Ellipse)
                    Positioned(
                      top: -30,
                      left: -20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.08),
                              blurRadius: 60,
                              spreadRadius: 30,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Top Highlight Gradient (Edge refraction)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 15,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.55),
                              Colors.white.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Inner Shadow (Simulated with a faint top-inner border)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(34),
                        border: Border(
                          top: BorderSide(color: Colors.white.withOpacity(0.18), width: 1.5),
                        ),
                      ),
                    ),
                    // Thin white border 1px
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(34),
                        border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
                      ),
                    ),
                    // Content
                    NavigationBarTheme(
                      data: NavigationBarThemeData(
                        indicatorColor: Colors.transparent,
                        labelTextStyle: MaterialStateProperty.resolveWith((states) {
                          if (states.contains(MaterialState.selected)) {
                            return const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F2050));
                          }
                          return TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: const Color(0xFF0F2050).withOpacity(0.5));
                        }),
                        iconTheme: MaterialStateProperty.resolveWith((states) {
                          if (states.contains(MaterialState.selected)) {
                            return const IconThemeData(color: Color(0xFF0F2050), size: 28);
                          }
                          return IconThemeData(color: const Color(0xFF0F2050).withOpacity(0.5), size: 26);
                        }),
                      ),
                      child: NavigationBar(
                        selectedIndex: _currentIndex,
                        onDestinationSelected: _onTabTapped,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        height: 65,
                        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                        destinations: const [
                          NavigationDestination(
                            icon: Icon(Icons.home_outlined),
                            selectedIcon: Icon(Icons.home),
                            label: 'Home',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.calendar_month_outlined),
                            selectedIcon: Icon(Icons.calendar_month),
                            label: 'Lịch hẹn',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.history_outlined),
                            selectedIcon: Icon(Icons.history),
                            label: 'Lịch sử',
                          ),
                          NavigationDestination(
                            icon: Icon(Icons.support_agent_outlined),
                            selectedIcon: Icon(Icons.support_agent),
                            label: 'Hỗ trợ',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF0F2050),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuBMIHwZp8RLc19nD4KtDTiu2Q4Nfx7irfa6j_R-1Cel5RXbphsnQnvgVnZk42WxpmbzInAHYM11SRsJDI2Vp8k74kreh2jUhGvsm0YkwUKn4m2KbN1qy9siwvSSQUGmk6arV6AcHgzQ2o8l26YiRZdItVWCMkAPPqZORnpv3MSrKdX0mbqFdWa2CiA65ioUN4VlN0bi3leO-qXk8jgudqm56MsW4gVgQXOkH-PScpiJ2aQItKCWjdLS77HETiuOPKOmywUITMCVN9g',
                        height: 44,
                        width: 44,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.local_car_wash, color: Color(0xFF4EE1F1), size: 36),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('LunaWash System', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const Text('Phiên bản 1.0.0', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(Icons.info_outline, 'Thông tin hệ thống', () => _showSystemInfo(context)),
                _buildDrawerItem(Icons.gavel, 'Pháp lý & Điều khoản', () => _showLegalInfo(context)),
                _buildDrawerItem(Icons.settings_outlined, 'Cài đặt App', () => _showSettings(context)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(),
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                  onTap: () async {
                    await ApiService.logout();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '© 2026 Bản quyền thuộc về LunaWash',
              style: TextStyle(color: Colors.black54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0F2050)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
      onTap: onTap,
    );
  }

  void _showSystemInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info, color: Color(0xFF4EE1F1)),
            SizedBox(width: 8),
            Text('Thông tin hệ thống', style: TextStyle(color: Color(0xFF0F2050), fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tên ứng dụng: LunaWash', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Phiên bản: 1.0.0 (Build 42)'),
            SizedBox(height: 8),
            Text('Môi trường: Production'),
            SizedBox(height: 8),
            Text('Máy chủ: ap-southeast-1 (Singapore)'),
            SizedBox(height: 8),
            Text('ID Thiết bị: 8A9F-2B4C-11D3'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng', style: TextStyle(color: Color(0xFF0F2050), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLegalInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.gavel, color: Color(0xFF0F2050)),
            SizedBox(width: 8),
            Text('Pháp lý & Điều khoản', style: TextStyle(color: Color(0xFF0F2050), fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: Text(
              '1. Điều khoản sử dụng\n'
              'Bằng việc sử dụng ứng dụng LunaWash, bạn đồng ý với các điều khoản của chúng tôi về việc cung cấp dịch vụ vệ sinh xe thông minh.\n\n'
              '2. Quyền riêng tư\n'
              'Chúng tôi cam kết bảo mật thông tin cá nhân của bạn. Dữ liệu biển số xe, số điện thoại chỉ được sử dụng cho mục đích cung cấp dịch vụ.\n\n'
              '3. Trách nhiệm bồi thường\n'
              'LunaWash có chính sách bảo hiểm 100% đối với các hư hỏng phát sinh do lỗi của nhân viên trong quá trình thao tác.\n\n'
              '4. Hủy dịch vụ\n'
              'Khách hàng có thể hủy dịch vụ miễn phí trước 30 phút so với giờ hẹn. Hủy sau thời gian này có thể phát sinh phí.\n\n'
              'Vui lòng truy cập website lunawash.vn để xem bản đầy đủ.',
              style: TextStyle(height: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu', style: TextStyle(color: Color(0xFF0F2050), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    bool _isDarkMode = false;
    bool _isNotificationEnabled = true;
    String _selectedLanguage = 'Tiếng Việt';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: const Color(0xFFF8F9FA),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const Text('Cài đặt Ứng dụng', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F2050))),
                const SizedBox(height: 24),
                
                // Notifications
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Nhận thông báo', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Ưu đãi, trạng thái đơn hàng'),
                  value: _isNotificationEnabled,
                  activeColor: const Color(0xFF4EE1F1),
                  onChanged: (val) {
                    setState(() { _isNotificationEnabled = val; });
                  },
                ),
                const Divider(),
                
                // Dark Mode
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Chế độ tối (Dark Mode)', style: TextStyle(fontWeight: FontWeight.w600)),
                  value: _isDarkMode,
                  activeColor: const Color(0xFF4EE1F1),
                  onChanged: (val) {
                    setState(() { _isDarkMode = val; });
                  },
                ),
                const Divider(),
                
                // Language
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ngôn ngữ', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: DropdownButton<String>(
                    value: _selectedLanguage,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0F2050)),
                    items: ['Tiếng Việt', 'English']
                        .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() { _selectedLanguage = val; });
                    },
                  ),
                ),
                
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2050),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Xong', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          );
        }
      ),
    );
  }
}
