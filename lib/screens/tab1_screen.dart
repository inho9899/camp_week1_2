import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'contact_detail_screen.dart';

class Tab1Screen extends StatefulWidget {
  const Tab1Screen({Key? key}) : super(key: key);

  @override
  _Tab1ScreenState createState() => _Tab1ScreenState();
}

class _Tab1ScreenState extends State<Tab1Screen> {
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getPermissions();
    _searchController.addListener(_filterContacts);
  }

  Future<void> _getPermissions() async {
    if (await Permission.contacts.request().isGranted) {
      _getContacts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission to access contacts was denied')),
      );
    }
  }

  Future<void> _getContacts() async {
    try {
      final contacts = await ContactsService.getContacts();
      setState(() {
        _contacts = contacts.toList();
        _filteredContacts = _contacts;
      });
    } catch (e) {
      print(e.toString());
    }
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = _contacts.where((contact) {
        final name = contact.displayName?.toLowerCase() ?? '';
        return name.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Contacts'),
            Text('Total Contacts: ${_contacts.length}'),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search Contacts...',
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
          ),
        ),
      ),
      body: _buildContactList(),
    );
  }

  Widget _buildContactList() {
    if (_filteredContacts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: _filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        final phone = (contact.phones != null && contact.phones!.isNotEmpty)
            ? contact.phones!.first.value
            : 'No phone number';
        return ListTile(
          title: Text(contact.displayName ?? 'No Name'),
          subtitle: Text(phone ?? 'No phone number'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ContactDetailScreen(contact: contact),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterContacts);
    _searchController.dispose();
    super.dispose();
  }
}