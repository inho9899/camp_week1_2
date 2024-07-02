import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';

class Tab2Screen extends StatefulWidget {
  const Tab2Screen({super.key});

  @override
  _Tab2ScreenState createState() => _Tab2ScreenState();
}

class _Tab2ScreenState extends State<Tab2Screen> with AutomaticKeepAliveClientMixin {
  final ImagePicker _picker = ImagePicker();
  List<ImageItem> _images = [];
  List<ImageItem> _trashImages = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? paths = prefs.getStringList('images');
    final List<String>? trashPaths = prefs.getStringList('trashImages');
    if (paths != null) {
      setState(() {
        _images = paths.map((path) => ImageItem.fromJson(path)).toList();
      });
    }
    if (trashPaths != null) {
      setState(() {
        _trashImages = trashPaths.map((path) => ImageItem.fromJson(path)).toList();
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      final directory = await getApplicationDocumentsDirectory();
      final String path = directory.path;
      final File newImage = await File(image.path).copy('$path/${DateTime.now().millisecondsSinceEpoch}.png');
      setState(() {
        _images.add(ImageItem(file: newImage, isFavorite: false));
      });
      _saveImages();
    }
  }

  Future<void> _saveImages() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> paths = _images.map((image) => image.toJson()).toList();
    final List<String> trashPaths = _trashImages.map((image) => image.toJson()).toList();
    prefs.setStringList('images', paths);
    prefs.setStringList('trashImages', trashPaths);
  }

  Future<void> _deleteImage(int index) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('이미지 삭제'),
          content: const Text('이 이미지를 휴지통으로 이동하시겠습니까?'),
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
                  _trashImages.add(_images[index]);
                  _images.removeAt(index);
                });
                _saveImages();
                Navigator.of(context).pop();
              },
              child: const Text('예'),
            ),
          ],
        );
      },
    );
  }

  void _showImageViewer(BuildContext context, List<ImageItem> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewer(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _showPickOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('이미지 선택'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('갤러리에서 선택'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('카메라로 찍기'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleFavorite(int index) {
    setState(() {
      _images[index].isFavorite = !_images[index].isFavorite;
    });
    _saveImages();
  }

  Future<void> _emptyTrash() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('휴지통 비우기'),
          content: const Text('휴지통을 비우시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
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
                  for (var image in _trashImages) {
                    image.file.delete();
                  }
                  _trashImages.clear();
                });
                _saveImages();
                Navigator.of(context).pop();
              },
              child: const Text('예'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _restoreImage(int index) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('이미지 복원'),
          content: const Text('이 이미지를 복원하시겠습니까?'),
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
                  _images.add(_trashImages[index]);
                  _trashImages.removeAt(index);
                });
                _saveImages();
                Navigator.of(context).pop();
              },
              child: const Text('예'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _unfavoriteImage(int index, bool isFavoriteTab) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('즐겨찾기 취소'),
          content: const Text('이 이미지를 즐겨찾기에서 취소하시겠습니까?'),
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
                  if (isFavoriteTab) {
                    int originalIndex = _images.indexOf(_images.where((image) => image.isFavorite).toList()[index]);
                    _images[originalIndex].isFavorite = false;
                  } else {
                    _images[index].isFavorite = false;
                  }
                });
                _saveImages();
                Navigator.of(context).pop();
              },
              child: const Text('예'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.photo,
                    color: Color(0xFF212A3E),
                    size: 24.0,
                  ),
                  SizedBox(width: 8.0),
                  Text(
                    '갤러리',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212A3E),
                    ),
                  ),
                ],
              ),
            ),
            const TabBar(
              tabs: [
                Tab(text: '전체'),
                Tab(text: '즐겨찾기'),
                Tab(text: '휴지통'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildGridView(_images),
                  _buildGridView(_images.where((image) => image.isFavorite).toList(), isFavoriteTab: true),
                  _buildTrashView(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildGridView(List<ImageItem> images, {bool isFavoriteTab = false}) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0, // 1:1 비율
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            _showImageViewer(context, images, index);
          },
          onLongPress: () {
            if (isFavoriteTab) {
              _unfavoriteImage(index, true);
            } else {
              _deleteImage(index);
            }
          },
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.file(
                  images[index].file,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              if (!isFavoriteTab)
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: Icon(
                      images[index].isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: images[index].isFavorite ? Colors.red : Colors.white,
                    ),
                    onPressed: () {
                      _toggleFavorite(index);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrashView() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0, // 1:1 비율
      ),
      itemCount: _trashImages.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onLongPress: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('이미지 삭제'),
                  content: const Text('이 이미지를 영구 삭제하시겠습니까?'),
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
                          _trashImages[index].file.delete();
                          _trashImages.removeAt(index);
                        });
                        _saveImages();
                        Navigator.of(context).pop();
                      },
                      child: const Text('예'),
                    ),
                  ],
                );
              },
            );
          },
          onTap: () {
            _restoreImage(index);
          },
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Image.file(
              _trashImages[index].file,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return Builder(
      builder: (context) {
        final TabController? tabController = DefaultTabController.of(context);
        return AnimatedBuilder(
          animation: tabController!,
          builder: (context, _) {
            if (tabController.index == 0) {
              return FloatingActionButton(
                onPressed: () => _showPickOptionsDialog(context),
                child: const Icon(Icons.add),
              );
            } else if (tabController.index == 2) {
              return FloatingActionButton(
                onPressed: () => _emptyTrash(),
                child: const Icon(Icons.delete),
              );
            }
            return SizedBox.shrink(); // 다른 탭에서는 빈 공간을 반환
          },
        );
      },
    );
  }
}

class ImageViewer extends StatelessWidget {
  final List<ImageItem> images;
  final int initialIndex;

  const ImageViewer({Key? key, required this.images, required this.initialIndex}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            panEnabled: true, // 확대 및 축소 시 패닝 가능
            scaleEnabled: true, // 확대 및 축소 가능
            minScale: 1.0,
            maxScale: 4.0,
            child: Image.file(
              images[index].file,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          );
        },
      ),
    );
  }
}

class ImageItem {
  final File file;
  bool isFavorite;

  ImageItem({required this.file, required this.isFavorite});

  String toJson() {
    return '{"path":"${file.path}","isFavorite":$isFavorite}';
  }

  factory ImageItem.fromJson(String json) {
    final Map<String, dynamic> data = jsonDecode(json);
    return ImageItem(
      file: File(data['path']),
      isFavorite: data['isFavorite'],
    );
  }
}
