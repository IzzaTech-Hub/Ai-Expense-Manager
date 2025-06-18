import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/goal_model.dart';

class AddMoneyToGoalScreen extends StatefulWidget {
  final Goal goal;

  const AddMoneyToGoalScreen({super.key, required this.goal});

  @override
  State<AddMoneyToGoalScreen> createState() => _AddMoneyToGoalScreenState();
}

class _AddMoneyToGoalScreenState extends State<AddMoneyToGoalScreen> {
  final TextEditingController _amountController = TextEditingController();
  double _amount = 0.0;
  bool _isSaving = false;

  void _updateAmount(double value) {
    setState(() {
      _amount += value;
      _amountController.text = _amount.toStringAsFixed(0);
    });
  }

  void _submit() async {
    if (_amount <= 0) return;

    setState(() => _isSaving = true);

    try {
      // Simulate delay and update (replace with real DB logic)
      await Future.delayed(const Duration(seconds: 1));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Money added successfully!')),
      );

      Navigator.pop(context, _amount); // return to previous screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add money: ${e.toString()}')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = (widget.goal.currentAmount / widget.goal.targetAmount)
        .clamp(0, 1);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF6B7280),
          ), // dark gray
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Add Money to Goal',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827), // near black
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Goal Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.yellow.shade200),
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.track_changes,
                      color: Color(0xFF3B82F6),
                      size: 32,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.goal.title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Savings',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade300,
                  color: const Color(0xFF3B82F6),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'PKR ${widget.goal.currentAmount.toStringAsFixed(0)} / ${widget.goal.targetAmount.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Amount to Add Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.yellow.shade200),
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount to Add',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _amount = double.tryParse(value) ?? 0;
                    });
                  },
                  decoration: InputDecoration(
                    prefixText: 'PKR ',
                    hintText: '0.00',
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                // ... (button remains the same)
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isSaving
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : Text(
                              'Add PKR ${_amount.toStringAsFixed(0)} to Goal',
                              style: const TextStyle(color: Colors.white),
                            ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Quick Add Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.yellow.shade200),
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Add',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children:
                      [25, 50, 100, 250, 500, 1000].map((amount) {
                        return GestureDetector(
                          onTap: () => _updateAmount(amount.toDouble()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5), // grayish white
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'PKR $amount',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar (based on screenshot)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF3B82F6),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle, size: 32),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Budget',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
