import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'tab3_screen.dart';

class CalendarScreen extends StatefulWidget {
  final List<Dday> ddayList;

  const CalendarScreen({Key? key, required this.ddayList}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  List<Dday> _selectedDdayList = [];

  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.month;
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _selectedDdayList = _getDdaysForDate(_selectedDay);
  }

  List<Dday> _getDdaysForDate(DateTime date) {
    return widget.ddayList.where((dday) => isSameDay(dday.date, date)).toList();
  }

  int _calculateDaysRemaining(DateTime selectedDate) {
    final now = DateTime.now();
    return selectedDate.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('과제 캘린더'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2000),
            lastDay: DateTime(2101),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _selectedDdayList = _getDdaysForDate(selectedDay);
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
            ),
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            eventLoader: (day) {
              return _getDdaysForDate(day);
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _selectedDdayList.length,
              itemBuilder: (context, index) {
                Dday dday = _selectedDdayList[index];
                int daysRemaining = _calculateDaysRemaining(dday.date);
                return ListTile(
                  title: Text(dday.description),
                  subtitle: Text('D-$daysRemaining (${DateFormat('yyyy-MM-dd').format(dday.date)})'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
