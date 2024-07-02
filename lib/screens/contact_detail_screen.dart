import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';

class ContactDetailScreen extends StatelessWidget {
  final Contact contact;

  const ContactDetailScreen({Key? key, required this.contact}) : super(key: key);

  String? extractCategory(String displayName) {
    List<String> delimiters = ['-', '_'];
    for (var delimiter in delimiters) {
      if (displayName.contains(delimiter)) {
        return displayName.split(delimiter)[0];
      }
    }
    return null; // 카테고리 없을 때
  }

  List<String?> listEmailGenerator() {
    if (contact.phones!.length == 1) { // number of elements is 1
      return contact.phones?.map((item) => randomEmailGenerator(item.value, extractCategory(contact.displayName!))).toList() ?? [];
    } else { // number of elements is 2
      int count = 0;
      List<String> mails = ["@gmail.com", "@naver.com", "@hanmail.net"];
      List<String?> res = [];

      for (Item iter in contact.phones!) {
        if (count > 2) {
          res.add(null);
        } else {
          res.add("${iter.value}${mails[count]}");
        }
        count++;
      }
      return res;
    }
  }

  String? randomEmailGenerator(String? phnum, String? category) {
    String? para = category;
    int randGen = Random().nextInt(3);
    switch (para) {
      case "KAIST":
        return "$phnum@kaist.ac.kr";
      case "제주과고":
        return "$phnum@jjhs.hs.kr";
      default:
        switch (randGen) {
          case 0:
            return "$phnum@gmail.com";
          case 1:
            return "$phnum@naver.com";
          case 2:
            return "$phnum@hanmail.net";
        }
    }
    return null;
  }

  Future<void> _makePhoneCall(String? phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launch(launchUri.toString());
  }

  Future<void> _sendSMS(String? phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
    );
    await launch(launchUri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final contactMap = _contactToMap(contact);

    return Scaffold(
      appBar: AppBar(
        title: Text(contact.displayName ?? 'No Name'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(0), // 리스트뷰 자체의 패딩 제거
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero, // 리스트뷰 항목의 좌우 공백 제거
                itemCount: contactMap.length,
                itemBuilder: (context, index) {
                  final entry = contactMap.entries.elementAt(index);
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0), // 항목의 좌우 패딩 설정
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Flexible(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(entry.value.toString()),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                separatorBuilder: (context, index) => const Divider(), // 각 항목 사이에 구분선 추가
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _makePhoneCall(contact.phones?.first.value),
                    icon: Icon(Icons.call),
                    label: Text('Call'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _sendSMS(contact.phones?.first.value),
                    icon: Icon(Icons.message),
                    label: Text('Message'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _contactToMap(Contact contact) {
    return {
      'Name': contact.displayName,
      'Category': extractCategory(contact.displayName!),
      'Emails': listEmailGenerator(),
      'Phones': contact.phones?.map((item) => item.value).toList(),
      'Country': 'Korea',
    };
  }
}
