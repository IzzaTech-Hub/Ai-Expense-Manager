import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class AISpeedDial extends StatefulWidget {
  const AISpeedDial({super.key});

  @override
  State<AISpeedDial> createState() => _AISpeedDialState();
}

class _AISpeedDialState extends State<AISpeedDial>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
    });

    if (_isOpen) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // AI Assistant Options
        if (_isOpen) ...[
          _buildSpeedDialItem(
            icon: Icons.analytics,
            label: 'Financial Analysis',
            onTap: () => _navigateToAI(context, 'financial_analysis'),
            delay: 0,
          ),
          _buildSpeedDialItem(
            icon: Icons.savings,
            label: 'Budget Advice',
            onTap: () => _navigateToAI(context, 'budget_advice'),
            delay: 1,
          ),
          _buildSpeedDialItem(
            icon: Icons.trending_up,
            label: 'Investment Tips',
            onTap: () => _navigateToAI(context, 'investment_tips'),
            delay: 2,
          ),
          _buildSpeedDialItem(
            icon: Icons.receipt_long,
            label: 'Expense Tracking',
            onTap: () => _navigateToAI(context, 'expense_tracking'),
            delay: 3,
          ),
          const SizedBox(height: 16),
        ],
        
        // Main AI Button
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: const Color(0xFF8B5CF6),
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 300),
            child: const Icon(
              Icons.psychology,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedDialItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required int delay,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final offset = (1.0 - _animation.value) * 50.0;
        final opacity = _animation.value;
        
        return Transform.translate(
          offset: Offset(0, offset),
          child: Opacity(
            opacity: opacity,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Label
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Icon Button
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToAI(BuildContext context, String intent) {
    Navigator.pushNamed(
      context,
      AppRoutes.aiAssistant,
      arguments: {'intent': intent},
    );
  }
}
