# 🚀 Flutter Performance Optimization Guide

## **🔍 Understanding the Logs**

### **✅ Safe to Ignore:**
- `D/UserSceneDetector: invoke error.` - Android system log, not your app
- `D/ViewRootImplStubImpl: onAnimationUpdate` - Android animation system
- `I/ImeTracker: onRequestHide` - Android keyboard management

### **❌ Must Fix:**
- `I/Choreographer: Skipped 30 frames!` - Your app is blocking the main thread

## **🚀 Solution 1: Move Heavy Work Off Main Thread**

### **Using `compute()` for Background Processing:**

```dart
import 'package:flutter/foundation.dart';

// ❌ Bad: Blocking main thread
Future<List<Transaction>> getTransactions() async {
  final db = await database;
  final maps = await db.query('transactions');
  
  // This blocks the main thread!
  return maps.map((map) => Transaction.fromMap(map)).toList();
}

// ✅ Good: Using compute() for background processing
Future<List<Transaction>> getTransactions() async {
  final db = await database;
  final maps = await db.query('transactions');
  
  // Process in background thread
  return await compute(_parseTransactions, maps);
}

// Background method (must be static and top-level)
static List<Transaction> _parseTransactions(List<Map<String, dynamic>> maps) {
  return maps.map((map) => Transaction.fromMap(map)).toList();
}
```

### **Using `Future.wait()` for Parallel Operations:**

```dart
// ❌ Bad: Sequential loading
Future<void> loadData() async {
  final transactions = await getTransactions();      // Wait for this
  final budgets = await getBudgetCategories();      // Then wait for this
  final goals = await getGoals();                   // Then wait for this
}

// ✅ Good: Parallel loading
Future<void> loadData() async {
  final results = await Future.wait([
    getTransactions(),
    getBudgetCategories(),
    getGoals(),
  ]);
  
  final transactions = results[0];
  final budgets = results[1];
  final goals = results[2];
}
```

## **🚀 Solution 2: Optimize Database Operations**

### **Batch Database Operations:**

```dart
// ❌ Bad: Multiple database calls
Future<void> updateBudget() async {
  await db.update('budget_categories', data1);
  await db.update('budget_categories', data2);
  await db.update('budget_categories', data3);
}

// ✅ Good: Single batch operation
Future<void> updateBudget() async {
  await db.transaction((txn) async {
    await txn.update('budget_categories', data1);
    await txn.update('budget_categories', data2);
    await txn.update('budget_categories', data3);
  });
}
```

### **Use Indexes for Fast Queries:**

```dart
// Add indexes to your database creation
await db.execute('''
  CREATE INDEX idx_transactions_user_date 
  ON transactions(userId, date DESC)
''');

await db.execute('''
  CREATE INDEX idx_budget_user 
  ON budget_categories(userId)
''');
```

## **🚀 Solution 3: Optimize UI Rendering**

### **Use `const` Constructors:**

```dart
// ❌ Bad: Creates new instance every rebuild
Text('Hello World', style: TextStyle(fontSize: 16))

// ✅ Good: Reuses same instance
const Text('Hello World', style: TextStyle(fontSize: 16))
```

### **Optimize List Views:**

```dart
// ❌ Bad: No itemExtent or cacheExtent
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)

// ✅ Good: With optimizations
ListView.builder(
  itemCount: items.length,
  itemExtent: 80, // Fixed height for better performance
  cacheExtent: 200, // Cache more items
  itemBuilder: (context, index) => ItemWidget(items[index]),
)
```

### **Use `RepaintBoundary` for Complex Widgets:**

```dart
// Wrap complex widgets that don't need frequent repaints
RepaintBoundary(
  child: ComplexChartWidget(data: chartData),
)
```

## **🚀 Solution 4: Memory Management**

### **Dispose Controllers and Listeners:**

```dart
class _MyWidgetState extends State<MyWidget> {
  late TextEditingController _controller;
  late ScrollController _scrollController;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _scrollController = ScrollController();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
```

### **Use `mounted` Check:**

