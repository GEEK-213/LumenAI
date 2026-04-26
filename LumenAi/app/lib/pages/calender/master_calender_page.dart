import 'package:app/models/calendar_event.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/api_service.dart';
import '../../theme/crimson_helpers.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final isCrimson = CrimsonHelpers.isCrimson(context);
    return Scaffold(
      backgroundColor: isCrimson ? CrimsonHelpers.crimsonBg : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isCrimson ? Colors.black : null,
        elevation: 0,
        title: isCrimson
            ? CrimsonHelpers.appBarTitle("CHRONO_LOG", "Master Calendar")
            : const Text(
                "Master Calendar",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: isCrimson ? CrimsonHelpers.crimsonRed : null))
          : content(),
    );
  }

  Widget content() {
    final events = getEventsForDay(today);

    final isCrimson = CrimsonHelpers.isCrimson(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          Text(
            isCrimson ? "SELECTED_ORBIT" : "Selected Date",
            style: isCrimson ? GoogleFonts.shareTechMono(color: CrimsonHelpers.crimsonRed, fontSize: 11) : Theme.of(context).textTheme.labelMedium,
          ),

          const SizedBox(height: 4),

          Text(
            today.toString().split(" ")[0],
            style: isCrimson ? GoogleFonts.shareTechMono(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold) : Theme.of(context).textTheme.titleMedium,
          ),

          const SizedBox(height: 20),

          Card(
            elevation: isCrimson ? 0 : 2,
            color: isCrimson ? Colors.black : null,
            shape: RoundedRectangleBorder(
              borderRadius: isCrimson ? BorderRadius.zero : BorderRadius.circular(16),
              side: isCrimson ? BorderSide(color: CrimsonHelpers.crimsonBorder) : BorderSide.none,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: TableCalendar(
                locale: "en_US",
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: isCrimson ? GoogleFonts.shareTechMono(color: Colors.white, fontWeight: FontWeight.bold) : const TextStyle(color: Colors.black),
                ),
                availableGestures: AvailableGestures.all,
                selectedDayPredicate: (day) => isSameDay(day, today),
                focusedDay: today,
                firstDay: DateTime.utc(DateTime.now().year - 1, 1, 1),
                lastDay: DateTime.utc(DateTime.now().year + 1, 12, 31),
                onDaySelected: _OnDaySelected,
                eventLoader: (day) => getEventsForDay(day),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: isCrimson ? GoogleFonts.shareTechMono(color: Colors.white70) : const TextStyle(color: Colors.black),
                  weekendStyle: isCrimson ? GoogleFonts.shareTechMono(color: CrimsonHelpers.crimsonRed) : const TextStyle(color: Colors.red),
                ),
                calendarStyle: CalendarStyle(
                  markerDecoration: BoxDecoration(
                    color: isCrimson ? CrimsonHelpers.crimsonRed : Colors.blue,
                    shape: isCrimson ? BoxShape.rectangle : BoxShape.circle,
                  ),
                  defaultTextStyle: isCrimson ? GoogleFonts.shareTechMono(color: Colors.white) : const TextStyle(color: Colors.black),
                  weekendTextStyle: isCrimson ? GoogleFonts.shareTechMono(color: CrimsonHelpers.crimsonRed) : const TextStyle(color: Colors.red),
                  selectedDecoration: BoxDecoration(
                    color: isCrimson ? CrimsonHelpers.crimsonRed : Colors.blue,
                    shape: isCrimson ? BoxShape.rectangle : BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: isCrimson ? CrimsonHelpers.crimsonRed.withOpacity(0.3) : Colors.blue.withOpacity(0.3),
                    shape: isCrimson ? BoxShape.rectangle : BoxShape.circle,
                    border: isCrimson ? Border.all(color: CrimsonHelpers.crimsonRed) : null,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          isCrimson ? CrimsonHelpers.sectionHeading("Events") : Text("Events", style: Theme.of(context).textTheme.titleLarge),

          const SizedBox(height: 12),

          Expanded(
            child: events.isEmpty
                ? Center(
                    child: Text(
                      isCrimson ? "//NO_LOGS_FOUND//" : "No events for this day",
                      style: isCrimson ? GoogleFonts.shareTechMono(color: Colors.white38) : null,
                    ),
                  )
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

    final isCrimson = CrimsonHelpers.isCrimson(context);
    final accentColor = isCrimson ? CrimsonHelpers.crimsonRed : Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: isCrimson ? Colors.black : const Color(0xFF1E2746),
            shape: isCrimson ? const BeveledRectangleBorder(side: BorderSide(color: Colors.white54)) : null,
            title: Row(
              children: [
                Icon(icon, color: accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isCrimson ? "[${event.type.toUpperCase()}]" : event.type.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: isCrimson ? 'ShareTechMono' : null,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              event.title,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontFamily: isCrimson ? 'ShareTechMono' : null,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  "CLOSE",
                  style: TextStyle(
                    color: accentColor,
                    fontFamily: isCrimson ? 'ShareTechMono' : null,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: isCrimson ? BorderRadius.zero : BorderRadius.circular(16),
          color: isCrimson ? CrimsonHelpers.crimsonCard : Theme.of(context).colorScheme.surface,
          border: isCrimson ? Border.all(color: CrimsonHelpers.crimsonBorder) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: accentColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCrimson ? event.title.toUpperCase() : event.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: isCrimson ? 'ShareTechMono' : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCrimson ? "//TYPE_ID::${event.type.toUpperCase()}" : event.type.toUpperCase(),
                    style: TextStyle(
                      color: isCrimson 
                          ? Colors.white54 
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 12,
                      fontFamily: isCrimson ? 'ShareTechMono' : null,
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
