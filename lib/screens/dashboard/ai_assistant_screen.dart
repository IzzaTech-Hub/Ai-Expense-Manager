import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/ai_service.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  late final AIService _aiService;

  @override
  void initState() {
    super.initState();
    _aiService = AIService();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final userText = _controller.text.trim();
    if (userText.isEmpty || _isSending) return;
    setState(() { _isSending = true; });
    _controller.clear();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _appendAssistant('Please sign in to use AI assistant.');
        return;
      }

      final messagesCol = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('ai_messages');

      // Persist user message
      await messagesCol.add({
        'role': 'user',
        'text': userText,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final json = await _aiService.parseIntent(userText);
      if (json == null) {
        await messagesCol.add({
          'role': 'assistant',
          'text': 'Sorry, I could not understand.',
          'createdAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      final resultText = await _handleIntent(json, user.uid);
      await messagesCol.add({
        'role': 'assistant',
        'text': resultText,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final messagesCol = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('ai_messages');
        await messagesCol.add({
          'role': 'assistant',
          'text': 'Error: $e',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<String> _handleIntent(Map<String, dynamic> json, String userId) async {
    final intent = (json['intent'] ?? '').toString();
    final category = (json['category'] as String?)?.trim();
    final amount = (json['amount'] is num) ? (json['amount'] as num).toDouble() : null;
    final transactionType = (json['transactionType'] as String?)?.trim();
    final dateStr = (json['date'] as String?)?.trim();
    final notes = (json['notes'] as String?)?.trim();
    final updateMode = (json['updateMode'] as String?)?.trim();
    final timeRange = (json['timeRange'] as String?)?.trim();
    final startDateStr = (json['startDate'] as String?)?.trim();
    final endDateStr = (json['endDate'] as String?)?.trim();

    final budgets = FirebaseFirestore.instance.collection('budgets');
    final transactions = FirebaseFirestore.instance.collection('transactions');

    DateTime? parsedDate;
    if (dateStr != null && dateStr.isNotEmpty) {
      if (dateStr.toLowerCase() == 'today') {
        parsedDate = DateTime.now();
      } else {
        try { parsedDate = DateTime.parse(dateStr); } catch (_) {}
      }
    }

    // Resolve time window for queries
    DateTimeRange? window;
    final now = DateTime.now();
    if (timeRange != null && timeRange.isNotEmpty) {
      switch (timeRange) {
        case 'last_3_days':
          window = DateTimeRange(start: now.subtract(const Duration(days: 3)), end: now);
          break;
        case 'last_7_days':
          window = DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
          break;
        case 'last_30_days':
          window = DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);
          break;
        case 'this_month':
          final start = DateTime(now.year, now.month, 1);
          final end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));
          window = DateTimeRange(start: start, end: end);
          break;
        case 'last_month':
          final start = DateTime(now.year, now.month - 1, 1);
          final end = DateTime(now.year, now.month, 1).subtract(const Duration(seconds: 1));
          window = DateTimeRange(start: start, end: end);
          break;
        case 'this_year':
          final start = DateTime(now.year, 1, 1);
          final end = DateTime(now.year + 1, 1, 1).subtract(const Duration(seconds: 1));
          window = DateTimeRange(start: start, end: end);
          break;
        case 'custom':
          try {
            if (startDateStr != null && endDateStr != null) {
              window = DateTimeRange(start: DateTime.parse(startDateStr), end: DateTime.parse(endDateStr));
            }
          } catch (_) {}
          break;
      }
    }

    switch (intent) {
      case 'query_budget':
        {
          Query<Map<String, dynamic>> q = budgets.where('userId', isEqualTo: userId);
          if (category != null && category.isNotEmpty) {
            q = q.where('name', isEqualTo: category);
          }
          final snap = await q.get();
          if (snap.docs.isEmpty) return 'No budget data found.';
          if (category != null && category.isNotEmpty) {
            final d = snap.docs.first.data();
            final allocated = (d['allocated'] ?? 0).toDouble();
            final spent = (d['spent'] ?? 0).toDouble();
            return '$category: allocated PKR ${allocated.toStringAsFixed(0)}, spent PKR ${spent.toStringAsFixed(0)}.';
          }
          double totalAllocated = 0, totalSpent = 0;
          for (final doc in snap.docs) {
            totalAllocated += (doc['allocated'] ?? 0).toDouble();
            totalSpent += (doc['spent'] ?? 0).toDouble();
          }
          return 'All budgets: allocated PKR ${totalAllocated.toStringAsFixed(0)}, spent PKR ${totalSpent.toStringAsFixed(0)}.';
        }
      case 'update_budget':
      case 'add_budget_category':
        {
          if (category == null || amount == null) return 'Need category and amount.';
          final existing = await budgets
              .where('userId', isEqualTo: userId)
              .where('name', isEqualTo: category)
              .limit(1)
              .get();
          if (existing.docs.isEmpty) {
            await budgets.add({
              'name': category,
              'allocated': amount,
              'spent': 0.0,
              'userId': userId,
              'createdAt': Timestamp.now(),
            });
            return 'Created budget "$category" with PKR ${amount.toStringAsFixed(0)}.';
          } else {
            final current = (existing.docs.first['allocated'] ?? 0).toDouble();
            final shouldIncrement = (updateMode == 'increment');
            final newValue = shouldIncrement ? (current + amount) : amount;
            await existing.docs.first.reference.update({'allocated': newValue});
            return shouldIncrement
                ? 'Increased "$category" budget by PKR ${amount.toStringAsFixed(0)} (now PKR ${newValue.toStringAsFixed(0)}).'
                : 'Set "$category" budget to PKR ${newValue.toStringAsFixed(0)}.';
          }
        }
      case 'delete_budget_category':
        {
          if (category == null) return 'Need category.';
          final existing = await budgets
              .where('userId', isEqualTo: userId)
              .where('name', isEqualTo: category)
              .limit(1)
              .get();
          if (existing.docs.isEmpty) return 'Category not found.';
          await existing.docs.first.reference.delete();
          return 'Deleted budget category "$category".';
        }
      case 'add_transaction':
        {
          String resolvedCategory = (category == null || category.isEmpty) ? 'Other' : category;
          if (amount == null || transactionType == null) return 'Need amount and type.';
          await transactions.add({
            'userId': userId,
            'category': resolvedCategory,
            'amount': amount,
            'type': transactionType,
            'date': Timestamp.fromDate(parsedDate ?? DateTime.now()),
            'notes': notes,
          });
          if (transactionType == 'expense') {
            final cat = await budgets
                .where('userId', isEqualTo: userId)
                .where('name', isEqualTo: resolvedCategory)
                .limit(1)
                .get();
            if (cat.docs.isNotEmpty) {
              final spent = (cat.docs.first['spent'] ?? 0).toDouble();
              await cat.docs.first.reference.update({'spent': spent + amount});
            }
          }
          return 'Added $transactionType of PKR ${amount.toStringAsFixed(0)} to "$resolvedCategory".';
        }
      case 'delete_transaction':
        {
          Query<Map<String, dynamic>> q = transactions
              .where('userId', isEqualTo: userId)
              .orderBy('date', descending: true)
              .limit(1);
          if (category != null && category.isNotEmpty) {
            q = transactions
                .where('userId', isEqualTo: userId)
                .where('category', isEqualTo: category)
                .orderBy('date', descending: true)
                .limit(1);
          }
          final snap = await q.get();
          if (snap.docs.isEmpty) return 'No matching transaction found.';
          final doc = snap.docs.first;
          final data = doc.data();
          await doc.reference.delete();
          if ((data['type'] as String?) == 'expense') {
            final cat = await budgets
                .where('userId', isEqualTo: userId)
                .where('name', isEqualTo: data['category'])
                .limit(1)
                .get();
            if (cat.docs.isNotEmpty) {
              final spent = (cat.docs.first['spent'] ?? 0).toDouble();
              await cat.docs.first.reference.update({'spent': (spent - (data['amount'] ?? 0)).clamp(0, double.infinity)});
            }
          }
          return 'Deleted last${category != null ? ' $category' : ''} transaction.';
        }
      case 'query_income_expense':
        {
          Query<Map<String, dynamic>> q = transactions.where('userId', isEqualTo: userId);
          if (window != null) {
            q = q
                .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(window.start))
                .where('date', isLessThanOrEqualTo: Timestamp.fromDate(window.end));
          }
          final snap = await q.get();
          double income = 0, expense = 0;
          for (final d in snap.docs) {
            final amt = (d['amount'] ?? 0).toDouble();
            if (d['type'] == 'income') income += amt; else expense += amt;
          }
          final rangeLabel = _rangeLabel(window);
          return '${rangeLabel.isEmpty ? '' : '$rangeLabel: '}Income PKR ${income.toStringAsFixed(0)}, expenses PKR ${expense.toStringAsFixed(0)}.';
        }
      case 'query_spending':
        {
          Query<Map<String, dynamic>> q = transactions
              .where('userId', isEqualTo: userId)
              .where('type', isEqualTo: 'expense');
          if (window != null) {
            q = q
                .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(window.start))
                .where('date', isLessThanOrEqualTo: Timestamp.fromDate(window.end));
          }
          if (category != null && category.isNotEmpty) {
            q = q.where('category', isEqualTo: category);
          }
          final snap = await q.get();
          double total = 0;
          final Map<String, double> byCategory = {};
          for (final d in snap.docs) {
            final amt = (d['amount'] ?? 0).toDouble();
            total += amt;
            final cat = (d['category'] ?? 'Unknown') as String;
            byCategory[cat] = (byCategory[cat] ?? 0) + amt;
          }
          final rangeLabel = _rangeLabel(window);
          if (category != null && category.isNotEmpty) {
            return '${rangeLabel.isEmpty ? '' : '$rangeLabel: '}Spent PKR ${total.toStringAsFixed(0)} on $category.';
          }
          if (byCategory.isEmpty) return 'No spending found${rangeLabel.isEmpty ? '' : ' for $rangeLabel'}.';
          final parts = byCategory.entries
              .toList()
              .map((e) => '${e.key}: PKR ${e.value.toStringAsFixed(0)}')
              .join(', ');
          return '${rangeLabel.isEmpty ? '' : '$rangeLabel: '}Spending -> $parts (Total PKR ${total.toStringAsFixed(0)}).';
        }
      default:
        return 'I could not understand. Try rephrasing.';
    }
  }

  String _rangeLabel(DateTimeRange? w) {
    if (w == null) return '';
    return '${w.start.year}-${w.start.month.toString().padLeft(2, '0')}-${w.start.day.toString().padLeft(2, '0')} to ${w.end.year}-${w.end.month.toString().padLeft(2, '0')}-${w.end.day.toString().padLeft(2, '0')}';
  }

  void _appendAssistant(String text) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final messagesCol = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('ai_messages');
    await messagesCol.add({
      'role': 'assistant',
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _clearHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final messagesCol = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('ai_messages');
    final snap = await messagesCol.get();
    final batch = FirebaseFirestore.instance.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        actions: [
          IconButton(
            tooltip: 'Clear chat',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear chat?'),
                  content: const Text('This will delete all chat messages.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
                  ],
                ),
              );
              if (ok == true) {
                await _clearHistory();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _messagesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: docs.length + (_isSending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isSending && index == docs.length) {
                      return _typingBubble();
                    }
                    final d = docs[index].data();
                    final isUser = (d['role'] as String?) == 'user';
                    final text = (d['text'] as String?) ?? '';
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser ? const Color(0xFF3B82F6) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          text,
                          style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: 'Message AI... (add, update, delete, ask)',
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFF3B82F6))),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF3B82F6),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send, color: Colors.white),
                      onPressed: _isSending ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _messagesStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('ai_messages')
        .orderBy('createdAt')
        .snapshots();
  }

  Widget _typingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [ _Dot(), SizedBox(width: 4), _Dot(), SizedBox(width: 4), _Dot() ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot();
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _a = Tween<double>(begin: 0.4, end: 1).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle)),
    );
  }
}

enum ChatRole { user, assistant }

