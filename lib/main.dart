import 'package:flutter/material.dart';
import 'package:video_rec/auth/authentication.dart';
import 'package:video_rec/ui/root_page.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        title: 'Video Recorder App',
        debugShowCheckedModeBanner: false,
        theme: new ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: new RootPage(auth: new Auth()));
  }
}


//void main(){
//  runApp(
//      new MaterialApp(
//        home: HomeScreen(),
//      )
//  );
//}



