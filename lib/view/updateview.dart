import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class Updateview extends StatefulWidget {
  const Updateview({super.key});

  @override
  State<Updateview> createState() => _UpdateviewState();
}

class _UpdateviewState extends State<Updateview> {
  static const String _baseUrl = 'http://192.168.20.52:8000';
  static const int _imageCount = 3;

  final TextEditingController contentController = TextEditingController();

  late final int seq;
  late final String insertdate;
  late final FixedExtentScrollController imagePickerController;
  late int selectedImageSeq;
  late String selectedImageUrl;
  bool isSaving = false;

  /// 기존 Todo와 연결된 이미지 번호로 미리보기와 Picker 위치를 초기화한다.
  @override
  void initState() {
    super.initState();
    final arguments = Map<String, dynamic>.from(Get.arguments as Map);
    seq = arguments['seq'] as int;
    contentController.text = arguments['content']?.toString() ?? '';
    insertdate = arguments['insertdate'].toString().substring(0, 10);

    final initialImageSeq =
        int.tryParse(arguments['image_seq']?.toString() ?? '') ?? 1;
    selectedImageSeq = initialImageSeq.clamp(1, _imageCount);
    selectedImageUrl = '$_baseUrl/todos/image/$selectedImageSeq';
    imagePickerController = FixedExtentScrollController(
      initialItem: selectedImageSeq - 1,
    );
  }

  /// 기존 Todo의 내용과 선택된 이미지 연결을 PUT 요청으로 수정한다.
  Future<void> updateTodo() async {
    final content = contentController.text.trim();
    if (content.isEmpty) {
      Get.snackbar('입력 확인', '목록을 입력하세요.');
      return;
    }

    setState(() => isSaving = true);

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/todos/$seq'),
        body: {
          'content': content,
          'insertdate': insertdate,
          'image_seq': selectedImageSeq.toString(),
        },
      );
      if (response.statusCode == 200) {
        Get.back(result: true);
        return;
      }

      Get.snackbar('수정 실패', 'Todo를 수정하지 못했습니다.');
    } catch (error) {
      Get.snackbar('수정 실패', error.toString());
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    imagePickerController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: const Text('Update View'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Image.network(selectedImageUrl, height: 120)),
                Expanded(
                  child: SizedBox(
                    height: 150,
                    child: CupertinoPicker(
                      scrollController: imagePickerController,
                      itemExtent: 60,
                      onSelectedItemChanged: (index) {
                        setState(() {
                          selectedImageSeq = index + 1;
                          selectedImageUrl =
                              '$_baseUrl/todos/image/$selectedImageSeq';
                        });
                      },
                      children: List.generate(
                        _imageCount,
                        (index) =>
                            Image.network('$_baseUrl/todos/image/${index + 1}'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(hintText: '목록을 입력하세요.'),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: isSaving ? null : updateTodo,
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}
