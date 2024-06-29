import 'dart:convert'; // JSON 변환을 위해 추가
import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'dart:math';

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

  String? random_email_generator(String? phnum, String? category){
    String? para = category;
    int rand_gen = Random().nextInt(3);
    switch(para){
      case "KAIST" :
        return "${phnum}@kaist.ac.kr";
        break;
      case "제주과고" :
        return "${phnum}@jjhs.hs.kr";
        break;
      default :
        switch(rand_gen){
          case 0 :
            return "${phnum}@gmail.com";
            break;
          case 1 :
            return "${phnum}@naver.com";
            break;
          case 2 :
            return "${phnum}@hanmail.net";
            break;
        }
        break;
    }

  }

  List <String?> list_email_generator(){
    // To avoid redundancy
    if(contact.phones!.length== 1){ // number of element is 1
      List <String?> res = (contact.phones?.map((item) => random_email_generator(item.value, extractCategory(contact.displayName!))).toList())!;
      return res;
    }
    else{ // number of element is 2
      int count = 0;
      List <String> mails = ["@gmail.com", "@naver.com", "@hanmail.net"];
      List <String?> res = [];
      // Map my_map = {};

      for(Item iter in contact.phones!){

        if(count > 2){
          res.add(null);
        }
        else{
          res.add("${iter.value}${mails[count]}");
        }

        count++;
      }

      return res;
    }

  }



  @override
  Widget build(BuildContext context) {
    final contactMap = _contactToMap(contact);

    return Scaffold(
      appBar: AppBar(
        title: Text(contact.displayName ?? 'No Name'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: contactMap.entries.map((entry) {
            return ListTile(
              title: Text(entry.key),
              subtitle: Text(entry.value.toString()),
            );
          }).toList(),
        ),
      ),
    );
  }

  Map<String, dynamic> _contactToMap(Contact contact) {
    return {
      'Name': contact.displayName,
      'Category' : extractCategory(contact.displayName!) ,
      'emails': list_email_generator(),
      'phones': contact.phones?.map((item) => item.value).toList(),
      'country' : 'Korea',
    };
  }
}