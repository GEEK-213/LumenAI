import 'package:flutter/material.dart';
import '../services/gamification_service.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final _gamificationService = GamificationService();

  List<Map<String, dynamic>> _leaderboard = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() => _loading = true);
    final data = await _gamificationService.fetchLeaderboard(limit: 50);
    if (mounted) {
      setState(() {
        _leaderboard = data;
        _loading = false;
      });
    }
  }

  // Helper for rank colors
  Color _getRankColor(int index) {
    if (index == 0) return const Color(0xFFFFD700); // Gold
    if (index == 1) return const Color(0xFFC0C0C0); // Silver
    if (index == 2) return const Color(0xFFCD7F32); // Bronze
    return Colors.white70;
  }

  Widget _buildTopThreeNode(
    Map<String, dynamic> user,
    int rank,
    double size,
    Color color,
  ) {
    final name = user['display_name'] as String? ?? 'Anonymous';
    final xp = user['xp'] as int? ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: size,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(Icons.person, size: size, color: color),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        Text(
          '$xp XP',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Separate top 3 and the rest
    final topThree = _leaderboard.take(3).toList();
    final remaining = _leaderboard.skip(3).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: const Text(
          'Global Rankings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLeaderboard,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.purpleAccent),
            )
          : _leaderboard.isEmpty
          ? const Center(
              child: Text(
                "No scholars found. Be the first!",
                style: TextStyle(color: Colors.white70),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchLeaderboard,
              child: CustomScrollView(
                slivers: [
                  // Top 3 Podium
                  if (topThree.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 32,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purpleAccent.withOpacity(0.1),
                              Colors.transparent,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Rank 2
                            if (topThree.length > 1)
                              Expanded(
                                child: _buildTopThreeNode(
                                  topThree[1],
                                  2,
                                  36,
                                  _getRankColor(1),
                                ),
                              )
                            else
                              const Spacer(),

                            // Rank 1
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: _buildTopThreeNode(
                                  topThree[0],
                                  1,
                                  48,
                                  _getRankColor(0),
                                ),
                              ),
                            ),

                            // Rank 3
                            if (topThree.length > 2)
                              Expanded(
                                child: _buildTopThreeNode(
                                  topThree[2],
                                  3,
                                  30,
                                  _getRankColor(2),
                                ),
                              )
                            else
                              const Spacer(),
                          ],
                        ),
                      ),
                    ),

                  // Remaining List
                  if (remaining.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final user = remaining[index];
                          final rank = index + 4; // Because top 3 are separated
                          final name =
                              user['display_name'] as String? ??
                              'Anonymous Scholar';
                          final title =
                              user['rank_title'] as String? ?? 'Novice';
                          final xp = user['xp'] as int? ?? 0;
                          final coins = user['lumen_coins'] as int? ?? 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A2235),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    '#$rank',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.white10,
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white54,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
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
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          color: Colors.purpleAccent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '$xp XP',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.stars,
                                          color: Colors.amber,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$coins',
                                          style: const TextStyle(
                                            color: Colors.amber,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }, childCount: remaining.length),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
