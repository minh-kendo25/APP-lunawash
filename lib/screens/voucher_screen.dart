import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({super.key});

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  List<Map<String, dynamic>> _vouchers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedVouchers = prefs.getStringList('saved_vouchers');
    
    if (savedVouchers != null) {
      setState(() {
        _vouchers = savedVouchers
            .map((e) => json.decode(e) as Map<String, dynamic>)
            .toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _vouchers = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _removeVoucher(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? savedVouchers = prefs.getStringList('saved_vouchers');
    
    if (savedVouchers != null) {
      savedVouchers.removeAt(index);
      await prefs.setStringList('saved_vouchers', savedVouchers);
      
      setState(() {
        _vouchers.removeAt(index);
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xoá mã giảm giá')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Ví Mã Giảm Giá', style: TextStyle(color: Color(0xFF0F2050), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF0F2050)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vouchers.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _vouchers.length,
                  itemBuilder: (context, index) {
                    final voucher = _vouchers[index];
                    return _buildVoucherCard(voucher, index);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_activity_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Ví voucher trống',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F2050)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Lưu các mã giảm giá từ trang chủ để sử dụng tại đây.',
            style: TextStyle(color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(Map<String, dynamic> voucher, int index) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF0F2050), Color(0xFF1E3A8A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            // Left icon part
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Colors.white24, width: 1, style: BorderStyle.solid)),
              ),
              child: const Icon(Icons.percent_rounded, color: Color(0xFF4EE1F1), size: 40),
            ),
            // Right info part
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      voucher['title'] ?? 'Mã giảm giá',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mã: ${voucher['code']}',
                      style: const TextStyle(color: Color(0xFF4EE1F1), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      voucher['subtitle'] ?? 'HSD: Không giới hạn',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            // Delete button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white54),
              onPressed: () => _removeVoucher(index),
            ),
          ],
        ),
      ),
    );
  }
}
