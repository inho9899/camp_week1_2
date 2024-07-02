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
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search Contacts...',
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
        )
            : const Text('Contacts'),
        actions: _isSearching
            ? [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _stopSearch,
          ),
        ]
            : [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _startSearch,
          ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade200, // 전체 배경색 설정
        child: _buildBody(),
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
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.0), // 둥근 모서리 설정
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3), // 그림자 위치 조정
                    ),
                  ],
                ),
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
