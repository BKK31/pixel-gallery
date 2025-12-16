import 'package:flutter/material.dart';

class ViewerScreen extends StatefulWidget {
  final int index;
  const ViewerScreen({super.key, required this.index});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  late PageController _controller;
  int _currentIndex = 0;
  bool _showUI = true;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _showUI = !_showUI;
              });
            },
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: 100,
              itemBuilder: (context, index) {
                return Container(
                  color: Colors.black,
                  child: Center(
                    child: Text(
                      (index + 1).toString(),
                      style: TextStyle(color: Colors.white, fontSize: 32),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_showUI)
            Align(
              alignment: Alignment.topRight,
              child: Container(
                margin: EdgeInsets.only(right: 20, top: 50),
                width: 50,
                height: 50,
                color: Colors.amber[50],
                child: Center(
                  child: Text(
                    (_currentIndex + 1).toString(),
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
