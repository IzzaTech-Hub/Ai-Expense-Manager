import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/budget_model.dart';
import '../../services/auth_service.dart';

class AddBudgetCategory extends StatefulWidget {
  const AddBudgetCategory({super.key});

  @override
  State<AddBudgetCategory> createState() => _AddBudgetCategoryState();
}

class _AddBudgetCategoryState extends State<AddBudgetCategory> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _limitController = TextEditingController();

  bool _isSaving = false;
  String? _selectedCategory;

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

  final AuthService _authService = AuthService();

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      try {
        final user = _authService.currentUser;
        if (user == null) {
          throw Exception('User not logged in');
        }
        final String categoryName = _selectedCategory!;
        final double limit = double.tryParse(_limitController.text) ?? 0.0;
        final int color = _categories.firstWhere((cat) => cat.name == _selectedCategory!).color.value;
        final newCategory = BudgetCategory(
          id: '', // Firestore will auto-generate
          name: categoryName,
          allocated: limit,
          spent: 0.0,
          userId: user.uid,
          color: color,
          createdAt: DateTime.now(),
        );
        await FirebaseFirestore.instance.collection('budgets').add(newCategory.toJson());
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Budget category added")));
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add category: \\${e.toString()}')),
        );
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color fieldColor = Color(0xFFDCDCD8);
    
    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;
    
    // Responsive values
    final titleFontSize = isLargeScreen ? 24.0 : (isTablet ? 22.0 : 20.0);
    final subtitleFontSize = isLargeScreen ? 16.0 : (isTablet ? 15.0 : 14.0);
    final bodyFontSize = isLargeScreen ? 15.0 : (isTablet ? 14.0 : 13.0);
    final smallFontSize = isLargeScreen ? 13.0 : (isTablet ? 12.0 : 11.0);
    
    final horizontalPadding = isLargeScreen ? 32.0 : (isTablet ? 24.0 : 16.0);
    final verticalSpacing = isLargeScreen ? 32.0 : (isTablet ? 28.0 : 24.0);
    final smallSpacing = isLargeScreen ? 16.0 : (isTablet ? 14.0 : 12.0);
    
    // Responsive grid
    final crossAxisCount = isLargeScreen ? 3 : (isTablet ? 2 : 2);
    final childAspectRatio = isLargeScreen ? 4.0 : (isTablet ? 3.7 : 3.5);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.only(bottom: isLargeScreen ? 60.0 : 40.0),
            children: [
              // --- Responsive Header with Back Button and Title ---
              Padding(
                padding: EdgeInsets.only(
                  top: isLargeScreen ? 24.0 : 16.0,
                  left: horizontalPadding * 0.5,
                  right: horizontalPadding * 0.5,
                  bottom: 0,
                ),
                child: SizedBox(
                  height: isLargeScreen ? 56.0 : 48.0,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Centered title
                      Text(
                        'Create Budget',
                        style: GoogleFonts.poppins(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7C3AED),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      // Back button at left
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: Color(0xFF7C3AED),
                            size: isLargeScreen ? 28.0 : 24.0,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // "Start Your Budget Journey" Card
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: smallSpacing,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7FE),
                    borderRadius: BorderRadius.circular(isLargeScreen ? 20.0 : 18.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.07),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: isLargeScreen ? 36.0 : 28.0,
                      horizontal: isLargeScreen ? 24.0 : 16.0,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Start Your Budget Journey',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: titleFontSize,
                            color: const Color(0xFF111827),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isLargeScreen ? 12.0 : 8.0),
                        Text(
                          'Choose a category below or create your own to begin tracking your expenses',
                          style: GoogleFonts.poppins(
                            fontSize: subtitleFontSize,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: verticalSpacing),

              // Popular Categories Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Text(
                  'Popular Categories',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: bodyFontSize,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(height: smallSpacing),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  crossAxisSpacing: isLargeScreen ? 20.0 : 14.0,
                  mainAxisSpacing: isLargeScreen ? 20.0 : 14.0,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: childAspectRatio,
                  children: _categories.map((cat) {
                    final bool selected = _selectedCategory == cat.name;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat.name;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected
                              ? cat.color.withOpacity(0.15)
                              : Colors.white,
                          border: Border.all(
                            color: selected ? cat.color : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(isLargeScreen ? 16.0 : 12.0),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: isLargeScreen ? 12.0 : 8.0,
                          horizontal: isLargeScreen ? 16.0 : 10.0,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: cat.color,
                              radius: isLargeScreen ? 20.0 : 16.0,
                              child: Icon(
                                cat.icon,
                                color: Colors.white,
                                size: isLargeScreen ? 22.0 : 18.0,
                              ),
                            ),
                            SizedBox(width: isLargeScreen ? 14.0 : 10.0),
                            Expanded(
                              child: Text(
                                cat.name,
                                style: GoogleFonts.poppins(
                                  fontSize: bodyFontSize,
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
              ),

              SizedBox(height: verticalSpacing),

              // Monthly Budget Amount Input
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Text(
                  'Monthly Budget Amount',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: bodyFontSize,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(height: smallSpacing),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: TextFormField(
                  controller: _limitController,
                  keyboardType: TextInputType.number,
                  decoration: _fieldDecoration('e.g. 0.00', isLargeScreen),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter amount';
                    if (double.tryParse(val) == null) {
                      return 'Enter valid number';
                    }
                    return null;
                  },
                ),
              ),

              SizedBox(height: verticalSpacing),

              // Premium Features Banner
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isLargeScreen ? 24.0 : 18.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E6),
                    borderRadius: BorderRadius.circular(isLargeScreen ? 18.0 : 14.0),
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFC107),
                          shape: BoxShape.circle,
                        ),
                        padding: EdgeInsets.all(isLargeScreen ? 14.0 : 10.0),
                        child: Icon(
                          Icons.trending_up,
                          color: Colors.white,
                          size: isLargeScreen ? 28.0 : 24.0,
                        ),
                      ),
                      SizedBox(width: isLargeScreen ? 20.0 : 16.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Unlock Premium Features',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: bodyFontSize,
                                color: Colors.brown,
                              ),
                            ),
                            SizedBox(height: isLargeScreen ? 4.0 : 2.0),
                            Text(
                              'Get custom colors, priority levels, AI budget optimization, and advanced analytics to maximize your savings!',
                              style: GoogleFonts.poppins(
                                fontSize: smallFontSize,
                                color: Colors.brown,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: isLargeScreen ? 16.0 : 10.0),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Handle upgrade action
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC107),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isLargeScreen ? 18.0 : 14.0,
                            vertical: isLargeScreen ? 12.0 : 8.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(isLargeScreen ? 10.0 : 8.0),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Upgrade to Premium',
                          style: TextStyle(fontSize: smallFontSize),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: isLargeScreen ? 36.0 : 28.0),

              // Save and Cancel Buttons
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          padding: EdgeInsets.symmetric(
                            vertical: isLargeScreen ? 18.0 : 14.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(isLargeScreen ? 14.0 : 12.0),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                'Save',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: bodyFontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(width: isLargeScreen ? 20.0 : 16.0),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: fieldColor,
                          padding: EdgeInsets.symmetric(
                            vertical: isLargeScreen ? 18.0 : 14.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(isLargeScreen ? 14.0 : 12.0),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: bodyFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isLargeScreen ? 32.0 : 20.0),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint, bool isLargeScreen) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFDCDCD8),
      contentPadding: EdgeInsets.symmetric(
        horizontal: isLargeScreen ? 20.0 : 16.0,
        vertical: isLargeScreen ? 18.0 : 14.0,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isLargeScreen ? 14.0 : 12.0),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _CategoryItem {
  final String name;
  final IconData icon;
  final Color color;

  _CategoryItem(this.name, this.icon, this.color);
}
