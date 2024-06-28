import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class Tab2Screen extends StatefulWidget {
  const Tab2Screen({super.key});

  @override
  _Tab2ScreenState createState() => _Tab2ScreenState();
}

class _Tab2ScreenState extends State<Tab2Screen> with AutomaticKeepAliveClientMixin {
  final ImagePicker _picker = ImagePicker();
  List<File> _images = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final directory = await getApplicationDocumentsDirectory();
      final String path = directory.path;
      final File newImage = await File(image.path).copy('$path/${DateTime.now().millisecondsSinceEpoch}.png');
      setState(() {
        _images.add(newImage);
      });
      _saveImages();
    }
  }

  Future<void> _deleteImage(int index) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('이미지 삭제'),
          content: const Text('이 이미지를 삭제하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('아니요'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _images[index].delete();
                  _images.removeAt(index);
                });
                Navigator.of(context).pop();
                _saveImages();
              },
              child: const Text('예'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showImage(BuildContext context, File image) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: InteractiveViewer(
              child: Image.file(image),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveImages() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> paths = _images.map((file) => file.path).toList();
    await prefs.setStringList('images', paths);
  }

  Future<void> _loadImages() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? paths = prefs.getStringList('images');
    if (paths != null) {
      setState(() {
        _images = paths.map((path) => File(path)).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.0,  // 1:1 비율
              ),
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _showImage(context, _images[index]);
                  },
                  onLongPress: () {
                    _deleteImage(index);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Image.file(
                      _images[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        child: const Icon(Icons.add),
        tooltip: '이미지 추가',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
