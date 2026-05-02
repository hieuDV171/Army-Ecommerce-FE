import 'package:army_ecommerce/core/utils/logger.dart';
import 'package:flutter/material.dart';

class VerifyOtpScreen extends StatefulWidget{
  final String phoneNumber;

  const VerifyOtpScreen({super.key, required this.phoneNumber});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final TextEditingController _otpController = TextEditingController();

  void _onVerifyPressed() {
    final otpCode = _otpController.text.trim();

    // Theo tài liệu: Mã OTP gồm 6 ký tự (số kèm chữ)[cite: 1]
    if (otpCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mã xác thực phải gồm đúng 6 ký tự')),
      );
      return;
    }

    // TODO: Ở bước tiếp theo, bạn sẽ thêm sự kiện VerifyOtpPressed vào BLoC
    // và gọi API check_otp ở đây. Tạm thời in ra màn hình.
    logger.i('Đang gửi mã $otpCode của số ${widget.phoneNumber} lên server...');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác thực tài khoản'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Mã xác thực 6 ký tự đã được gửi đến số \n${widget.phoneNumber}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: 'Mã xác thực (OTP)',
                border: OutlineInputBorder(),
              ),
              // Bàn phím text vì mã có thể chứa cả chữ và số[cite: 1]
              keyboardType: TextInputType.text,
              maxLength: 6, // Giới hạn 6 ký tự trên giao diện
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _onVerifyPressed,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.deepOrangeAccent,
              ),
              child: const Text('XÁC NHẬN'),
            ),
          ],
        ),
      ),
    );
  }
}