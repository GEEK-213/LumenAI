import 'package:app/models/calendar_event.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

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

  late final List<CalenderEvent> allEvents;
  @override
  void initState() {
    super.initState();

    allEvents = [
      CalenderEvent(
        id: "1",
        title: "cs class",
        date: DateTime.now(),
        type: "class",
      ),
      CalenderEvent(
        id: "2",
        title: "submit assignment",
        date: DateTime.now().add(const Duration(days: 2)),
        type: "deadline",
      ),
      CalenderEvent(
        id: "3",
        title: "mobile app notes uploaded",
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: "note",
      ),
      CalenderEvent(
        id: "4",
        title: "ecommerce class",
        date: DateTime.now(),
        type: "class",
      ),
    ];
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
      appBar: AppBar(title: Text("master calender page")),
      body: content(),
    );
  }

  Widget content() {
    final events = getEventsForDay(today);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Text(
            'Selected Day ${today.toString().split(" ")[0]}',
            style: const TextStyle(fontSize: 16),
          ),

          const SizedBox(height: 16),
          TableCalendar(
            locale: "en_US",
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            availableGestures: AvailableGestures.all,
            selectedDayPredicate: (day) => isSameDay(day, today),
            focusedDay: today,
            firstDay: DateTime.utc(2010, 01, 01),
            lastDay: DateTime.utc(2030, 01, 01),
            onDaySelected: _OnDaySelected,

            eventLoader: (day) {
              return getEventsForDay(day);
            },

            calendarStyle: const CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
          ),

          const SizedBox(height: 16),
          Expanded(
            child: events.isEmpty
                ? const Center(child: Text("No events for this day!"))
                : ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];

                      return Card(
                        child: ListTile(
                          leading: Icon(
                            event.type == "class"
                                ? Icons.school
                                : event.type == "deadline"
                                ? Icons.warning
                                : event.type == "note"
                                ? Icons.note
                                : Icons.mic,
                          ),
                          title: Text(event.title),
                          subtitle: Text(event.type),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
