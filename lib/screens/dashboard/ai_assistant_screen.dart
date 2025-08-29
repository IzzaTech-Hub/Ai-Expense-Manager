import 'package:flutter/material.dart';
import '../../services/ai_service.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';
import '../../routes/app_routes.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  List<Map<String, dynamic>> _chatHistory = [];
  User? _currentUser;

  late final AIService _aiService;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _aiService = AIService();
    _isSending = false; // Initialize the sending state
    _chatHistory = <Map<String, dynamic>>[]; // Initialize as empty mutable list
    _loadUserAndChatHistory();
    _testApiConnection();
  }

  Future<void> _loadUserAndChatHistory() async {
    try {
      final user = await _databaseService.getUser('default_user');
      if (user != null) {
        final chatHistory = await _aiService.getChatHistory(user.id, limit: 50);
        
        setState(() {
          _currentUser = user;
          _chatHistory = List<Map<String, dynamic>>.from(chatHistory);
        });
      }
    } catch (e) {
      print('Error loading user and chat history: $e');
    }
  }

  Future<void> _testApiConnection() async {
    try {
      final isConnected = await _aiService.testApiConnection();
      if (!isConnected) {
        print('AI Service: API connection test failed');
        // Don't show error to user immediately, let them try to use it first
      } else {
        print('AI Service: API connection test successful');
      }
    } catch (e) {
      print('AI Service: Error testing API connection: $e');
    }
  }

  Stream<bool> _getConnectionStatusStream() async* {
    // Initial check - use basic connectivity first
    yield await _aiService.testBasicConnectivity();
    
    // Periodic check every 10 seconds
    while (true) {
      await Future.delayed(const Duration(seconds: 10));
      yield await _aiService.testBasicConnectivity();
    }
  }

  void _refreshConnectionStatus() {
    // Force a refresh by calling setState
    setState(() {});
  }

  Future<bool> _checkApiKeyPoolStatus() async {
    try {
      // Check if ApiKeyPool is working by trying to get a key
      return _aiService.isApiKeyPoolReady();
    } catch (e) {
      print('AI Assistant: Failed to check ApiKeyPool status: $e');
      return false;
    }
  }

  void _testApiKeyPool() async {
    try {
      print('🔑 Testing ApiKeyPool functionality...');
      final result = await _aiService.testApiKeyPool();
      
      print('📊 ApiKeyPool test result: $result');
      
      // Show result in a dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('ApiKeyPool Test Results'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status: ${result['status']}'),
                  Text('Ready: ${result['ready']}'),
                  if (result['keyLength'] != null) Text('Key Length: ${result['keyLength']}'),
                  if (result['keyPreview'] != null) Text('Key Preview: ${result['keyPreview']}...'),
                  if (result['isValid'] != null) Text('Valid Key: ${result['isValid']}'),
                  if (result['error'] != null) Text('Error: ${result['error']}'),
                  if (result['errorType'] != null) Text('Error Type: ${result['errorType']}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('❌ Error testing ApiKeyPool: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error testing ApiKeyPool: $e')),
        );
      }
    }
  }

  void _navigateBackToDashboard() {
    // Navigate back to dashboard and reset the bottom navigation state
    Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
  }

  void _showConnectionInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Connection Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('AI Assistant requires:'),
              const SizedBox(height: 8),
              const Text('• Internet connection'),
              const Text('• Valid API key'),
              const Text('• Google AI service access'),
              const SizedBox(height: 16),
              const Text('If you\'re having issues:'),
              const Text('1. Check your internet connection'),
              const Text('2. Try again in a few minutes'),
              const Text('3. Contact support if problem persists'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final userText = _controller.text.trim();
    if (userText.isEmpty || _isSending) {
      print('Cannot send: empty text or already sending');
        return;
      }

    print('Sending message: $userText');
    
    setState(() { 
      _isSending = true;
      // Ensure the list is mutable
      if (_chatHistory is! List<Map<String, dynamic>>) {
        _chatHistory = <Map<String, dynamic>>[];
      }
      _chatHistory.insert(0, {
        'role': 'user',
        'message': userText,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
    
    _controller.clear();
    _scrollToBottom();

    try {
      if (_currentUser == null) {
        print('No current user, creating default user');
        _appendAssistant('Please wait while I initialize...');
        // Try to get or create default user
        final user = await _databaseService.getUser('default_user');
        if (user != null) {
          setState(() {
            _currentUser = user;
          });
        } else {
          _appendAssistant('Error: Could not initialize user. Please restart the app.');
          return;
        }
      }

      print('Getting AI response for user: ${_currentUser!.id}');
      final response = await _aiService.getResponse(userText, _currentUser!.id);
      print('AI response received: ${response.substring(0, response.length > 50 ? 50 : response.length)}...');
      
      setState(() {
        // Ensure the list is mutable
        if (_chatHistory is! List<Map<String, dynamic>>) {
          _chatHistory = <Map<String, dynamic>>[];
        }
        _chatHistory.insert(0, {
          'role': 'assistant',
          'response': response,
          'timestamp': DateTime.now().toIso8601String(),
        });
      });
      
      _scrollToBottom();
    } catch (e) {
      print('Error in AI service: $e');
      String errorMessage = 'Sorry, I encountered an error. Please try again.';
      
      // Provide more specific error messages for common issues
      if (e.toString().contains('Network error') || 
          e.toString().contains('SocketException') ||
          e.toString().contains('timeout')) {
        errorMessage = 'I\'m having trouble connecting to the internet. Please check your internet connection and try again.';
      } else if (e.toString().contains('API key') || e.toString().contains('authentication')) {
        errorMessage = 'There\'s an issue with the AI service configuration. Please contact support.';
      }
      
      _appendAssistant(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _appendAssistant(String message) {
    setState(() {
      // Ensure the list is mutable
      if (_chatHistory is! List<Map<String, dynamic>>) {
        _chatHistory = <Map<String, dynamic>>[];
      }
      _chatHistory.insert(0, {
        'role': 'assistant',
        'response': message,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }



  Future<void> _clearChatHistory() async {
    try {
      if (_currentUser != null) {
        // Clear chat history from database
        await _databaseService.clearChatHistory(userId: _currentUser!.id);
        
        // Clear local chat history
        setState(() {
          _chatHistory.clear();
        });
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chat history cleared successfully!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error clearing chat history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing chat history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Chat History'),
          content: const Text(
            'Are you sure you want to clear all chat history? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearChatHistory();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print('AI Assistant Screen - Current user: ${_currentUser?.name}, isSending: $_isSending');
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        title: const Text(
          'AI Assistant',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => _navigateBackToDashboard(),
        ),
        actions: [
          // Network status indicator
          StreamBuilder<bool>(
            stream: _getConnectionStatusStream(),
            builder: (context, snapshot) {
              final isConnected = snapshot.data ?? true; // Default to true to avoid false negatives
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isConnected ? Icons.wifi : Icons.wifi_off,
                    color: isConnected ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  if (!isConnected) ...[
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18),
                      onPressed: () => _refreshConnectionStatus(),
                      tooltip: 'Refresh Connection',
                    ),
          IconButton(
                      icon: const Icon(Icons.info_outline, size: 18),
                      onPressed: () => _showConnectionInfo(),
                      tooltip: 'Connection Info',
                    ),
                  ],
                  // ApiKeyPool status indicator
                  FutureBuilder<bool>(
                    future: _checkApiKeyPoolStatus(),
                    builder: (context, snapshot) {
                      final isApiKeyReady = snapshot.data ?? false;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isApiKeyReady ? Icons.key : Icons.key_off,
                            color: isApiKeyReady ? Colors.green : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          if (!isApiKeyReady)
                            IconButton(
                              icon: const Icon(Icons.bug_report, size: 16),
                              onPressed: () => _testApiKeyPool(),
                              tooltip: 'Test ApiKeyPool',
                            ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
          if (_chatHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              onPressed: () => _showClearChatDialog(),
              tooltip: 'Clear Chat History',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _chatHistory.isEmpty
                ? _buildWelcomeMessage()
                : _buildChatList(),
          ),

          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.smart_toy_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome to your AI Financial Assistant!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me anything about your finances:\n• "How much did I spend on food this month?"\n• "Show my budget overview"\n• "What\'s my income vs expenses?"',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Network status message
          StreamBuilder<bool>(
            stream: _getConnectionStatusStream(),
              builder: (context, snapshot) {
              final isConnected = snapshot.data ?? true; // Default to true to avoid false negatives
              if (!isConnected) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Text(
                    '⚠️ No internet connection detected.\nThe AI assistant requires internet to function.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
                return ListView.builder(
                  controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: _chatHistory.length,
                  itemBuilder: (context, index) {
        final message = _chatHistory[index];
        final isUser = message['role'] == 'user';
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF3B82F6),
                  child: Icon(
                    Icons.smart_toy_outlined,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                      child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF3B82F6) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                        ),
                        child: Text(
                    isUser ? message['message'] : message['response'],
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[300],
                  child: Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
                      ),
                    );
                  },
                );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                hintText: 'Ask about your finances...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                        filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) {
                print('Text field submitted');
                _sendMessage();
              },
              onChanged: (value) {
                print('Text field changed: "$value"');
                setState(() {
                  // Force rebuild to show current text
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              print('Send button tapped, isSending: $_isSending');
              print('Button pressed! Current text: "${_controller.text}"');
              
              // Simple test response for debugging
              if (_controller.text.trim().isEmpty) {
                print('Empty text, showing test message');
                _appendAssistant('Please type a message first! You can ask me about your expenses, budget, or any financial questions.');
                return;
              }
              
              if (!_isSending) {
                print('Calling _sendMessage()');
                _sendMessage();
              } else {
                print('Cannot send - already sending');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isSending ? Colors.grey[400] : const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: _isSending ? 0 : 2,
            ),
            child: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Send',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
            ),
          ),
        ],
      ),
    );
  }
}

