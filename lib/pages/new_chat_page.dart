import 'package:flutter/material.dart';

class NewChatPage extends StatelessWidget {
  const NewChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample data for contacts
    List<String> contacts = ["Alice", "Bob", "Charlie", "David"];

    return Scaffold(
      appBar: AppBar(
        title: Text('Select Contact'),
      ),
      body: ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(contacts[index]),
            onTap: () {
              // Handle contact selection
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
