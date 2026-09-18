import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class Addview extends StatefulWidget {
  const Addview({super.key});

  @override
  State<Addview> createState() => _AddViewState();
}

class _AddViewState extends State<Addview> {
  final TextEditingController contentController =
      TextEditingController();

  int imageSeq = 1;

  Future<void> insertTodo() async {
    final uri = Uri.parse(
      //'http://팀_FASTAPI_서버_IP:8000/todos/insertTodo'
      'http://192.168.20.52:8000/todos/insertTodo',
      ).replace(
      queryParameters: {
        'content': contentController.text,
        'image_seq': imageSeq.toString(),
      },
    );

    final response = await http.post(uri);

    if (response.statusCode == 200) {
      Get.back(result: true);
    }
  }

  @override
  void dispose() {
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
        title: const Text('Add View'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Image.network(
                    //'http://팀_FASTAPI_서버_IP:8000/todos/view/$imageSeq'
                    'http://192.168.20.52:8000/todos/view/$imageSeq',
                    height: 120,
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: 150,
                    child: CupertinoPicker(
                      itemExtent: 60,
                      onSelectedItemChanged: (index) {
                        setState(() {
                          imageSeq = index + 1;
                        });
                      },
                      children: List.generate(
                        3,
                        (index) => Image.network(
                          // 'http://팀_FASTAPI_서버_IP:8000/todos/view/${index + 1}'
                          'http://192.168.20.52:8000/todos/view/${index + 1}',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                hintText: '목록을 입력하세요',
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: insertTodo,
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}