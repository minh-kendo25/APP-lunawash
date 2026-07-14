import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'voucher_screen.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  
  const HomeScreen({super.key, this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _mainPackages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      final services = await ApiService.fetchServices();
      setState(() {
        _mainPackages = services.where((s) => s['serviceType'] == 'Package').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveVoucher(Map<String, dynamic> voucherData) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedVouchers = prefs.getStringList('saved_vouchers') ?? [];
    
    // Check if already saved
    bool exists = savedVouchers.any((element) {
      var map = json.decode(element);
      return map['code'] == voucherData['code'];
    });

    if (exists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn đã lưu mã này rồi!')),
      );
      return;
    }

    savedVouchers.add(json.encode(voucherData));
    await prefs.setStringList('saved_vouchers', savedVouchers);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lưu mã giảm giá thành công!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatCurrency(int amount) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Banner
            Stack(
              children: [
                Container(
                  height: 240,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F2050),
                    image: DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1601362840469-51e4d8d58785?auto=format&fit=crop&q=80'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'Trải nghiệm rửa xe công\nnghệ đỉnh cao',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Chăm sóc xe chuyên nghiệp với hệ thống\ntự động và đội ngũ tận tâm.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            widget.onNavigate?.call(1);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4EE1F1),
                            foregroundColor: const Color(0xFF0F2050),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('Đặt lịch ngay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.local_activity, color: Color(0xFF4EE1F1)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const VoucherScreen()),
                        );
                      },
                      tooltip: 'Ví Mã Giảm Giá',
                    ),
                  ),
                ),
              ],
            ),

            // Ưu đãi đặc biệt
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ưu đãi đặc biệt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const VoucherScreen()));
                    }, 
                    child: const Text('Ví Voucher', style: TextStyle(color: Color(0xFF0F2050), fontWeight: FontWeight.bold))
                  )
                ],
              ),
            ),
            
            SizedBox(
              height: 140,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildPromoCard(
                    title: 'Giảm 20% lần đầu', 
                    subtitle: 'Nhập mã: LUNANEW', 
                    bgColor: const Color(0xFF0F2050),
                    voucherData: {
                      'code': 'LUNANEW',
                      'title': 'Giảm 20% lần đầu',
                      'subtitle': 'Dành cho khách hàng mới',
                      'discount': 20,
                    }
                  ),
                  _buildPromoCard(
                    title: 'Giảm 50K thứ 3', 
                    subtitle: 'Nhập mã: TUESDAY50', 
                    bgColor: const Color(0xFF0F2050),
                    voucherData: {
                      'code': 'TUESDAY50',
                      'title': 'Giảm 50K thứ 3',
                      'subtitle': 'Áp dụng cho ngày thứ 3 hàng tuần',
                      'discountAmount': 50000,
                    }
                  ),
                ],
              ),
            ),

            // Các gói dịch vụ
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0F7FA),
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    child: const Text('DỊCH VỤ HÀNG ĐẦU', style: TextStyle(color: Color(0xFF0F2050), fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  const Text('Chọn gói dịch vụ\nphù hợp', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F2050), height: 1.2)),
                  const SizedBox(height: 12),
                  const Text('Trải nghiệm công nghệ rửa xe thông minh nhanh chóng, chất lượng vượt trội tại LunaWash.', style: TextStyle(color: Colors.black54, fontSize: 13)),
                ],
              ),
            ),

            _isLoading 
                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                : SizedBox(
                    height: 260,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _mainPackages.length,
                      itemBuilder: (context, index) {
                        final pkg = _mainPackages[index];
                        // Tìm giá thấp nhất để hiển thị đại diện
                        int displayPrice = 0;
                        int displayDuration = 0;
                        if (pkg['prices'] != null && (pkg['prices'] as List).isNotEmpty) {
                          displayPrice = (pkg['prices'][0]['price'] as num).toInt();
                          displayDuration = (pkg['prices'][0]['durationMinutes'] as num).toInt();
                        }
                        
                        List<dynamic> features = pkg['features'] ?? [];
                        
                        return _buildServicePackageCard(
                          title: pkg['serviceName'] ?? 'Gói dịch vụ',
                          description: pkg['description'] ?? '',
                          duration: '~$displayDuration phút',
                          price: displayPrice,
                          features: features,
                          isPopular: pkg['isPopular'] == true,
                          onTap: () {
                            widget.onNavigate?.call(1); // Chuyển sang tab đặt lịch
                          }
                        );
                      },
                    ),
                  ),

            const SizedBox(height: 20), // Không gian đệm dưới cùng
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCard({required String title, required String subtitle, required Color bgColor, required Map<String, dynamic> voucherData}) {
    return GestureDetector(
      onTap: () => _saveVoucher(voucherData),
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: bgColor,
          image: const DecorationImage(
            image: NetworkImage('https://images.unsplash.com/photo-1552930294-6b595f4c2974?auto=format&fit=crop&q=80'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const Icon(Icons.download_rounded, color: Colors.white, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicePackageCard({
    required String title,
    required String description,
    required String duration,
    required int price,
    required List<dynamic> features,
    required bool isPopular,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 200,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPopular ? const Color(0xFF0F2050) : Colors.grey.shade200, width: isPopular ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    title.toLowerCase().contains('cao cấp') ? Icons.diamond : (title.toLowerCase().contains('nâng cao') ? Icons.waves : Icons.water_drop),
                    color: const Color(0xFF0F2050),
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F2050)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        duration,
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (features.isNotEmpty) ...[
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    ...features.take(2).map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, color: Colors.green, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  f['featureText'] ?? '',
                                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                  const Spacer(),
                  Text(
                    _formatCurrency(price),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F2050)),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isPopular ? Colors.white : const Color(0xFF0F2050),
                        backgroundColor: isPopular ? const Color(0xFF0F2050) : Colors.transparent,
                        side: const BorderSide(color: Color(0xFF0F2050)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Chọn ngay', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
            if (isPopular)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F2050),
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(14)),
                  ),
                  child: const Text('PHỔ BIẾN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
