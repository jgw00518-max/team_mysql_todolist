import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_todo_list_app/view/addview.dart';
import 'package:image_todo_list_app/view/home.dart';
import 'package:image_todo_list_app/view/updateview.dart';

/// 팀원들이 화면 이동에 공통으로 사용할 GetX 경로를 관리한다.
abstract final class AppRoutes {
  static const home = '/';
  static const add = '/add';
  static const update = '/update';
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      initialRoute: AppRoutes.home,
      getPages: [
        GetPage(name: AppRoutes.home, page: () => const Home()),
        GetPage(name: AppRoutes.add, page: () => const Addview()),
        GetPage(name: AppRoutes.update, page: () => const Updateview()),
      ],
    );
  }
}
