import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gamification_service.dart';
import '../theme/theme_provider.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final _gamificationService = GamificationService();

  int _lumenCoins = 0;
  List<String> _unlockedItems = [];
  bool _loading = true;
  bool _purchasing = false;

  // Hardcoded Catalog
  final List<Map<String, dynamic>> _catalog = [
    {
      'id': 'avatar_socratic',
      'name': 'Socratic Tutor Avatar',
      'description':
          'An AI persona that asks guiding questions instead of giving direct answers.',
      'cost': 150,
      'icon': Icons.psychology,
      'color': Colors.blueAccent,
      'type': 'Avatar',
    },
    {
      'id': 'avatar_hypeman',
      'name': 'Hype-Man Avatar',
      'description':
          'An energetic AI that aggressively encourages you to keep studying.',
      'cost': 150,
      'icon': Icons.local_fire_department,
      'color': Colors.orangeAccent,
      'type': 'Avatar',
    },
    {
      'id': 'default',
      'name': 'Midnight Ocean',
      'description': 'The default smooth dark theme for late night focus.',
      'cost': 0,
      'icon': Icons.nightlight_round,
      'color': Colors.blue,
      'type': 'Theme',
    },
    {
      'id': 'theme_synthwave',
      'name': 'Cyberpunk / Neon',
      'description':
          'Unlock a glowing retro-futuristic dark neon visual theme.',
      'cost': 350,
      'icon': Icons.bolt,
      'color': Colors.pinkAccent,
      'type': 'Theme',
    },
    {
      'id': 'theme_sunset',
      'name': 'Sunset Warm',
      'description': 'A bright minimal theme resembling warm sunset gradients.',
      'cost': 250,
      'icon': Icons.wb_sunny,
      'color': Colors.orange,
      'type': 'Theme',
    },
    {
      'id': 'theme_crimson',
      'name': 'Crimson Tech',
      'description':
          'Dark minimalist theme marked by aggressive red tech accents.',
      'cost': 400,
      'icon': Icons.memory,
      'color': Colors.redAccent,
      'type': 'Theme',
    },
    {
      'id': 'theme_sketch',
      'name': 'Sketchbook',
      'description':
          'Clean white background with sketchy borders and mint aesthetic.',
      'cost': 400,
      'icon': Icons.brush,
      'color': Colors.greenAccent,
      'type': 'Theme',
    },
    {
      'id': 'theme_noir',
      'name': 'Noir Minimal',
      'description':
          'Sleek, heavily desaturated dark mode with muted gold trims.',
      'cost': 300,
      'icon': Icons.diamond,
      'color': Colors.amber,
      'type': 'Theme',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final profile = await _gamificationService.fetchProfile();
      if (mounted) {
        setState(() {
          _lumenCoins = profile['lumen_coins'] as int? ?? 0;
          _unlockedItems = List<String>.from(profile['unlocked_items'] ?? []);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _purchaseItem(String id, int cost, String name) async {
    if (_lumenCoins < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Not enough Lumen Coins! Need $cost.')),
      );
      return;
    }

    setState(() => _purchasing = true);

    final success = await _gamificationService.purchaseItem(id, cost);

    if (mounted) {
      setState(() => _purchasing = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Unlocked $name!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadProfile(); // Refresh balance and unlocks
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to purchase item. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentAppTheme = Theme.of(context);

    return Scaffold(
      backgroundColor: currentAppTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: currentAppTheme.scaffoldBackgroundColor,
        elevation: 0,
        title: const Text(
          'Lumen Store',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.stars, color: Colors.amber),
                const SizedBox(width: 6),
                Text(
                  '$_lumenCoins',
                  style: TextStyle(
                    color:
                        currentAppTheme.textTheme.bodyLarge?.color ??
                        Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.purpleAccent),
            )
          : Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _catalog.length,
                  itemBuilder: (context, index) {
                    final item = _catalog[index];
                    final id = item['id'] as String;
                    final name = item['name'] as String;
                    final desc = item['description'] as String;
                    final cost = item['cost'] as int;
                    final isOwned = _unlockedItems.contains(id);
                    final icon = item['icon'] as IconData;
                    final baseColor = item['color'] as Color;
                    final type = item['type'] as String;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: currentAppTheme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isOwned || cost == 0
                              ? Colors.green.withOpacity(0.5)
                              : Colors.grey.withOpacity(0.05),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: baseColor.withOpacity(0.1),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(icon, color: baseColor, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  type.toUpperCase(),
                                  style: TextStyle(
                                    color: baseColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          color:
                                              currentAppTheme
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color ??
                                              Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        desc,
                                        style: TextStyle(
                                          color:
                                              (currentAppTheme
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.color ??
                                                      Colors.white)
                                                  .withOpacity(0.6),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                _buildActionWidget(
                                  type: type,
                                  isOwned: isOwned || cost == 0,
                                  isEquipped:
                                      themeProvider.currentThemeId == id,
                                  cost: cost,
                                  onPurchase: () =>
                                      _purchaseItem(id, cost, name),
                                  onEquip: () =>
                                      themeProvider.setEquippedTheme(id),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                if (_purchasing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.purpleAccent,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildActionWidget({
    required String type,
    required bool isOwned,
    required bool isEquipped,
    required int cost,
    required VoidCallback onPurchase,
    required VoidCallback onEquip,
  }) {
    if (type == 'Theme') {
      if (isOwned) {
        if (isEquipped) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green),
            ),
            child: const Text(
              'EQUIPPED',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        } else {
          return ElevatedButton(
            onPressed: onEquip,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'EQUIP',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        }
      } else {
        return _buildPurchaseButton(cost, onPurchase);
      }
    } else {
      // Avatars logic
      if (isOwned) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green),
          ),
          child: const Text(
            'OWNED',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
        );
      } else {
        return _buildPurchaseButton(cost, onPurchase);
      }
    }
  }

  Widget _buildPurchaseButton(int cost, VoidCallback onPurchase) {
    return ElevatedButton.icon(
      onPressed: onPurchase,
      icon: const Icon(Icons.shopping_cart, size: 16),
      label: Text('$cost', style: const TextStyle(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: _lumenCoins >= cost
            ? Colors.purpleAccent
            : Colors.grey[800],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
