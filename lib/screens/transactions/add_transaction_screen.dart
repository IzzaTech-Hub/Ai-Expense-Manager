import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart'; // adjust path as needed
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/app_bottom_nav_bar.dart';

class _CategoryItem {
  final String name;
  final IconData icon;
  final Color color;
  _CategoryItem(this.name, this.icon, this.color);
}

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _transactionType = 'Expense'; // default
  String? _selectedCategory;

  final Map<String, List<String>> _categoryOptions = {
    'Income': ['Salary', 'Freelance', 'Investment', 'Gift', 'Other'],
  };

  final List<_CategoryItem> _expenseCategories = [
    _CategoryItem('Food & Dining', Icons.restaurant, Color(0xFFFF7043)),
    _CategoryItem('Transportation', Icons.directions_car, Color(0xFF42A5F5)),
    _CategoryItem('Entertainment', Icons.movie, Color(0xFFAB47BC)),
    _CategoryItem('Shopping', Icons.shopping_bag, Color(0xFF66BB6A)),
    _CategoryItem('Bills & Utilities', Icons.flash_on, Color(0xFFFFB300)),
    _CategoryItem('Healthcare', Icons.medical_services, Color(0xFFEC407A)),
    _CategoryItem('Education', Icons.school, Color(0xFF7E57C2)),
    _CategoryItem('Travel', Icons.flight, Color(0xFF29B6F6)),
  ];

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2022),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a category")),
        );
        return;
      }

      final double amount = double.tryParse(_amountController.text) ?? 0.0;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in")),
        );
        return;
      }

      if (_transactionType == 'Expense') {
        final budgetQuery = await FirebaseFirestore.instance
            .collection('budgets')
            .where('userId', isEqualTo: user.uid)
            .where('name', isEqualTo: _selectedCategory)
            .limit(1)
            .get();

        if (budgetQuery.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("There is no budget for this category.")),
          );
          return;
        }

        final budgetDoc = budgetQuery.docs.first;
        final currentSpent = (budgetDoc['spent'] ?? 0).toDouble();
        final newSpent = currentSpent + amount;

        await budgetDoc.reference.update({'spent': newSpent});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Expense added and budget updated.")),
        );
        Navigator.pop(context);
      } else {
        // Add income transaction to Firestore
        await FirebaseFirestore.instance.collection('transactions').add({
          'userId': user.uid,
          'type': 'income',
          'amount': amount,
          'category': _selectedCategory,
          'note': _noteController.text,
          'date': Timestamp.fromDate(_selectedDate),
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Income added.")),
        );
        Navigator.pop(context);
      }
    }
  }

  void _deleteIncomeCategory(BuildContext context, String category) async {
    final user = AuthService().currentUser;
    if (user == null) return;
    final query = await FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: user.uid)
        .where('type', isEqualTo: 'income')
        .where('category', isEqualTo: category)
        .get();
    for (var doc in query.docs) {
      await doc.reference.delete();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All income transactions for $category deleted.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const fieldColor = Color.fromARGB(255, 220, 220, 216);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black),
        centerTitle: true,
        title: Text(
          'Add Transaction',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Toggle Button
              Container(
                padding: const EdgeInsets.all(6),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.yellow.shade300),
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    _buildToggleButton(
                      'Expense',
                      _transactionType == 'Expense',
                      color: Colors.red,
                    ),
                    _buildToggleButton(
                      'Income',
                      _transactionType == 'Income',
                      color: Colors.green,
                    ),
                  ],
                ),
              ),

              _buildLabel('Amount'),
              _buildAmountField(fieldColor),
              const SizedBox(height: 20),

              _buildLabel('Description'),
              _buildNoteField(fieldColor),
              const SizedBox(height: 20),

              _buildLabel('Category'),
              _buildCategoryPicker(),
              const SizedBox(height: 20),

              _buildLabel('Date'),
              _buildDatePicker(fieldColor),
              const SizedBox(height: 30),

              // Add Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _transactionType == 'Expense'
                            ? Colors.red
                            : Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    _transactionType == 'Expense'
                        ? 'Add Expense'
                        : 'Add Income',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      // Bottom Nav
      bottomNavigationBar: AppBottomNavBar(currentIndex: 2),
    );
  }

  // WIDGETS

  Widget _buildToggleButton(
    String label,
    bool selected, {
    required Color color,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _transactionType = label;
            _selectedCategory = null; // Reset selected category
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildAmountField(Color fieldColor) {
    return Container(
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.yellow.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text('\$', style: TextStyle(color: Colors.black54)),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '0.00',
                border: InputBorder.none,
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Enter amount';
                if (double.tryParse(val) == null) return 'Enter valid number';
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteField(Color fieldColor) {
    return TextFormField(
      controller: _noteController,
      decoration: InputDecoration(
        hintText: 'What was this for?',
        filled: true,
        fillColor: fieldColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildCategoryPicker() {
    if (_transactionType == 'Expense') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 3.7,
          children: _expenseCategories.map((cat) {
            final bool selected = _selectedCategory == cat.name;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat.name),
              child: Container(
                decoration: BoxDecoration(
                  color: selected ? cat.color.withOpacity(0.15) : Colors.white,
                  border: Border.all(
                    color: selected ? cat.color : Colors.transparent,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 10,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: cat.color,
                      radius: 16,
                      child: Icon(
                        cat.icon,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        cat.name,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      );
    } else {
      final categories = _categoryOptions[_transactionType]!;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.yellow.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isSelected ? Colors.green.shade100 : Colors.grey.shade100,
                ),
                child: Text(cat),
              ),
            );
          }).toList(),
        ),
      );
    }
  }

  Widget _buildDatePicker(Color fieldColor) {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: fieldColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.yellow.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat('MM/dd/yyyy').format(_selectedDate)),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }
}
