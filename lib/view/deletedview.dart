import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class Deletedview extends StatefulWidget {
  const Deletedview({super.key});

  @override
  State<Deletedview> createState() => _DeletedviewState();
}

class _DeletedviewState extends State<Deletedview> {
  static const String _baseUrl = 'http://192.168.20.52:8000';

  List<Map<String, dynamic>> deletedTodos = [];
  bool isLoading = true;
  bool isRestoring = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    getDeletedTodos();
  }

  /// 삭제된 Todo와 이미지 연결을 현재 목록으로 복구한다.
  Future<void> restoreTodo(int seq) async {
    setState(() => isRestoring = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/todos/trash/$seq/restore'),
      );
      if (response.statusCode != 200) {
        throw Exception('Todo를 복구하지 못했습니다.');
      }

      await getDeletedTodos();
      Get.snackbar('복구 완료', 'Todo가 현재 목록으로 복구됐습니다.');
    } catch (error) {
      Get.snackbar('복구 실패', error.toString());
    } finally {
      if (mounted) {
        setState(() => isRestoring = false);
      }
    }
  }

  /// FastAPI에서 삭제된 Todo 목록을 불러온다.
  Future<void> getDeletedTodos() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/todos/trash'));
      if (response.statusCode != 200) {
        throw Exception('휴지통을 불러오지 못했습니다.');
      }

      final decoded = json.decode(utf8.decode(response.bodyBytes));
      final results = decoded['results'] as List;
      if (!mounted) return;

      setState(() {
        deletedTodos = results
            .map((todo) => Map<String, dynamic>.from(todo as Map))
            .toList();
        isLoading = false;
        errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: const Text('Deleted Todo List'),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null) {
      return Center(child: Text(errorMessage!));
    }
    if (deletedTodos.isEmpty) {
      return const Center(child: Text('삭제된 데이터가 없습니다.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: deletedTodos.length,
      itemBuilder: (context, index) {
        final todo = deletedTodos[index];
        final imageSeq = todo['image_seq'];
        return Card(
          color: index.isEven ? Colors.amber[50] : Colors.pink[50],
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: imageSeq == null
                    ? const SizedBox(
                        width: 70,
                        height: 70,
                        child: Icon(Icons.image_not_supported_outlined),
                      )
                    : Image.network(
                        '$_baseUrl/todos/image/$imageSeq',
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
              ),
              Expanded(
                child: Text(
                  '${todo['content']} / '
                  '${todo['insertdate'].toString().substring(0, 10)}',
                ),
              ),
              IconButton(
                tooltip: '복구',
                onPressed: isRestoring
                    ? null
                    : () => restoreTodo(todo['seq'] as int),
                icon: const Icon(Icons.restore),
              ),
            ],
          ),
        );
      },
    );
  }
}
