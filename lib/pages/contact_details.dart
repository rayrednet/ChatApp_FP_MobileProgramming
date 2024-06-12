import 'package:flutter/material.dart';

class ContactDetailsPage extends StatelessWidget {
  final Map<String, String> contact;

  ContactDetailsPage({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.person, size: 50),
                  ),
                  SizedBox(height: 20),
                  Text(
                    contact['name']!,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    contact['status']!,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // Add your message action here
              },
              icon: Icon(Icons.message,
                  color: const Color.fromARGB(255, 11, 69, 117)),
              label: Text('Message',
                  style:
                      TextStyle(color: const Color.fromARGB(255, 21, 58, 88))),
            ),
            SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Block Contact'),
                            content: Text(
                                'Are you sure you want to block ${contact['name']}?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(); // Close the dialog
                                },
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Add block action here
                                  Navigator.of(context)
                                      .pop(); // Close the dialog
                                },
                                child: Text('Block'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    icon: Icon(Icons.block, color: Colors.red),
                    label: Text(
                      'Block ${contact['name']}',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      bool _blockContact = false;
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return AlertDialog(
                                title: Text('Report ${contact['name']}?'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'The last 5 messages from this contact will be forwarded to ChatterBox. If you block this contact and delete the chat, messages will only be removed from this device and your devices on the newer version of ChatterBox.\nThis contact will not be notified.',
                                    ),
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: _blockContact,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              _blockContact = value!;
                                            });
                                          },
                                        ),
                                        Text('Block contact and delete chat'),
                                      ],
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pop(); // Close the dialog
                                    },
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // Add report action here
                                      Navigator.of(context)
                                          .pop(); // Close the dialog
                                    },
                                    child: Text('Report'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                    icon: Icon(Icons.thumb_down, color: Colors.red),
                    label: Text(
                      'Report ${contact['name']}',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Delete Contact'),
                            content: Text(
                                'Are you sure you want to delete ${contact['name']}?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(); // Close the dialog
                                },
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Add delete action here
                                  Navigator.of(context)
                                      .pop(); // Close the dialog
                                },
                                child: Text('Delete'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    icon: Icon(Icons.delete, color: Colors.red),
                    label: Text(
                      'Delete ${contact['name']}',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
