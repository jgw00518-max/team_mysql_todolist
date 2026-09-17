import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_todo_list_app/view/addview.dart';
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
            onPressed: () {
              Get.to(Addview())!.then((value) => getJSONData());
            },
            icon: Icon(Icons.add_outlined)
          )
        ],
      ),

      body: Center(
        child: data.isEmpty
        ? const Center(child: Text("데이터가 없습니다."))
        : ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            return Card(
              color: data[index] % 2 == 0
              ? Colors.amber[50]
              : Colors.pink[50],
              child: Row(
                children: [
                  Image.network(
                    "http://192.168.20.229:8000/view/${data[index]['seq']}?v=$imageVersion",
                    width: 100
                  ),
                  Text("${data[index]['image']} / ${data[index]['insertdate']}")
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> getJSONData({bool refreshImages = false}) async {
    var url = Uri.parse("http://192.168.20.229:8000/todos/select");
    var response = await http.get(url);
    var dataConvertedJSON = json.decode(utf8.decode(response.bodyBytes));

    List result = dataConvertedJSON['results'];

    data.clear();
    data.addAll(result);

    if(refreshImages) {
      imageVersion++;
    }

    setState(() {});
    // print(data);
  }
}
