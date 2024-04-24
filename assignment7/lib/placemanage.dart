import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ManagePlacesScreen extends StatefulWidget {
  const ManagePlacesScreen({Key? key}) : super(key: key);

  @override
  State<ManagePlacesScreen> createState() => _ManagePlacesScreenState();
}

class _ManagePlacesScreenState extends State<ManagePlacesScreen> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  late String currentDocumentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Manage Places',
          style: GoogleFonts.montserrat(
            fontSize: 20,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore.collection('favoritePlaces').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }

              List<DocumentSnapshot> placesDocs = snapshot.data!.docs;

              return ListView.builder(
                shrinkWrap: true,
                itemCount: placesDocs.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> data =
                      placesDocs[index].data() as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      title: Text(
                        data['name'],
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              showEditDialog(
                                placesDocs[index].id,
                                data['name'],
                                data['description'],
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              showDeleteConfirmation(placesDocs[index].id);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> deletePlace(String documentId) async {
    try {
      await firestore.collection('favoritePlaces').doc(documentId).delete();
    } catch (e) {
      print('Error deleting place: $e');
    }
  }

  void showEditDialog(
      String documentId, String currentName, String currentDescription) {
    currentDocumentId = documentId;
    nameController.text = currentName;
    descriptionController.text = currentDescription;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Edit Place',
            style: GoogleFonts.montserrat(
              fontSize: 20,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                editPlace();
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void showDeleteConfirmation(String documentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this place?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                deletePlace(documentId);
                Navigator.pop(context);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> editPlace() async {
    try {
      await firestore
          .collection('favoritePlaces')
          .doc(currentDocumentId)
          .update({
        'name': nameController.text,
        'description': descriptionController.text,
      });
    } catch (e) {
      print('Error editing place: $e');
    }
  }
}
