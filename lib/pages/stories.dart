import 'package:flutter/material.dart';
import '../widgets/bottom_navbar.dart';

class StoriesPage extends StatefulWidget {
  @override
  _StoriesPageState createState() => _StoriesPageState();
}

class _StoriesPageState extends State<StoriesPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Stories')),
      body: Center(child: Text('Stories Page')),
    );
  }
}
