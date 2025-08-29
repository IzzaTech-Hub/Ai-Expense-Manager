import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/goal_model.dart';
import '../../services/database_service.dart';

class AddMoneyToGoalScreen extends StatefulWidget {
  final Goal goal;

  const AddMoneyToGoalScreen({super.key, required this.goal});

  @override
  State<AddMoneyToGoalScreen> createState() => _AddMoneyToGoalScreenState();
}

class _AddMoneyToGoalScreenState extends State<AddMoneyToGoalScreen> {
  final TextEditingController _amountController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
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
      final newCurrentAmount = widget.goal.currentAmount + _amount;
      final updatedGoal = Goal(
        id: widget.goal.id,
        title: widget.goal.title,
        targetAmount: widget.goal.targetAmount,
        currentAmount: newCurrentAmount,
        deadline: widget.goal.deadline,
        category: widget.goal.category,
        color: widget.goal.color,
        userId: widget.goal.userId,
      );
      
      await _databaseService.updateGoal(updatedGoal);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Money added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, _amount);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add money: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final fontSize = size.width * 0.038;
    final titleSize = size.width * 0.045;

    double progress = (widget.goal.currentAmount / widget.goal.targetAmount)
        .clamp(0, 1);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6B7280)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Add Money to Goal',
          style: GoogleFonts.poppins(
            fontSize: titleSize,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
          // Goal Card
          _cardWrapper(
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
                          fontSize: fontSize + 2,
                        ),
                      ),
                      Text(
                        widget.goal.category ?? 'Savings',
                        style: GoogleFonts.poppins(fontSize: fontSize - 1),
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
                  '\$${widget.goal.currentAmount.toStringAsFixed(0)} / \$${widget.goal.targetAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(fontSize: fontSize),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Amount to Add Section
          _cardWrapper(
            children: [
              Text(
                'Amount to Add',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: fontSize + 2,
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
                style: GoogleFonts.poppins(fontSize: fontSize),
                decoration: InputDecoration(
                                      prefixText: '\$ ',
                  hintText: '0.00',
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
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
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                            'Add \$${_amount.toStringAsFixed(0)} to Goal',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: fontSize,
                            ),
                          ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Quick Add Section
          _cardWrapper(
            children: [
              Text(
                'Quick Add',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize + 1,
                ),
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
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.05,
                            vertical: size.height * 0.015,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '\$$amount',
                            style: GoogleFonts.poppins(
                              fontSize: fontSize,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        ],
        ),
      ),

      // ✅ Dashboard-consistent bottom nav bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF3B82F6),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/dashboard');
              break;
            case 1:
              Navigator.pushNamed(context, '/analytics');
              break;
            case 2:
              Navigator.pushNamed(context, '/add');
              break;
            case 3:
              Navigator.pushNamed(context, '/budget');
              break;
            case 4:
              Navigator.pushNamed(context, '/goals');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle, size: 36, color: Color(0xFF3B82F6)),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Budget',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Goals'),
        ],
      ),
    );
  }

  Widget _cardWrapper({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.yellow.shade200),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
