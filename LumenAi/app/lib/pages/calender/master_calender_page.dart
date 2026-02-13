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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("master calender page")),
      body: content(),
    );
  }

  Widget content() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Text('Selected Day ' + today.toString().split(" ")[0]),
          Container(
            child: TableCalendar(
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
            ),
          ),
        ],
      ),
    );
  }
}
