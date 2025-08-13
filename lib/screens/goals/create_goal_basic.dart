import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/goal_service.dart';
import '../../services/auth_service.dart';
import '../../models/goal_model.dart';

class CreateGoalBasic extends StatefulWidget {
  const CreateGoalBasic({super.key});

  @override
  State<CreateGoalBasic> createState() => _CreateGoalBasicState();
}

class _CreateGoalBasicState extends State<CreateGoalBasic> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _targetAmountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedCategory;

  final List<String> categories = [
    'Emergency Fund',
    'Vacation',
    'Electronics',
    'Car',
    'Home',
    'Education',
    'Investment',
    'Other',
  ];

  final Color fieldColor = const Color(0xFFF5F7FA);
  final Color selectedCategoryColor = const Color(0xFF3B82F6);

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a target date")),
        );
        return;
      }
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a category")),
        );
        return;
      }

      final user = AuthService().currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in")),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final goal = Goal(
          id: '', // Firestore will generate the ID
          title: _titleController.text.trim(),
          targetAmount: double.parse(_targetAmountController.text.trim()),
          currentAmount: 0,
          deadline: _selectedDate!,
          category: _selectedCategory,
          color: selectedCategoryColor,
          userId: user.uid,
        );
        await GoalService().addGoal(goal);
        Navigator.of(context).pop(); // Remove loading
        Navigator.pop(context); // Go back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Goal created successfully!")),
        );
      } catch (e) {
        Navigator.of(context).pop(); // Remove loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to create goal: $e")),
        );
      }
    }
  }

  Widget buildField({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget buildLabeledField(String label, Widget child, double fontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: fontSize,
          ),
        ),
        const SizedBox(height: 8),
        buildField(child: child),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final fontSize = width * 0.035;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
        title: Text(
          'Create New Goal',
          style: GoogleFonts.poppins(
            fontSize: width * 0.045,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              buildLabeledField(
                'Goal Title',
                TextFormField(
                  controller: _titleController,
                  style: GoogleFonts.poppins(fontSize: fontSize),
                  decoration: InputDecoration(
                    hintText: 'e.g., Emergency Fund, Dream Vacation',
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontSize: fontSize * 0.95),
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Enter a goal title'
                              : null,
                ),
                fontSize,
              ),
              buildLabeledField(
                'Target Amount',
                TextFormField(
                  controller: _targetAmountController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(fontSize: fontSize),
                  decoration: InputDecoration(
                    prefixText: '₨ ',
                    hintText: '0.00',
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontSize: fontSize * 0.95),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Enter target amount';
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0)
                      return 'Enter a valid amount > 0';
                    return null;
                  },
                ),
                fontSize,
              ),
              buildLabeledField(
                'Target Date',
                GestureDetector(
                  onTap: _pickDate,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate != null
                            ? DateFormat.yMMMd().format(_selectedDate!)
                            : 'mm/dd/yyyy',
                        style: GoogleFonts.poppins(
                          color:
                              _selectedDate != null
                                  ? Colors.black
                                  : Colors.grey,
                          fontSize: fontSize,
                        ),
                      ),
                      const Icon(Icons.calendar_today, size: 20),
                    ],
                  ),
                ),
                fontSize,
              ),
              const SizedBox(height: 8),
              Text(
                'Category',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: fontSize,
                ),
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: (width / 2 - 32) / 50,
                children:
                    categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color:
                                isSelected ? selectedCategoryColor : fieldColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            category,
                            style: GoogleFonts.poppins(
                              fontSize: fontSize,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 24),
              buildLabeledField(
                'Description',
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  style: GoogleFonts.poppins(fontSize: fontSize),
                  decoration: InputDecoration(
                    hintText: 'Add some details about your goal...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontSize: fontSize * 0.95),
                  ),
                ),
                fontSize,
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.2,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Create Goal',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
              Navigator.pushNamed(context, '/profile');
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
            icon: Icon(Icons.add_circle_outline),
            label: 'Add',
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
