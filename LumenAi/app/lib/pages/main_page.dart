import 'package:app/pages/calender/master_calender_page.dart';
import 'package:flutter/material.dart';
import 'notes_page.dart';
import 'input_type_page.dart';
import 'homePage.dart';
import 'profilePage.dart';
import 'recorder.dart'; 

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

    List<Widget> get _pages => [
    const HomePage(),
    MasterCalenderPage(), // Placeholder just for current use**
    NotesPage(classes : _classes, onClassTap: _openAudioInput),
    const Profilepage(),  
  ];

  final List<String> _classes = [];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1223),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      floatingActionButton: _selectedIndex == 2
    ? FloatingActionButton(
        onPressed:  _showAddClassDialog,
        child: const Icon(Icons.add),
      )
    : FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FlashCardPage()),
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
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        height: 80,
        decoration: const BoxDecoration(
          color: Color(0xFF050B18),
          border: Border(top: BorderSide(color: Color(0xFF1E2746))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_outlined, Icons.home, "Home"),
            _buildNavItem(1, Icons.folder_outlined, Icons.folder, "Projects"),
            const SizedBox(width: 48), 
            _buildNavItem(2, Icons.note_outlined, Icons.analytics, "Notes"),
            _buildNavItem(3, Icons.person_outline, Icons.person, "Profile"),
          ],
        ),
      ),
    );
  }

  void _openAudioInput(String className) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => InputTypePage(className: className),
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
            color: isSelected ? Colors.blueAccent : Colors.grey.shade600,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blueAccent : Colors.grey.shade600,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
  void _showAddClassDialog() {
  final controller = TextEditingController();

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Add Class"),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: "Enter class name",
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            _addClass(controller.text);
            Navigator.pop(context);
          },
          child: const Text("Add"),
        ),
      ],
    ),
  );
}

void _addClass(String name){
   if (name.trim().isEmpty) return;

  setState(() {
    _classes.add(name.trim());
  });
}

}
