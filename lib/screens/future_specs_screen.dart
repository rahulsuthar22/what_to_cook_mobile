import 'package:flutter/material.dart';
import 'portal_navigation.dart';

class FutureSpecsScreen extends StatefulWidget {
  const FutureSpecsScreen({super.key});

  @override
  State<FutureSpecsScreen> createState() => _FutureSpecsScreenState();
}

class _FutureSpecsScreenState extends State<FutureSpecsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Chatbot Mock State
  final List<Map<String, String>> _chatMessages = [
    {'sender': 'chef', 'text': 'Hello! I am your AI Chef Assistant. Tell me what ingredients you have, and I will create custom recipe steps for you!'}
  ];
  final _chatController = TextEditingController();

  // Voice Mock State
  bool _isListening = false;
  String _voiceText = 'Click the mic and say: "Suggest a quick vegetarian dinner for tonight"';

  // Scanner Mock State
  bool _isScanning = false;
  List<String> _scannedItems = [];

  // Delivery Mock State
  bool _isExported = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  void _sendChatMessage() {
    if (_chatController.text.trim().isEmpty) return;
    
    final text = _chatController.text.trim();
    setState(() {
      _chatMessages.add({'sender': 'user', 'text': text});
      _chatController.clear();
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() {
        String reply = "That sounds delicious! You can make a custom stir fry using those ingredients. Would you like me to generate instructions?";
        if (text.toLowerCase().contains('paneer')) {
          reply = "Great choice! Since you have paneer, I suggest making a quick Paneer Bhurji. Sauté onions, tomatoes, and crumbled paneer with spices!";
        } else if (text.toLowerCase().contains('egg')) {
          reply = "With eggs, you can make a classic French Omelette or Egg Fried Rice. Let me know which one you prefer!";
        }
        _chatMessages.add({'sender': 'chef', 'text': reply});
      });
    });
  }

  void _triggerVoice() {
    setState(() {
      _isListening = true;
      _voiceText = 'Listening to voice input...';
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _voiceText = 'Transcribed: "Add Paneer and Onion to my pantry list"';
      });
    });
  }

  void _triggerScan() {
    setState(() {
      _isScanning = true;
      _scannedItems = [];
    });

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _scannedItems = ['Paneer', 'Tomato', 'Onion', 'Green Chillies'];
      });
    });
  }

  void _triggerExport(String provider) {
    setState(() {
      _isExported = true;
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() {
        _isExported = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFFF5A36);
    final surfaceColor = const Color(0xFF1E1E2C);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text('AI Chef & Smart Tools', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              final navState = context.findAncestorStateOfType<PortalNavigationState>();
              navState?.setTab(0);
            }
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.chat_outlined), text: 'AI Chat'),
            Tab(icon: Icon(Icons.mic_outlined), text: 'Voice Assist'),
            Tab(icon: Icon(Icons.camera_alt_outlined), text: 'Scanner'),
            Tab(icon: Icon(Icons.apple_outlined), text: 'Macros'),
            Tab(icon: Icon(Icons.local_shipping_outlined), text: 'Delivery'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. AI Chatbot
          _buildChatTab(surfaceColor, primaryColor),
          // 2. Voice Assistant
          _buildVoiceTab(surfaceColor, primaryColor),
          // 3. Fridge Scanner
          _buildScannerTab(surfaceColor, primaryColor),
          // 4. Macros Dashboard
          _buildMacrosTab(surfaceColor, primaryColor),
          // 5. Grocery Delivery
          _buildDeliveryTab(surfaceColor, primaryColor),
        ],
      ),
    );
  }

  Widget _buildChatTab(Color surfaceColor, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView.builder(
                itemCount: _chatMessages.length,
                itemBuilder: (context, idx) {
                  final msg = _chatMessages[idx];
                  final isChef = msg['sender'] == 'chef';
                  return Align(
                    alignment: isChef ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isChef ? Colors.white.withValues(alpha: 0.04) : primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                      child: Text(
                        msg['text'] ?? '',
                        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Ask Chef: "I have eggs, what can I cook?"',
                    hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                    filled: true,
                    fillColor: surfaceColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                onPressed: _sendChatMessage,
                backgroundColor: primaryColor,
                mini: true,
                child: const Icon(Icons.send, color: Colors.white, size: 18),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildVoiceTab(Color surfaceColor, Color primaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Voice-Activated Cooking Companion',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hands-free app portal interaction while cooking.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Stack(
              alignment: Alignment.center,
              children: [
                if (_isListening)
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.redAccent.withValues(alpha: 0.15),
                    ),
                  ),
                GestureDetector(
                  onTap: _triggerVoice,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening ? Colors.redAccent : primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? Colors.redAccent : primaryColor).withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: const Icon(Icons.mic, color: Colors.white, size: 36),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                _voiceText,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildScannerTab(Color surfaceColor, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'AI Fridge Scanner',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Click the card to simulate snapping a photo of your fridge ingredients.',
            style: TextStyle(color: Colors.white38, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: _triggerScan,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Icon(Icons.camera_alt_outlined, color: Colors.white38, size: 48),
                  const SizedBox(height: 16),
                  const Text('Simulate Fridge Shelf Snapshot', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Classifies dairy, vegetables, & pantry items', style: TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_isScanning)
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFFFF5A36), strokeWidth: 2)),
                SizedBox(width: 12),
                Text('Running image classification models...', style: TextStyle(color: Colors.white60, fontSize: 13)),
              ],
            ),
          if (_scannedItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Success: Detected 4 pantry items!',
                    style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _scannedItems.map((item) {
                      return Chip(
                        label: Text(item),
                        backgroundColor: Colors.green.withValues(alpha: 0.2),
                        labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMacrosTab(Color surfaceColor, Color primaryColor) {
    final List<Map<String, dynamic>> macros = [
      {'name': 'Calories Intake', 'current': 1850, 'goal': 2200, 'unit': 'kcal', 'color': primaryColor},
      {'name': 'Protein Target', 'current': 68, 'goal': 85, 'unit': 'g', 'color': Colors.blueAccent},
      {'name': 'Carbs Limit', 'current': 195, 'goal': 250, 'unit': 'g', 'color': Colors.amberAccent},
      {'name': 'Fat Limit', 'current': 52, 'goal': 70, 'unit': 'g', 'color': Colors.tealAccent},
    ];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Personalized Nutrition Goals',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        const Text('Calculated dynamically from your planned weekly meals.', style: TextStyle(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 20),
        Column(
          children: macros.map((macro) {
            final double percent = macro['current'] / macro['goal'];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(macro['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('${macro['current']} / ${macro['goal']} ${macro['unit']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent,
                      backgroundColor: Colors.white.withValues(alpha: 0.04),
                      valueColor: AlwaysStoppedAnimation<Color>(macro['color']),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        )
      ],
    );
  }

  Widget _buildDeliveryTab(Color surfaceColor, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Direct Grocery Delivery Integration',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Send compiled recipe ingredients directly to local delivery partners.',
            style: TextStyle(color: Colors.white38, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('Shopping List: 12 items pending checkout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: ['Instacart', 'Amazon Fresh', 'Blinkit', 'BigBasket'].map((provider) {
                    return ElevatedButton(
                      onPressed: () => _triggerExport(provider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.04),
                        side: const BorderSide(color: Colors.white10),
                      ),
                      child: Text('Export to $provider', style: const TextStyle(color: Colors.white70)),
                    );
                  }).toList(),
                ),
                if (_isExported) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
                        SizedBox(width: 8),
                        Text('Cart exported! Open provider app to check out.', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          )
        ],
      ),
    );
  }
}
