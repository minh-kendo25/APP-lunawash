import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _ongoingBookings = [];
  List<dynamic> _pastBookings = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final bookings = await ApiService.getBookingHistory();
      if (mounted) {
        setState(() {
          _ongoingBookings = bookings.where((b) => 
            b['status'] != 'Hoàn thành' && b['status'] != 'Đã hủy'
          ).toList();
          _pastBookings = bookings.where((b) => 
            b['status'] == 'Hoàn thành' || b['status'] == 'Đã hủy'
          ).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Đang diễn ra
                  if (_ongoingBookings.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ĐANG DIỄN RA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('${_ongoingBookings.length} BOOKING', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._ongoingBookings.map((b) => _buildOngoingCard(b)).toList(),
                    const SizedBox(height: 32),
                  ],
                  
                  // Lịch sử trước đó
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('LỊCH SỬ TRƯỚC ĐÓ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                      Text('Lọc kết quả', style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (_pastBookings.isEmpty && _ongoingBookings.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('Bạn chưa có lịch đặt nào.', style: TextStyle(fontSize: 14, color: Colors.black54)),
                      ),
                    )
                  else ...[
                    ..._pastBookings.map((b) {
                      final title = b['packageName'] ?? b['services'] ?? 'Dịch vụ rửa xe';
                      final car = b['vehicleInfo'] ?? '';
                      final date = b['bookingDate']?.toString().substring(0, 10) ?? '';
                      final price = b['totalPrice']?.toString() ?? '0đ';
                      final status = (b['status'] ?? '').toString().toUpperCase();
                      final color = status == 'CANCELLED' ? Colors.grey : Colors.teal;
                      final isCancelled = status == 'CANCELLED';
                      final branch = b['branchInfo'] ?? '';
                      final time = b['timeRange'] ?? '';
                      final bookingId = b['id']?.toString() ?? '';
                      return _buildHistoryCard(context, title, car, date, price, status, color, Icons.cleaning_services_outlined, branch: branch, time: time, isCancelled: isCancelled, bookingId: bookingId);
                    }).toList(),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('Bạn đã xem hết lịch sử dịch vụ.', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      ),
                    ),
                  ]
                ],
              ),
            ),
    );
  }

  Widget _buildOngoingCard(dynamic booking) {
    final title = booking['packageName'] ?? booking['services'] ?? 'Dịch vụ rửa xe';
    final car = booking['vehicleInfo'] ?? '';
    final time = booking['timeRange']?.replaceAll('\n', ' • ') ?? '';
    final branch = booking['branchInfo'] ?? '';
    final price = booking['totalPrice']?.toString() ?? '0đ';
    final status = booking['status'] ?? 'Đang chờ';
    final canCancel = status == 'Sắp đến';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.directions_car_filled, color: Colors.black87),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(car, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'Đang rửa' ? Colors.blue.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(status, style: TextStyle(
                  color: status == 'Đang rửa' ? Colors.blue : Colors.orange, 
                  fontSize: 10, 
                  fontWeight: FontWeight.bold
                )),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.black54),
              const SizedBox(width: 8),
              Text(branch, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.black54),
                  const SizedBox(width: 8),
                  Text(time, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                ],
              ),
              Text(
                price, 
                style: const TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: Colors.black,
                )
              ),
            ],
          ),
          if (canCancel) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext ctx) {
                      return AlertDialog(
                        title: const Text('Hủy lịch đặt', style: TextStyle(color: Color(0xFF0F2050))),
                        content: const Text('Bạn có chắc chắn muốn hủy lịch đặt này không? Hành động này không thể hoàn tác.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Không', style: TextStyle(color: Colors.grey)),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (c) => const Center(child: CircularProgressIndicator()),
                              );
                              final success = await ApiService.cancelBooking(booking['id'].toString());
                              if (context.mounted) {
                                Navigator.pop(context); // Tắt loading
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy lịch đặt thành công'), backgroundColor: Colors.teal));
                                  _loadHistory();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hủy lịch thất bại. Vui lòng thử lại!'), backgroundColor: Colors.red));
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Có, Hủy', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                label: const Text('Hủy lịch đặt', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, String title, String car, String date, String price, String status, Color statusColor, IconData icon, {String branch = '', String time = '', bool isCancelled = false, String bookingId = ''}) {
    return GestureDetector(
      onTap: () => _showHistoryDetailPopup(context, title, car, date, price, status, statusColor, isCancelled, bookingId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCancelled ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Icon(icon, color: isCancelled ? Colors.grey : Colors.black87),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title, 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: isCancelled ? Colors.grey : Colors.black
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(car, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.black54),
                    const SizedBox(width: 8),
                    Text(branch, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Colors.black54),
                        const SizedBox(width: 8),
                        Text(time, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                      ],
                    ),
                    Text(
                      price, 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: isCancelled ? Colors.grey : Colors.black,
                        decoration: isCancelled ? TextDecoration.lineThrough : null,
                      )
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  void _showHistoryDetailPopup(BuildContext context, String title, String car, String date, String price, String status, Color statusColor, bool isCancelled, String bookingId) {
    int _cleanlinessRating = 0;
    int _speedRating = 0;
    int _staffRating = 0;
    bool _isEdit = false;
    bool _isLoadingReview = !isCancelled;
    bool _hasFetched = false;
    final TextEditingController _commentController = TextEditingController();

    Widget buildStarRow(String label, int currentRating, Function(int) onRatingChanged) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0F2050))),
            Row(
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => onRatingChanged(index + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      index < currentRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: index < currentRating ? Colors.amber : Colors.grey.shade400,
                      size: 28,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            if (!_hasFetched && !isCancelled && bookingId.isNotEmpty) {
              _hasFetched = true;
              ApiService.getReviewByBooking(bookingId).then((reviewData) {
                if (reviewData != null) {
                  setState(() {
                    _cleanlinessRating = reviewData['cleanlinessRating'] ?? 0;
                    _speedRating = reviewData['speedRating'] ?? 0;
                    _staffRating = reviewData['staffRating'] ?? 0;
                    _commentController.text = reviewData['comment'] ?? '';
                    _isEdit = true;
                    _isLoadingReview = false;
                  });
                } else {
                  setState(() => _isLoadingReview = false);
                }
              }).catchError((_) {
                setState(() => _isLoadingReview = false);
              });
            }

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Chi tiết dịch vụ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F2050),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCancelled ? Colors.grey.shade200 : Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Service Info Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 12),
                            _buildDetailRow(Icons.directions_car_outlined, 'Xe', car),
                            const SizedBox(height: 8),
                            _buildDetailRow(Icons.calendar_today_outlined, 'Ngày hẹn', date),
                            const SizedBox(height: 8),
                            _buildDetailRow(Icons.location_on_outlined, 'Chi nhánh', 'Chi nhánh Linh Đông'),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Tổng thanh toán', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F2050))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Rating Section (only if completed)
                      if (!isCancelled) ...[
                        const Text(
                          'Đánh giá dịch vụ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F2050),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_isLoadingReview)
                          const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else ...[
                          buildStarRow('Mức độ sạch sẽ', _cleanlinessRating, (r) => setState(() => _cleanlinessRating = r)),
                          buildStarRow('Tốc độ dịch vụ', _speedRating, (r) => setState(() => _speedRating = r)),
                          buildStarRow('Thái độ nhân viên', _staffRating, (r) => setState(() => _staffRating = r)),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _commentController,
                            maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Chia sẻ trải nghiệm của bạn (không bắt buộc)',
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
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
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_cleanlinessRating == 0 || _speedRating == 0 || _staffRating == 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Vui lòng đánh giá đủ 3 tiêu chí!'), backgroundColor: Colors.red),
                                );
                                return;
                              }
                              
                              final calculatedOverall = double.parse(((_cleanlinessRating + _speedRating + _staffRating) / 3).toStringAsFixed(1));
                              final payload = {
                                'bookingId': bookingId,
                                'serviceRating': calculatedOverall,
                                'cleanlinessRating': _cleanlinessRating,
                                'speedRating': _speedRating,
                                'staffRating': _staffRating,
                                'comment': _commentController.text,
                              };
                              
                              final success = await ApiService.submitReview(payload, isEdit: _isEdit, bookingId: bookingId);
                              
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success ? 'Cảm ơn bạn đã đánh giá dịch vụ!' : 'Gửi đánh giá thất bại. Vui lòng thử lại!'),
                                    backgroundColor: success ? Colors.teal : Colors.red,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4EE1F1),
                              foregroundColor: const Color(0xFF0F2050),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(_isEdit ? 'Cập nhật đánh giá' : 'Gửi đánh giá', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                        ]
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ),
      ],
    );
  }
}
