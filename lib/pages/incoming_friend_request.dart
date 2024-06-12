import 'package:flutter/material.dart';

class IncomingRequestsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // This is a placeholder for the incoming friend requests data
    final List<Map<String, String>> incomingRequests = [
      {'name': 'burger 124', 'status': 'Incoming Friend Request'},
      {'name': 'burger 149', 'status': 'Incoming Friend Request'},
      {'name': 'burger 195', 'status': 'Incoming Friend Request'},
      {'name': 'burger 231', 'status': 'Incoming Friend Request'},
      {'name': 'burger 263', 'status': 'Incoming Friend Request'},
      {'name': 'burger 339', 'status': 'Incoming Friend Request'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Incoming Friend Requests'),
      ),
      body: incomingRequests.isEmpty
          ? Center(
              child: Text(
                'No incoming friend requests',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: incomingRequests.length,
              itemBuilder: (context, index) {
                final request = incomingRequests[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(
                        'https://via.placeholder.com/150'), // Placeholder image
                  ),
                  title: Text(request['name']!),
                  subtitle: Text(request['status']!),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () {
                          // Accept friend request logic
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.cancel, color: Colors.red),
                        onPressed: () {
                          // Decline friend request logic
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
