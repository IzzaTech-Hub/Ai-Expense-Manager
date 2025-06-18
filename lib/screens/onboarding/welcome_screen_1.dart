import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen1 extends StatelessWidget {
  const WelcomeScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Box
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.show_chart,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Track Your Expenses',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Monitor your spending habits with detailed analytics and insights.',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _dot(active: true),
                  const SizedBox(width: 6),
                  _dot(),
                  const SizedBox(width: 6),
                  _dot(),
                  const SizedBox(width: 6),
                  _dot(),
                ],
              ),

              const SizedBox(height: 20),

              // Next Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/welcome2');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 4,
                    shadowColor: Colors.black26,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Next',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot({bool active = false}) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF3B82F6) : Colors.black12,
        shape: BoxShape.circle,
      ),
    );
  }
}
