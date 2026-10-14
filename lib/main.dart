import 'package:flutter/material.dart';

void main() {
  runApp(const OnSpeedPartnerApp());
}

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

  @override
  Widget build(BuildContext context) {
    if (!loggedIn) {
      return PartnerLogin(onDone: (p) => setState(() { phone = p; loggedIn = true; }));
    }
    return PartnerDashboard(driverPhone: phone);
  }
}

class PartnerLogin extends StatefulWidget {
  final Function(String) onDone;
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
                      if (oCtrl.text == "1234") widget.onDone(pCtrl.text);
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
  const PartnerDashboard({super.key, required this.driverPhone});
  @override
  State<PartnerDashboard> createState() => _PartnerDashboardState();
}

class _PartnerDashboardState extends State<PartnerDashboard> {
  bool dutyOn = true;
  bool hasRide = false;
  bool rideStarted = false;
  final otpInput = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
              const Expanded(child: Center(child: Text('Turn Duty ON', style: TextStyle(color: Colors.white54))))
            else if (!hasRide)
              Expanded(
                child: Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                    onPressed: () => setState(() => hasRide = true),
                    child: const Text('Simulate Customer Order', style: TextStyle(color: Colors.white)),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    const Text('TRIP ALERT: ₹290 Cash', style: TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Pickup: Connaught Place\nDrop: Sector 62, Noida', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 14),
                    if (!rideStarted) ...[
                      TextField(
                        controller: otpInput,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        style: const TextStyle(color: Colors.white, letterSpacing: 4),
                        decoration: const InputDecoration(counterText: '', hintText: 'Enter 4829', hintStyle: TextStyle(color: Colors.white30)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: () {
                          if (otpInput.text == "4829") setState(() => rideStarted = true);
                        },
                        child: const Text('Start Trip', style: TextStyle(color: Colors.white)),
                      )
                    ] else ...[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                        onPressed: () => setState(() { hasRide = false; rideStarted = false; otpInput.clear(); }),
                        child: const Text('Complete Trip', style: TextStyle(color: Colors.white)),
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
