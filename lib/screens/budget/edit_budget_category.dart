import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class _CategoryItem {
  final String name;
  final IconData icon;
  final Color color;
  _CategoryItem(this.name, this.icon, this.color);
}

class EditBudgetCategory extends StatefulWidget {
  final String categoryId;
  final String initialName;
  final double initialLimit;
  final double spentAmount; // For progress bar

  const EditBudgetCategory({
    super.key,
    required this.categoryId,
    required this.initialName,
    required this.initialLimit,
    required this.spentAmount,
    required Map<String, dynamic> category,
  });

  @override
  State<EditBudgetCategory> createState() => _EditBudgetCategoryState();
}

class _EditBudgetCategoryState extends State<EditBudgetCategory> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _allocatedController;

  bool _isSaving = false;
  bool _isDeleting = false;

  late String _selectedCategory;
  late int _selectedColor;
  final List<_CategoryItem> _categories = [
    _CategoryItem('Food & Dining', Icons.restaurant, Color(0xFFFF7043)),
    _CategoryItem('Transportation', Icons.directions_car, Color(0xFF42A5F5)),
    _CategoryItem('Entertainment', Icons.movie, Color(0xFFAB47BC)),
    _CategoryItem('Shopping', Icons.shopping_bag, Color(0xFF66BB6A)),
    _CategoryItem('Bills & Utilities', Icons.flash_on, Color(0xFFFFB300)),
    _CategoryItem('Healthcare', Icons.medical_services, Color(0xFFEC407A)),
    _CategoryItem('Education', Icons.school, Color(0xFF7E57C2)),
    _CategoryItem('Travel', Icons.flight, Color(0xFF29B6F6)),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _allocatedController = TextEditingController(
      text: widget.initialLimit.toStringAsFixed(0),
    );
    _selectedCategory = widget.initialName;
    final found = _categories.firstWhere((cat) => cat.name == widget.initialName, orElse: () => _categories[0]);
    _selectedColor = found.color.value;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _allocatedController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        await FirebaseFirestore.instance
            .collection('budgets')
            .doc(widget.categoryId)
            .update({
          'name': _selectedCategory,
          'allocated': double.tryParse(_allocatedController.text) ?? widget.initialLimit,
          'color': _selectedColor,
        });
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Budget category updated")));
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: \\${e.toString()}')),
        );
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  void _deleteCategory() async {
    setState(() => _isDeleting = true);
    try {
      await FirebaseFirestore.instance
          .collection('budgets')
          .doc(widget.categoryId)
          .delete();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Budget category deleted")));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: \\${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double spent = widget.spentAmount;
    final double limit =
        double.tryParse(_allocatedController.text) ?? widget.initialLimit;
    final double percentUsed = limit > 0 ? (spent / limit).clamp(0, 1) : 0;

    const blue = Color(0xFF3B82F6);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              // --- Custom AppBar ---
              Padding(
                padding: const EdgeInsets.only(
                  top: 12,
                  left: 8,
                  right: 8,
                  bottom: 0,
                ),
                child: SizedBox(
                  height: 54,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Centered icon and title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              color: blue,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.radio_button_checked,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Edit Budget',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: blue,
                            ),
                          ),
                        ],
                      ),
                      // Back button at left
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: blue),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- Category Name Card ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.07),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 18,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFFD0E5FC), // light blue
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.radio_button_checked,
                                color: blue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Category',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          items: _categories.map((cat) {
                            return DropdownMenuItem<String>(
                              value: cat.name,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: cat.color,
                                    radius: 12,
                                    child: Icon(cat.icon, color: Colors.white, size: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(cat.name),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCategory = val;
                                final found = _categories.firstWhere((cat) => cat.name == val);
                                _selectedColor = found.color.value;
                                _nameController.text = val;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Select a category' : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // --- Monthly Budget Amount Card ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.07),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 18,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFFD0E5FC), // light blue
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.attach_money,
                                color: blue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Allocated Amount',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _allocatedController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            prefixText: '	',
                            prefixStyle: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                            hintText: 'e.g. 800',
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Enter amount';
                            }
                            if (double.tryParse(val) == null) {
                              return 'Enter valid number';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Spent: PKR ${widget.spentAmount.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(fontSize: 13, color: Colors.red),
                            ),
                            Text(
                              'Remaining: PKR ${(double.tryParse(_allocatedController.text) ?? widget.initialLimit - widget.spentAmount).toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(fontSize: 13, color: Colors.green),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // --- Current Progress Card ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F0FA), // very light blue
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 18,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'Current Progress',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Spent: \$${spent.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: percentUsed,
                            minHeight: 10,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              blue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            '${(percentUsed * 100).toStringAsFixed(1)}% used',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // --- Save Changes Button (with blue gradient background) ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save, color: Colors.white),
                    label:
                        _isSaving
                            ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white, // white text
                              ),
                            ),
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white, // white text
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),

              // --- Delete Button (blue background, white text) ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label:
                      _isDeleting
                          ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            'Delete Budget Category',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white, // white text
                            ),
                          ),
                  onPressed: _isDeleting ? null : _deleteCategory,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white, // white text
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
