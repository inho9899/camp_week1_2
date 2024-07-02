import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';
import 'calendar_screen.dart';

class Tab3Screen extends StatefulWidget {
  const Tab3Screen({super.key});

  @override
  _Tab3ScreenState createState() => _Tab3ScreenState();
}

class _Tab3ScreenState extends State<Tab3Screen> {
  List<Dday> _ddayList = [];

  @override
  void initState() {
    super.initState();
    _loadDdays();
  }

  Future<void> _pickDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final TextEditingController _textController = TextEditingController();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('디데이 내용 입력'),
            content: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: '내용을 입력하세요',
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    Dday newDday = Dday(
                      date: pickedDate,
                      description: _textController.text,
                    );
                    _ddayList.add(newDday);
                    _scheduleNotification(newDday);
                    _saveDdays();
                    _checkAndShowImmediateNotification(newDday);
                    _removeExpiredDdays(); // 새로 추가된 부분
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('추가'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _saveDdays() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> ddayStrings = _ddayList.map((dday) => '${dday.date.toIso8601String()},${dday.description}').toList();
    prefs.setStringList('ddays', ddayStrings);
  }

  Future<void> _loadDdays() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? ddayStrings = prefs.getStringList('ddays');
    if (ddayStrings != null) {
      setState(() {
        _ddayList = ddayStrings.map((str) {
          List<String> parts = str.split(',');
          return Dday(
            date: DateTime.parse(parts[0]),
            description: parts.sublist(1).join(','),
          );
        }).toList();
      });
      _removeExpiredDdays(); // 화면 초기화 시 만료된 디데이 제거
    }
  }

  String _formatDate(DateTime date) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(date);
  }

  int _calculateDaysRemaining(DateTime selectedDate) {
    final now = DateTime.now();
    return selectedDate.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  Future<void> _deleteDday(int index) async {
    bool? confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('디데이 삭제'),
          content: const Text('이 디데이를 삭제하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('아니요'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _ddayList.removeAt(index);
                  _saveDdays();
                });
                Navigator.of(context).pop(true);
              },
              child: const Text('예'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      // 알림 취소 기능은 이곳에 추가해야 합니다.
    }
  }

  Future<void> _scheduleNotification(Dday dday) async {
    await _scheduleSpecificNotification(dday, Duration(days: 3), "${dday.description} 마감일 3일 전입니다!");
    await _scheduleSpecificNotification(dday, Duration(days: 1), "${dday.description} 마감일 하루 전입니다!");
  }

  Future<void> _scheduleSpecificNotification(Dday dday, Duration duration, String message) async {
    DateTime scheduledNotificationDateTime = dday.date.subtract(duration);
    scheduledNotificationDateTime = DateTime(
      scheduledNotificationDateTime.year,
      scheduledNotificationDateTime.month,
      scheduledNotificationDateTime.day,
      9, // 알림을 보낼 시간 설정 (오전 9시로 설정)
    );

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'high_importance_channel', // 알림 채널 ID
      '중요한 알림',
      channelDescription: '중요한 알림을 위한 채널입니다.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.schedule(
      0,
      '과제 알리미',
      message,
      scheduledNotificationDateTime,
      platformChannelSpecifics,
    );
    print('Scheduled notification: $message at $scheduledNotificationDateTime');
  }

  Future<void> _checkAndShowImmediateNotification(Dday dday) async {
    final now = DateTime.now();
    final daysRemaining = dday.date.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (daysRemaining == 3) {
      await _showNotification("${dday.description} 마감 3일 전입니다!");
    } else if (daysRemaining == 1) {
      await _showNotification("${dday.description} 마감 하루 전입니다! 서둘러 과제를 완료하세요!");
    }
  }

  Future<void> _showNotification(String message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'high_importance_channel', // 알림 채널 ID
      '중요한 알림',
      channelDescription: '중요한 알림을 위한 채널입니다.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      '과제 알리미',
      message,
      platformChannelSpecifics,
    );
  }

  void _removeExpiredDdays() {
    final now = DateTime.now();
    setState(() {
      _ddayList.removeWhere((dday) => dday.date.isBefore(DateTime(now.year, now.month, now.day)));
    });
    _saveDdays();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CalendarScreen(ddayList: _ddayList),
                        ),
                      );
                    },
                    child: Icon(
                      Icons.event_note,
                      color: Color(0xFF212A3E),
                      size: 24.0,
                    ),
                  ),
                  SizedBox(width: 8.0),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CalendarScreen(ddayList: _ddayList),
                        ),
                      );
                    },
                    child: Text(
                      '과제 캘린더',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212A3E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: Scrollbar(
                child: ListView.builder(
                  itemCount: _ddayList.length,
                  itemBuilder: (context, index) {
                    Dday dday = _ddayList[index];
                    return GestureDetector(
                      onLongPress: () => _deleteDday(index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white, // 흰색 배경
                          border: Border.all(color: Colors.black, width: 1.0), // 검정색 테두리
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_today, color: Colors.black, size: 24.0),
                                SizedBox(width: 8.0),
                                Text(
                                  'D-${_calculateDaysRemaining(dday.date)}: ${_formatDate(dday.date)}',
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.0),
                            Text(dday.description),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pickDate(context),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class Dday {
  final DateTime date;
  final String description;

  Dday({required this.date, required this.description});
}
