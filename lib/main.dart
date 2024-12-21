// lib/main.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:async';
//import http
import 'package:http/http.dart' as http;
import 'package:qr_payment_scanner/config.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure QR Payment',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure QR Payment'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            const Text(
              'Welcome to Secure QR Payment',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Scan QR codes securely with AI fraud detection',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ScannerPage()),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Generate secure QR Code'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScannerPage extends StatefulWidget {
  const ScannerPage({Key? key}) : super(key: key);

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isProcessing = false;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  // Simulated backend check
  Future<bool> checkQRCodeSafety(String qrData) async {
    // Request to backend to check if QR code is safe
    var url = Config.BASE_URL + '/api/verify-qr/';
    /* Example post and response
    tarekbn@Hamzas-MacBook-Pro ~ % curl -X POST http://127.0.0.1:8000/api/verify-qr/ \
-H "Content-Type: application/json" \
-d '{
  "url": "http://example.com"
}'
{"is_suspicious":false,"reason":"Classified as safe","verification_id":15}%     tarekbn@Hamzas-MacBook-Pro ~ % 


Case 2 : 
tarekbn@Hamzas-MacBook-Pro ~ % curl -X POST http://127.0.0.1:8000/api/verify-qr/ \                                                                           
-H "Content-Type: application/json" \
-d '{
  "url": "http://example.com",
  "created_at": "2023-10-01T12:00:00Z",
  "expires_at": "2023-10-31T12:00:00Z",
  "transaction_at": "2023-10-15T12:00:00Z"
}'
{"is_suspicious":false,"reason":"Classified as safe","verification_id":16}%     tarekbn@Hamzas-MacBook-Pro ~ % 


    */

    print('going to send request to $url');
    print('with json data :');
    print(jsonEncode(<String, String>{
      'url': qrData,
    }));

    // Send a POST request to the backend
    var response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'url': qrData,
      }),
    );

    // Parse the response
    var data = jsonDecode(response.body);

    // Return the safety status
    return data['is_suspicious'] == false;
  }

  void onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (isProcessing) return;
      isProcessing = true;

      // Pause scanner
      controller.pauseCamera();

      // Show processing dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Verifying Payment...'),
              ],
            ),
          );
        },
      );

      // Check QR safety
      bool isSafe = await checkQRCodeSafety(scanData.code ?? '');

      // Close processing dialog
      Navigator.pop(context);

      if (isSafe) {
        showSuccessDialog();
      } else {
        showFraudWarningDialog();
      }
    });
  }

  void showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Payment Successful'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Your payment has been processed successfully.'),
              SizedBox(height: 16),
              Icon(
                Icons.payment,
                size: 48,
                color: Colors.green,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void showFraudWarningDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Fraud Warning'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This QR code has been flagged as potentially fraudulent. '
                'Please do not proceed with the payment.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Icon(
                Icons.security,
                size: 48,
                color: Colors.red,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                controller?.resumeCamera();
                isProcessing = false;
              },
              child: const Text('Try Another Code'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.blue,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: 300,
            ),
          ),
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Align QR code within the frame',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
