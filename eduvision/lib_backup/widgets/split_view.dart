import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class SplitView extends StatefulWidget {
  final Widget iosView;
  final Widget androidView;
  
  const SplitView({
    Key? key,
    required this.iosView,
    required this.androidView,
  }) : super(key: key);

  @override
  State<SplitView> createState() => _SplitViewState();
}

class _SplitViewState extends State<SplitView> {
  bool _isVertical = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EduVision Preview'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isVertical ? Icons.view_agenda : Icons.view_sidebar),
            onPressed: () {
              setState(() {
                _isVertical = !_isVertical;
              });
            },
            tooltip: 'Thay đổi hướng hiển thị',
          ),
        ],
      ),
      body: _isVertical 
        ? _buildVerticalLayout()
        : _buildHorizontalLayout(),
    );
  }

  Widget _buildHorizontalLayout() {
    return Row(
      children: [
        // iOS View
        Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.blue.withOpacity(0.2),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.apple, color: Colors.black87),
                    SizedBox(width: 8),
                    Text(
                      'iOS Version',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: widget.iosView,
              ),
            ],
          ),
        ),
        // Divider
        Container(
          width: 2,
          color: Colors.grey.shade300,
        ),
        // Android View
        Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.green.withOpacity(0.2),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.android, color: Colors.black87),
                    SizedBox(width: 8),
                    Text(
                      'Android Version',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: widget.androidView,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalLayout() {
    return Column(
      children: [
        // iOS View
        Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.blue.withOpacity(0.2),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.apple, color: Colors.black87),
                    SizedBox(width: 8),
                    Text(
                      'iOS Version',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: widget.iosView,
              ),
            ],
          ),
        ),
        // Divider
        Container(
          height: 2,
          color: Colors.grey.shade300,
        ),
        // Android View
        Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.green.withOpacity(0.2),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.android, color: Colors.black87),
                    SizedBox(width: 8),
                    Text(
                      'Android Version',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: widget.androidView,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
