import 'package:flutter/material.dart';
import '../services/gamification_service.dart';

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
      'cost': 500,
      'icon': Icons.psychology,
      'color': Colors.blueAccent,
      'type': 'Avatar',
    },
    {
      'id': 'avatar_hypeman',
      'name': 'Hype-Man Avatar',
      'description':
          'An energetic AI that aggressively encourages you to keep studying.',
      'cost': 500,
      'icon': Icons.local_fire_department,
      'color': Colors.orangeAccent,
      'type': 'Avatar',
    },
    {
      'id': 'theme_synthwave',
      'name': 'Synthwave Theme',
      'description':
          'Unlock a nostalgic 80s neon-grid visual theme for the app.',
      'cost': 1000,
      'icon': Icons.nightlight_round,
      'color': Colors.purpleAccent,
      'type': 'Theme',
    },
    {
      'id': 'theme_midnight',
      'name': 'Midnight Ocean',
      'description':
          'A deep, calming dark blue palette optimized for late-night studying.',
      'cost': 800,
      'icon': Icons.water,
      'color': Colors.indigoAccent,
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
    return Scaffold(
      backgroundColor: const Color(0xFF0C1223),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C1223),
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
                  style: const TextStyle(
                    color: Colors.white,
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
                        color: const Color(0xFF1A2235),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isOwned
                              ? Colors.green.withOpacity(0.5)
                              : Colors.white.withOpacity(0.05),
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
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        desc,
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                isOwned
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Colors.green,
                                          ),
                                        ),
                                        child: const Text(
                                          'OWNED',
                                          style: TextStyle(
                                            color: Colors.greenAccent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    : ElevatedButton.icon(
                                        onPressed: () =>
                                            _purchaseItem(id, cost, name),
                                        icon: const Icon(
                                          Icons.shopping_cart,
                                          size: 16,
                                        ),
                                        label: Text(
                                          '$cost',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _lumenCoins >= cost
                                              ? Colors.purpleAccent
                                              : Colors.grey[800],
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                        ),
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
}
