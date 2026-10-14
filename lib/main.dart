import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const OnSpeedPartnerApp());
}

const String firebaseUrl = "https://onspeed-logistics-default-rtdb.firebaseio.com";

class OnSpeedPartnerApp extends StatelessWidget {
  const OnSpeedPartnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OnSpeed Partner',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB), primary: const Color(0xFF2563EB)),
      ),
      home: const PartnerGate(),
    );
  }
}

class PartnerGate extends StatefulWidget {
  const PartnerGate({super.key});
  @override
  State<PartnerGate> createState() => _PartnerGateState();
}

class _PartnerGateState extends State<PartnerGate> {
  bool loggedIn = false;
  String phone = "";
  String vehicle = "";

  @override
  Widget build(BuildContext context) {
    if (!loggedIn) {
      return PartnerLogin(onDone: (p, v) => setState(() { phone = p; vehicle = v; loggedIn = true; }));
    }
    return PartnerDashboard(driverPhone: phone, vehicleNumber: vehicle);
  }
}

class PartnerLogin extends StatefulWidget {
  final Function(String, String) onDone;
  const PartnerLogin({super.key, required this.onDone});
  @override
  State<PartnerLogin> createState() => _PartnerLoginState();
}

class _PartnerLoginState extends State<PartnerLogin> {
  final vCtrl = TextEditingController(text: 'DL 1L AA 4821');
  final pCtrl = TextEditingController();
  final oCtrl = TextEditingController();
  bool otpSent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              const Icon(Icons.bolt, color: Colors.amberAccent, size: 44),
              const SizedBox(height: 16),
              const Text('OnSpeed Partner', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
              const Text('Driver Partner Delivery Dashboard', style: TextStyle(color: Colors.white60, fontSize: 13)),
              const SizedBox(height: 28),
              TextField(
                controller: vCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Vehicle Number', labelStyle: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(counterText: '', labelText: 'Mobile Number', labelStyle: TextStyle(color: Colors.white70)),
              ),
              if (otpSent) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: oCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.amber, letterSpacing: 6, fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(counterText: '', hintText: '1234', hintStyle: TextStyle(color: Colors.white24)),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent),
                  onPressed: () {
                    if (!otpSent) {
                      if (pCtrl.text.length == 10) setState(() => otpSent = true);
                    } else {
                      if (oCtrl.text == "1234") widget.onDone(pCtrl.text, vCtrl.text);
                    }
                  },
                  child: Text(otpSent ? 'Login to Partner' : 'Get OTP', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class PartnerDashboard extends StatefulWidget {
  final String driverPhone;
  final String vehicleNumber;
  const PartnerDashboard({super.key, required this.driverPhone, required this.vehicleNumber});
  @override
  State<PartnerDashboard> createState() => _PartnerDashboardState();
}

class _PartnerDashboardState extends State<PartnerDashboard> {
  bool dutyOn = true;
  Timer? pollTimer;
  Map<String, dynamic>? activeOrder;
  final otpInput = TextEditingController();

  @override
  void initState() {
    super.initState();
    pollTimer = Timer.periodic(const Duration(seconds: 2), (t) => listenOrders());
  }

  @override
  void dispose() {
    pollTimer?.cancel();
    super.dispose();
  }

  Future<void> listenOrders() async {
    if (!dutyOn) return;
    try {
      final res = await http.get(Uri.parse('$firebaseUrl/active_order.json'));
      if (res.body != "null" && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          activeOrder = data;
        });
      } else {
        if (mounted) setState(() => activeOrder = null);
      }
    } catch (_) {}
  }

  Future<void> acceptRide() async {
    await http.patch(
      Uri.parse('$firebaseUrl/active_order.json'),
      body: jsonEncode({
        "status": "ACCEPTED",
        "driverName": "Mukesh Partner",
        "driverPhone": widget.driverPhone,
        "driverVehicle": widget.vehicleNumber,
      }),
    );
    listenOrders();
  }

  Future<void> startRide() async {
    if (otpInput.text == (activeOrder?['otp'] ?? '4829')) {
      await http.patch(
        Uri.parse('$firebaseUrl/active_order.json'),
        body: jsonEncode({"status": "STARTED"}),
      );
      listenOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP')));
    }
  }

  Future<void> completeRide() async {
    await http.patch(
      Uri.parse('$firebaseUrl/active_order.json'),
      body: jsonEncode({"status": "COMPLETED"}),
    );
    listenOrders();
  }

  @override
  Widget build(BuildContext context) {
    final status = activeOrder?['status'] ?? 'NONE';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('ONSPEED PARTNER', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dutyOn ? 'DUTY ONLINE' : 'DUTY OFFLINE', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Switch(value: dutyOn, activeColor: Colors.green, onChanged: (v) => setState(() => dutyOn = v)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!dutyOn)
              const Expanded(child: Center(child: Text('Turn Duty ON to receive orders', style: TextStyle(color: Colors.white54))))
            else if (activeOrder == null || status == 'COMPLETED' || status == 'NONE')
              const Expanded(child: Center(child: Text('Waiting for Customer Orders...', style: TextStyle(color: Colors.white54))))
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Text('TRIP ALERT: ${activeOrder!['fare']} Cash', style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Pickup: ${activeOrder!['pickup']}\nDrop: ${activeOrder!['drop']}', style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 14),
                    if (status == 'SEARCHING')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent),
                        onPressed: acceptRide,
                        child: const Text('Accept Order', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      )
                    else if (status == 'ACCEPTED') ...[
                      TextField(
                        controller: otpInput,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        style: const TextStyle(color: Colors.white, letterSpacing: 4),
                        decoration: const InputDecoration(counterText: '', hintText: 'Enter Customer OTP', hintStyle: TextStyle(color: Colors.white30)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: startRide,
                        child: const Text('Verify OTP & Start Trip', style: TextStyle(color: Colors.white)),
                      )
                    ] else if (status == 'STARTED') ...[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                        onPressed: completeRide,
                        child: const Text('Complete Trip & Collect Cash', style: TextStyle(color: Colors.white)),
                      )
                    ]
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}
