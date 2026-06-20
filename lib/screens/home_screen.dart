import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import '../services/api_service.dart';

class HomeScreen extends StatelessWidget {
  final Function(int)? onNavigate;
  
  const HomeScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Banner
            Container(
              height: 240,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF0F2050),
                image: DecorationImage(
                  // Ảnh placeholder ô tô
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
                        onNavigate?.call(1);
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

            // Ưu đãi đặc biệt
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Text('Ưu đãi đặc biệt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            
            SizedBox(
              height: 140,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildPromoCard('Giảm 20% lần đầu', 'Nhập mã: LUNANEW', const Color(0xFF0F2050)),
                  _buildPromoCard('Thành viên mới', 'Đăng ký ngay', const Color(0xFF0F2050)),
                ],
              ),
            ),
            const SizedBox(height: 100), // Không gian cho nút FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          onNavigate?.call(1);
        },
        backgroundColor: const Color(0xFF0F2050),
        foregroundColor: const Color(0xFF4EE1F1),
        icon: const Icon(Icons.add),
        label: const Text('Đặt lịch mới', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPromoCard(String title, String subtitle, Color bgColor) {
    return Container(
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
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
