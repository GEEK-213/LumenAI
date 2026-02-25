import 'package:app/models/calendar_event.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/api_service.dart';

class MasterCalenderPage extends StatefulWidget {
  const MasterCalenderPage({super.key});

  @override
  State<MasterCalenderPage> createState() => _MasterCalenderPageState();
}

class _MasterCalenderPageState extends State<MasterCalenderPage> {
  DateTime today = DateTime.now();
  void _OnDaySelected(DateTime day, DateTime focusedDay) {
    setState(() {
      today = day;
    });
  }

  List<CalenderEvent> allEvents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final api = ApiService();
      final tasks = await api.getExtractedTasks(userId);

      final loadedEvents = <CalenderEvent>[];
      for (var t in tasks) {
        // Only map tasks that have an actual valid due_date
        if (t['due_date'] != null) {
          try {
            final date = DateTime.parse(t['due_date'].toString());
            loadedEvents.add(
              CalenderEvent(
                id: t['id'].toString(),
                title: t['title'] ?? 'Assignment',
                date: date,
                type: 'deadline',
              ),
            );
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          allEvents = loadedEvents;
        });
      }
    } catch (e) {
      print("Error loading events: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  List<CalenderEvent> getEventsForDay(DateTime day) {
    return allEvents
        .where(
          (event) =>
              event.date.year == day.year &&
              event.date.month == day.month &&
              event.date.day == day.day,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Master Calendar",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : content(),
    );
  }

  Widget content() {
    final events = getEventsForDay(today);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          Text("Selected Date", style: Theme.of(context).textTheme.labelMedium),

          const SizedBox(height: 4),

          Text(
            today.toString().split(" ")[0],
            style: Theme.of(context).textTheme.titleMedium,
          ),

          const SizedBox(height: 20),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: TableCalendar(
                locale: "en_US",
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                availableGestures: AvailableGestures.all,
                selectedDayPredicate: (day) => isSameDay(day, today),
                focusedDay: today,
                firstDay: DateTime.utc(DateTime.now().year - 1, 1, 1),
                lastDay: DateTime.utc(DateTime.now().year + 1, 12, 31),
                onDaySelected: _OnDaySelected,
                eventLoader: (day) => getEventsForDay(day),
                calendarStyle: const CalendarStyle(
                  markerDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text("Events", style: Theme.of(context).textTheme.titleLarge),

          const SizedBox(height: 12),

          Expanded(
            child: events.isEmpty
                ? const Center(child: Text("No events for this day"))
                : ListView.separated(
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return buildEventTile(event);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget buildEventTile(CalenderEvent event) {
    IconData icon;

    switch (event.type) {
      case "class":
        icon = Icons.school;
        break;
      case "deadline":
        icon = Icons.warning_amber_rounded;
        break;
      case "note":
        icon = Icons.note_alt_outlined;
        break;
      case "recording":
        icon = Icons.mic;
        break;
      default:
        icon = Icons.event;
    }

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: const Color(0xFF1E2746),
            title: Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.type.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: Text(
              event.title,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Close"),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.type.toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
