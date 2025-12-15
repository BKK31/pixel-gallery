import 'package:flutter/material.dart';

class ViewerScreen extends StatelessWidget {
  int index;
  ViewerScreen({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(index.toString(), style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

