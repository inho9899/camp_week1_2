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
  bool _isSearching = false;

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

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _filteredContacts = _contacts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200, // 전체 배경색 설정
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  Icons.contacts,
                  color: Color(0xFF212A3E),
                  size: 24.0,
                ),
                SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    '연락처',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212A3E),
                    ),
                  ),
                ),
                if (_isSearching)
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search Contacts...',
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(color: Colors.black, fontSize: 18),
                    ),
                  ),
                IconButton(
                  icon: Icon(_isSearching ? Icons.clear : Icons.search),
                  onPressed: _isSearching ? _stopSearch : _startSearch,
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.grey.shade200, // 전체 배경색 설정
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            '연락처 (${_filteredContacts.length} Found)',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Expanded(
          child: _buildListView(),
        ),
      ],
    );
  }

  Widget _buildListView() {
    if (_filteredContacts.isEmpty) {
      if (_searchController.text.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      } else {
        return const Center(child: Text('Not Found', style: TextStyle(fontSize: 24)));
      }
    } else {
      return Scrollbar(
        child: ListView.builder(
          itemCount: _filteredContacts.length,
          itemBuilder: (context, index) {
            final contact = _filteredContacts[index];
            final phone = (contact.phones != null && contact.phones!.isNotEmpty)
                ? contact.phones!.first.value
                : 'No phone number';
            return Container(
              color: index % 2 == 0 ? Colors.white : Colors.grey[300],
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 16.0),
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
              ),
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterContacts);
    _searchController.dispose();
    super.dispose();
  }
}
