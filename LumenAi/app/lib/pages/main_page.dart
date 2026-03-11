import 'package:flutter/material.dart';
import 'calender/master_calender_page.dart';
import 'notes/notes_page.dart';
import 'home/homePage.dart';
import 'profile/profilePage.dart';
import 'notes/recorder.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  static const _breakpoint = 800.0;

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return const HomePage();
      case 1:
        return const MasterCalenderPage();
      case 2:
        return const NotesPage();
      case 3:
        return const Profilepage();
      default:
        return const HomePage();
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _breakpoint;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: isWide ? _buildDesktopLayout() : _buildPage(),
          floatingActionButton: !isWide && _selectedIndex != 2
              ? _buildRecorderFAB()
              : null,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: isWide ? null : _buildBottomNav(),
        );
      },
    );
  }

  // ─── Desktop: NavigationRail + Content ────────────────────────────
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Navigation Rail
        Container(
          decoration: BoxDecoration(
            color:
                Theme.of(context).bottomAppBarTheme.color ??
                Theme.of(context).colorScheme.surface,
            border: Border(
              right: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
              ),
            ),
          ),
          child: NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            backgroundColor: Colors.transparent,
            indicatorColor: Theme.of(context).primaryColor.withOpacity(0.15),
            selectedIconTheme: IconThemeData(
              color: Theme.of(context).primaryColor,
            ),
            unselectedIconTheme: IconThemeData(color: Colors.grey.shade500),
            selectedLabelTextStyle: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelTextStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
            ),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  // App logo
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blueAccent, Colors.purpleAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Lumen',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildRailRecorderButton(),
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.folder_outlined),
                selectedIcon: Icon(Icons.folder),
                label: Text('Projects'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.note_outlined),
                selectedIcon: Icon(Icons.analytics),
                label: Text('Notes'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('Profile'),
              ),
            ],
          ),
        ),
        // Content area
        Expanded(child: _buildPage()),
      ],
    );
  }

  // ─── Rail: Recorder button ────────────────────────────────────────
  Widget _buildRailRecorderButton() {
    return FloatingActionButton.small(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RecorderPage()),
        );
      },
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.blueAccent, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(Icons.mic, color: Colors.white, size: 22),
      ),
    );
  }

  // ─── Mobile: Recorder FAB ────────────────────────────────────────
  Widget _buildRecorderFAB() {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RecorderPage()),
        );
      },
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        height: 56,
        width: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.blueAccent, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.mic, color: Colors.white, size: 28),
      ),
    );
  }

  // ─── Mobile: Bottom Navigation ────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color:
            Theme.of(context).bottomAppBarTheme.color ??
            Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
          _buildNavItem(1, Icons.folder_outlined, Icons.folder, 'Projects'),
          const SizedBox(width: 48),
          _buildNavItem(2, Icons.note_outlined, Icons.analytics, 'Notes'),
          _buildNavItem(3, Icons.person_outline, Icons.person, 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade600,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade600,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
