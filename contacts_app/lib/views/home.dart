import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_app/controllers/auth_services.dart';
import 'package:contacts_app/controllers/crud_services.dart';
import 'package:contacts_app/views/update_contact.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  late Stream<QuerySnapshot> _stream;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchfocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _stream = CRUDService().getContacts();
  }

  @override
  void dispose() {
    _searchfocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void callUser(String? phone) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phone number is invalid")),
      );
      return;
    }

    final Uri url = Uri.parse("tel:$phone");
if (await canLaunchUrl(url)) {
  await launchUrl(
    url,
    mode: LaunchMode.externalApplication,
  );
} else {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Could not launch call to $phone")),
    );
  }
}

  }

  void searchContacts(String search) {
    setState(() {
      _stream = CRUDService().getContacts(searchQuery: search);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contacts"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * .9,
              child: TextFormField(
                controller: _searchController,
                focusNode: _searchfocusNode,
                onChanged: (value) => searchContacts(value),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  label: const Text("Search"),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            _searchfocusNode.unfocus();
                            setState(() {
                              _stream = CRUDService().getContacts();
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, "/add");
        },
        child: const Icon(Icons.person_add),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    maxRadius: 32,
                    child: Text(
                      FirebaseAuth.instance.currentUser?.email
                              ?.substring(0, 1)
                              .toUpperCase() ??
                          "U",
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(FirebaseAuth.instance.currentUser?.email ?? "Unknown User"),
                ],
              ),
            ),
            ListTile(
              onTap: () {
                AuthService().logout();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Logged Out")),
                );
                Navigator.pushReplacementNamed(context, "/login");
              },
              leading: const Icon(Icons.logout_outlined),
              title: const Text("Logout"),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Something Went Wrong"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No Contacts Found ..."));
          }

          return ListView(
            children: snapshot.data!.docs.map((document) {
              final Map<String, dynamic> data =
                  document.data()! as Map<String, dynamic>;

              return ListTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UpdateContact(
                      name: data["name"] ?? "No Name",
                      phone: data["phone"] ?? "No Phone",
                      email: data["email"] ?? "",
                      docID: document.id,
                    ),
                  ),
                ),
                leading: CircleAvatar(
                  child: Text(
                    (data["name"]?.substring(0, 1) ?? "N").toUpperCase(),
                  ),
                ),
                title: Text(data["name"] ?? "No Name"),
                subtitle: Text(data["phone"] ?? "No Phone"),
                trailing: IconButton(
                  icon: const Icon(Icons.call),
                  onPressed: data["phone"] != null
                      ? () => callUser(data["phone"])
                      : null,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
