import 'package:flutter/material.dart';

class Tab1Screen extends StatelessWidget {
  const Tab1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'This is Tab 1',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}