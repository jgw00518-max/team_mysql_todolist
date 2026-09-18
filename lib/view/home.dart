import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_todo_list_app/view/addview.dart';
import 'package:image_todo_list_app/view/deletedview.dart';
import 'package:image_todo_list_app/view/updateview.dart';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List data = [];
  int imageVersion = 0;

  @override
  void initState() {
    super.initState();
    getJSONData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Todo List 검색"),
        actions: [
          IconButton(
            onPressed: () async {
              await Get.to(() => const Deletedview());
              getJSONData(refreshImages: true);
            },
            icon: const Icon(Icons.delete_outline),
          ),
          IconButton(
            onPressed: () {
              Get.to(Addview())!.then((value) => getJSONData());
            },
            icon: Icon(Icons.add_outlined),
          ),
        ],
      ),

      body: Center(
        child: data.isEmpty
            ? const Center(child: Text("데이터가 없습니다."))
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    return Card(
                      color: index % 2 == 0
                          ? Colors.amber[50]
                          : Colors.pink[50],
                      child: InkWell(
                        onLongPress: () => showDeleteDialog(
                          Map<String, dynamic>.from(data[index]),
                        ),
                        onTap: () async {
                          final isUpdated = await Get.to<bool>(
                            () => const Updateview(),
                            arguments: Map<String, dynamic>.from(data[index]),
                          );
                          if (isUpdated == true) {
                            getJSONData(refreshImages: true);
                          }
                        },
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Image.network(
                                "http://192.168.20.52:8000/todos/view/${data[index]['seq']}?v=$imageVersion",
                                // "http://192.168.0.109:8000/todos/view/${data[index]['seq']}?v=$imageVersion",
                                width: 70,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Text(
                              "${data[index]['content']} / ${data[index]['insertdate'].toString().substring(0, 10)}  ${data[index]['insertdate'].toString().substring(11)}",
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  /// 길게 누른 Todo를 휴지통으로 이동할지 확인한다.
  Future<void> showDeleteDialog(Map<String, dynamic> todo) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('삭제 안내'),
        content: Text("'${todo['content']}'을(를) 휴지통으로 이동할까요?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await moveTodoToTrash(todo['seq'] as int);
    }
  }

  /// FastAPI에 요청하여 Todo를 삭제 목록으로 이동한다.
  Future<void> moveTodoToTrash(int seq) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.20.52:8000/todos/trash/$seq'),
      );
      if (response.statusCode != 200) {
        throw Exception('Todo를 삭제하지 못했습니다.');
      }

      await getJSONData(refreshImages: true);
      Get.snackbar('삭제 완료', 'Todo가 휴지통으로 이동했습니다.');
    } catch (error) {
      Get.snackbar('삭제 실패', error.toString());
    }
  }

  Future<void> getJSONData({bool refreshImages = false}) async {
    var url = Uri.parse("http://192.168.20.52:8000/todos/select");
    // var url = Uri.parse("http://192.168.0.109:8000/todos/select",);
    var response = await http.get(url);
    var dataConvertedJSON = json.decode(utf8.decode(response.bodyBytes));

    List result = dataConvertedJSON['results'];

    data.clear();
    data.addAll(result);

    if (refreshImages) {
      imageVersion++;
    }

    setState(() {});
    // print(data);
  }
}