```dart
Future<void> loadData() async {
  try {
    final data = await expensiveOperation();
    
    // Check if widget is still mounted before setState
    if (mounted) {
      setState(() {
        _data = data;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _error = e.toString();
      });
    }
  }
}
```

## **🚀 Solution 5: Animation Optimization**

### **Use `AnimatedBuilder` for Custom Animations:**

```dart
class _AnimatedWidget extends StatefulWidget {
  @override
  _AnimatedWidgetState createState() => _AnimatedWidgetState();
}

class _AnimatedWidgetState extends State<_AnimatedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: child,
        );
      },
      child: YourWidget(),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### **Use `SlideTransition` and `FadeTransition`:**

```dart
SlideTransition(
  position: Tween<Offset>(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(_controller),
  child: FadeTransition(
    opacity: _controller,
    child: YourWidget(),
  ),
)
```

## **🚀 Solution 6: Image Optimization**

### **Use `cached_network_image` for Network Images:**

```yaml
dependencies:
  cached_network_image: ^3.3.0
```

```dart
CachedNetworkImage(
  imageUrl: 'https://example.com/image.jpg',
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
  memCacheWidth: 300, // Limit memory usage
  memCacheHeight: 300,
)
```

### **Optimize Local Images:**

```dart
Image.asset(
  'assets/images/large_image.png',
  width: 200,
  height: 200,
  fit: BoxFit.cover,
  cacheWidth: 400, // 2x for high DPI screens
  cacheHeight: 400,
)
```

## **🚀 Solution 7: State Management Optimization**

### **Use `Provider` with `ChangeNotifierProvider.value`:**

```dart
// ❌ Bad: Creates new ChangeNotifier every rebuild
ChangeNotifierProvider(
  create: (context) => MyNotifier(),
  child: MyWidget(),
)

// ✅ Good: Reuses existing instance
ChangeNotifierProvider.value(
  value: existingNotifier,
  child: MyWidget(),
)
```

### **Use `Selector` for Granular Updates:**

```dart
// ❌ Bad: Rebuilds on any change
Consumer<MyNotifier>(
  builder: (context, notifier, child) {
    return Text(notifier.someValue);
  },
)

// ✅ Good: Only rebuilds when specific value changes
Selector<MyNotifier, String>(
  selector: (context, notifier) => notifier.someValue,
  builder: (context, value, child) {
    return Text(value);
  },
)
```

## **🚀 Solution 8: Testing Performance**

### **Use Flutter Inspector:**

1. Run app in debug mode
2. Open Flutter Inspector
3. Check "Performance Overlay" to see frame rate
4. Use "Repaint Rainbow" to identify unnecessary repaints

### **Use Performance Profiler:**

```bash
flutter run --profile
```

### **Check Frame Rate:**

```dart
// Add this to see frame rate in debug mode
if (kDebugMode) {
  debugPrint('Frame rate: ${WidgetsBinding.instance.schedulerPhase}');
}
```

## **🚀 Quick Wins Checklist**

- [ ] Use `compute()` for expensive operations
- [ ] Use `Future.wait()` for parallel operations
- [ ] Add `const` constructors everywhere possible
- [ ] Dispose controllers and listeners
- [ ] Check `mounted` before `setState`
- [ ] Use `RepaintBoundary` for complex widgets
- [ ] Optimize database queries with indexes
- [ ] Use `cached_network_image` for network images
- [ ] Limit image cache sizes
- [ ] Use `Selector` instead of `Consumer` when possible

## **🚀 Performance Monitoring**

### **Add Performance Logging:**

```dart
class PerformanceMonitor {
  static void logOperation(String operation, Function() callback) {
    final stopwatch = Stopwatch()..start();
    callback();
    stopwatch.stop();
    
    if (stopwatch.elapsedMilliseconds > 16) { // 60 FPS = 16ms per frame
      print('⚠️ Slow operation: $operation took ${stopwatch.elapsedMilliseconds}ms');
    }
  }
}

// Usage
PerformanceMonitor.logOperation('Database Query', () {
  // Your expensive operation
});
```

Follow these guidelines and your app will run smoothly at 60 FPS! 🎯
