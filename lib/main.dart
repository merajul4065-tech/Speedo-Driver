import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const OnSpeedDriverApp());
}

const String firebaseUrl = "https://onspeed-logistics-default-rtdb.firebaseio.com";

class OnSpeedDriverApp extends StatelessWidget {
  const OnSpeedDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OnSpeed Partner',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          primary: const Color(0xFF0F172A),
        ),
      ),
      home: const DriverDashboardScreen(),
    );
  }
}

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  // Driver Profile info exactly styled like Porter
  String driverName = "Merajul Alam";
  String driverRating = "4.8";
  String vehicleType = "2 Wheeler";
  String vehicleNumber = "HR-98-U-6634";
  String driverPhone = "8984216008";

  bool isOnline = true;
  double todayEarning = 0.0;
  double walletBalance = 0.0;

  Timer? syncTimer;
  Map<String, dynamic>? liveOrder;
  final otpInputCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    checkIncomingRides();
    syncTimer = Timer.periodic(const Duration(seconds: 2), (t) => checkIncomingRides());
  }

  @override
  void dispose() {
    syncTimer?.cancel();
    super.dispose();
  }

  Future<void> checkIncomingRides() async {
    if (!isOnline) return;
    try {
      final res = await http.get(Uri.parse('$firebaseUrl/active_order.json'));
      if (res.body != "null" && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          liveOrder = data;
        });
      } else {
        if (mounted) setState(() => liveOrder = null);
      }
    } catch (_) {}
  }

  Future<void> acceptCurrentOrder() async {
    if (liveOrder == null) return;
    try {
      await http.patch(
        Uri.parse('$firebaseUrl/active_order.json'),
        body: jsonEncode({
          "status": "ACCEPTED",
          "driverName": driverName,
          "driverPhone": driverPhone,
          "driverVehicle": vehicleNumber,
        }),
      );
      checkIncomingRides();
    } catch (_) {}
  }

  Future<void> verifyOtpAndStart() async {
    if (liveOrder == null) return;
    if (otpInputCtrl.text.trim() == (liveOrder!['otp'] ?? '')) {
      await http.patch(
        Uri.parse('$firebaseUrl/active_order.json'),
        body: jsonEncode({"status": "STARTED"}),
      );
      otpInputCtrl.clear();
      checkIncomingRides();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Galat OTP! Customer se sahi 4-digit OTP lein')),
      );
    }
  }

  Future<void> completeRideAndCollect() async {
    if (liveOrder == null) return;
    final fareStr = (liveOrder!['fare'] ?? '₹0').toString().replaceAll('₹', '').trim();
    final fareVal = double.tryParse(fareStr) ?? 0.0;

    await http.patch(
      Uri.parse('$firebaseUrl/active_order.json'),
      body: jsonEncode({"status": "COMPLETED"}),
    );

    setState(() {
      todayEarning += fareVal;
      walletBalance += fareVal;
    });

    checkIncomingRides();
  }

  @override
  Widget build(BuildContext context) {
    final status = liveOrder?['status'] ?? 'NONE';
    final hasActiveTrip = liveOrder != null && (status == 'SEARCHING' || status == 'ACCEPTED' || status == 'STARTED');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ================= 1. PORTER HEADER =================
            Container(
              color: const Color(0xFF1E293B),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.menu, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  // Logo
                  Row(
                    children: const [
                      Text('ON', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                      Text('SPEED', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w900, fontSize: 20)),
                    ],
                  ),
                  const Spacer(),
                  // Top action icons
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF334155)),
                    child: const Icon(Icons.notifications_active_outlined, color: Colors.redAccent, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF334155)),
                    child: const Icon(Icons.headset_mic_outlined, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),

            // ================= 2. DRIVER PROFILE BAR =================
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Stack(
                    children: [
                      const CircleAvatar(
                        radius: 26,
                        backgroundColor: Color(0xFFE2E8F0),
                        child: Icon(Icons.person, size: 36, color: Color(0xFF64748B)),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: isOnline ? const Color(0xFF16A34A) : Colors.grey,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(driverName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                            const SizedBox(width: 8),
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            Text(' $driverRating', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('$vehicleType • $vehicleNumber', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('VIEW PROFILE', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
                  )
                ],
              ),
            ),

            // Online status indicator line
            Container(
              height: 4,
              color: isOnline ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
            ),

            // ================= 3. SCROLLABLE DASHBOARD =================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Today's Earning
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Today's Earning", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          Row(
                            children: [
                              Text('₹${todayEarning.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Porter Style Dark Wallet Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('₹${walletBalance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 4),
                              const Text('Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: Color(0xFF1E293B), shape: BoxShape.circle),
                            child: const Icon(Icons.chevron_right, color: Colors.white),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Incentives banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: const Text('Check the details of your incentives here!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEFF6FF),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            onPressed: () {},
                            child: const Text('Read more', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Documents verified status
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified, color: Color(0xFF16A34A), size: 28),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Documents Verified', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('Active Delivery Partner Account', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                            ],
                          )
                        ],
                      ),
                    ),

                    // ================= 4. LIVE TRIP CARD (POPUP) =================
                    if (hasActiveTrip) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF2563EB), width: 2),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 6))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                                  child: Text('NEW ORDER: ${liveOrder!['fare']}', style: const TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.w900, fontSize: 14)),
                                ),
                                Text(status, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.radio_button_checked, size: 16, color: Color(0xFF16A34A)),
                                const SizedBox(width: 8),
                                Expanded(child: Text('Pickup: ${liveOrder!['pickup']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on, size: 18, color: Color(0xFFDC2626)),
                                const SizedBox(width: 8),
                                Expanded(child: Text('Drop: ${liveOrder!['drop']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Customer: ${liveOrder!['customerName']} (+91 ${liveOrder!['customerPhone']})', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            const SizedBox(height: 16),

                            if (status == 'SEARCHING') ...[
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  onPressed: acceptCurrentOrder,
                                  child: const Text('ACCEPT ORDER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                ),
                              )
                            ] else if (status == 'ACCEPTED') ...[
                              TextField(
                                controller: otpInputCtrl,
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 6),
                                decoration: InputDecoration(
                                  labelText: 'Enter Customer OTP',
                                  counterText: '',
                                  filled: true,
                                  fillColor: const Color(0xFFF1F5F9),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  onPressed: verifyOtpAndStart,
                                  child: const Text('VERIFY OTP & START TRIP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              )
                            ] else if (status == 'STARTED') ...[
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  onPressed: completeRideAndCollect,
                                  child: const Text('COMPLETE TRIP & COLLECT CASH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              )
                            ]
                          ],
                        ),
                      )
                    ]
                  ],
                ),
              ),
            ),

            // ================= 5. PORTER BOTTOM SLIDER BUTTON =================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: Colors.white,
              child: GestureDetector(
                onTap: () => setState(() => isOnline = !isOnline),
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: isOnline ? const Color(0xFFDC2626) : const Color(0xFF16A34A), width: 2),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isOnline ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isOnline ? Icons.power_settings_new : Icons.play_arrow,
                          color: Colors.white,
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            isOnline ? 'GO OFFLINE' : 'GO ONLINE',
                            style: TextStyle(
                              color: isOnline ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
