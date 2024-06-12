import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class NewGroupPage extends StatefulWidget {
  const NewGroupPage({super.key});

  @override
  _NewGroupPageState createState() => _NewGroupPageState();
}

class _NewGroupPageState extends State<NewGroupPage> {
  List<String> selectedContacts = [];
  TextEditingController groupNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Members'),
      ),
      body: ListView.builder(
        itemCount: 20, // Sample data for contacts
        itemBuilder: (context, index) {
          String contact = 'Contact $index';
          return CheckboxListTile(
            title: Text(contact),
            value: selectedContacts.contains(contact),
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  selectedContacts.add(contact);
                } else {
                  selectedContacts.remove(contact);
                }
              });
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (selectedContacts.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupDetailsPage(
                  selectedContacts: selectedContacts,
                ),
              ),
            );
          } else {
            Fluttertoast.showToast(msg: "Please select at least one contact.");
          }
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(Icons.arrow_forward, color: Colors.white),
      ),
    );
  }
}

class GroupDetailsPage extends StatefulWidget {
  final List<String> selectedContacts;
  GroupDetailsPage({required this.selectedContacts, super.key});

  @override
  _GroupDetailsPageState createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  TextEditingController groupNameController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    } else {
      Fluttertoast.showToast(msg: "No image selected.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage:
                          _imageFile != null ? FileImage(_imageFile!) : null,
                      child: _imageFile == null
                          ? Icon(Icons.camera_alt, size: 40)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: Colors.blue,
                          child:
                              Icon(Icons.edit, size: 15, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 20),
                Expanded(
                  child: TextField(
                    controller: groupNameController,
                    decoration: InputDecoration(
                      labelText: 'Group Name',
                      hintText: 'Enter group name',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Members: ${widget.selectedContacts.length + 1}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ListTile(
              title: Text('You'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.selectedContacts.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(widget.selectedContacts[index]),
                  );
                },
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () {
                  // Handle group creation
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text('Create Group'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
