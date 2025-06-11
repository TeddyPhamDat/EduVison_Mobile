import 'package:flutter/cupertino.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Simple Test',
      home: CupertinoPageScaffold(
        child: Center(
          child: Text('Hello EduVision!'),
        ),
      ),
    );
  }
}
