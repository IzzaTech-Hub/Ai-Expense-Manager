import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../models/budget_model.dart';
import '../../services/database_service.dart';

class AddBudgetCategory extends StatefulWidget {
  const AddBudgetCategory({super.key});

  @override
  State<AddBudgetCategory> createState() => _AddBudgetCategoryState();
}

class _AddBudgetCategoryState extends State<AddBudgetCategory> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _limitController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  final _uuid = Uuid();

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

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      try {
        final String categoryName = _selectedCategory!;
        final double limit = double.tryParse(_limitController.text) ?? 0.0;
        final int color = _categories.firstWhere((cat) => cat.name == _selectedCategory!).color.value;
        
        final newCategory = BudgetCategory(
          id: _uuid.v4(),
          name: categoryName,
          allocated: limit,
          spent: 0.0,
          userId: 'default_user',
          color: color,
          createdAt: DateTime.now(),
        );
        
        await _databaseService.insertBudgetCategory(newCategory);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Budget category added successfully")),
        );
        Navigator.pop(context, true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add category: ${e.toString()}')),
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
    final isSmallScreen = screenHeight < 700; // Check for small height screens
    
    // Responsive values - more conservative for small screens
    final titleFontSize = isSmallScreen ? 18.0 : (isLargeScreen ? 24.0 : (isTablet ? 22.0 : 20.0));
    final subtitleFontSize = isSmallScreen ? 14.0 : (isLargeScreen ? 16.0 : (isTablet ? 15.0 : 14.0));
    final bodyFontSize = isSmallScreen ? 13.0 : (isLargeScreen ? 15.0 : (isTablet ? 14.0 : 13.0));
    final smallFontSize = isSmallScreen ? 11.0 : (isLargeScreen ? 13.0 : (isTablet ? 12.0 : 11.0));
    
    final horizontalPadding = isLargeScreen ? 32.0 : (isTablet ? 24.0 : 16.0);
    final verticalSpacing = isSmallScreen ? 16.0 : (isLargeScreen ? 32.0 : (isTablet ? 28.0 : 24.0));
    final smallSpacing = isSmallScreen ? 8.0 : (isLargeScreen ? 16.0 : (isTablet ? 14.0 : 12.0));
    
    // Responsive grid - more conservative for small screens
    final crossAxisCount = isSmallScreen ? 2 : (isLargeScreen ? 3 : (isTablet ? 2 : 2));
    final childAspectRatio = isSmallScreen ? 3.0 : (isLargeScreen ? 4.0 : (isTablet ? 3.7 : 3.5));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header - Fixed height to prevent overflow
              Container(
                height: isSmallScreen ? 60 : 80,
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: isSmallScreen ? 12 : 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                    Expanded(
                      child: Text(
                        'Add Budget Category',
                        style: GoogleFonts.poppins(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 40 : 48), // Balance the back button
                  ],
                ),
              ),

              // Content - Flexible and scrollable
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category section
                      Text(
                        'Choose a category',
                        style: GoogleFonts.poppins(
                          fontSize: subtitleFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: smallSpacing),
                      Text(
                        'Select a category that best describes your budget',
                        style: GoogleFonts.poppins(
                          fontSize: bodyFontSize,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? smallSpacing : verticalSpacing),

                      // Category Grid - Responsive and flexible
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Calculate grid dimensions based on available space
                          final availableWidth = constraints.maxWidth;
                          final itemWidth = (availableWidth - (smallSpacing * (crossAxisCount - 1))) / crossAxisCount;
                          final itemHeight = itemWidth * (isSmallScreen ? 0.8 : 1.0);
                          
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: smallSpacing,
                              mainAxisSpacing: smallSpacing,
                              childAspectRatio: itemWidth / itemHeight,
                            ),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              final isSelected = _selectedCategory == category.name;
                              
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = category.name;
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected ? category.color.withOpacity(0.1) : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? category.color : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        category.icon,
                                        color: isSelected ? category.color : Colors.grey[600],
                                        size: isSmallScreen ? 24 : (isLargeScreen ? 32 : 28),
                                      ),
                                      SizedBox(height: isSmallScreen ? 4 : smallSpacing / 2),
                                      Flexible(
                                        child: Text(
                                          category.name,
                                          style: GoogleFonts.poppins(
                                            fontSize: isSmallScreen ? 10 : smallFontSize,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                            color: isSelected ? category.color : Colors.black87,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),

                      SizedBox(height: isSmallScreen ? smallSpacing : verticalSpacing),

                      // Budget Limit Input
                      Text(
                        'Set budget limit',
                        style: GoogleFonts.poppins(
                          fontSize: subtitleFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: smallSpacing),
                      Text(
                        'Enter the maximum amount you want to spend on this category',
                        style: GoogleFonts.poppins(
                          fontSize: bodyFontSize,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? smallSpacing : verticalSpacing),

                      TextFormField(
                        controller: _limitController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Enter amount (e.g., 5000)',
                          prefixText: '\$ ',
                          filled: true,
                          fillColor: fieldColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a budget limit';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: isSmallScreen ? smallSpacing : verticalSpacing),
                    ],
                  ),
                ),
              ),

              // Bottom Button - Fixed height to prevent overflow
              Container(
                height: isSmallScreen ? 70 : 80,
                padding: EdgeInsets.all(horizontalPadding),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selectedCategory == null || _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Create Budget Category',
                            style: GoogleFonts.poppins(
                              fontSize: bodyFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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

class _CategoryItem {
  final String name;
  final IconData icon;
  final Color color;

  _CategoryItem(this.name, this.icon, this.color);
}
