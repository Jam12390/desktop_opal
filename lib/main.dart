import 'dart:io';
import 'package:desktop_opal/dashboard.dart';
import 'package:desktop_opal/blocksettings.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

void main() async{
  const double maxSizeX = 1600;
  const double maxSizeY = 1200;
  const double minSizeX = 800;
  const double minSizeY = 600;

  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  if (Platform.isWindows) {
    WindowManager.instance.setMinimumSize(const Size(minSizeX, minSizeY));
    WindowManager.instance.setMaximumSize(const Size(maxSizeX, maxSizeY));
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      home: const MainPage(title: 'Example Text'),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.title});

  final String title;

  @override
  State<MainPage> createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  Widget page = DashboardPage();
  Text appbarText = Text("Dashboard", style: TextStyle(color: Colors.white),);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        backgroundColor: Colors.red,
        toolbarHeight: 50,

        title: appbarText,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            SizedBox(
              height: 120,
              child: DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: <Color>[
                    Colors.red,
                    Colors.redAccent
                  ])
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("miata"),
                      Text("waaaaaaaaaaaaaaaaaaaaa")
                    ],
                  ),
                ),
              ),
            ),
            CustomListTile(Icon(Icons.dashboard_rounded, color: Colors.grey[800],), Text("Dashboard"), () {
              setState(() {
                page = DashboardPage();
                appbarText = Text("Dashboard");
                Navigator.pop(context);
              });
              }
            ),
            CustomListTile(Icon(Icons.piano_rounded), Text("ow"), () {
              setState(() {
                page = OtherPage();
                appbarText = Text("Other page");
                Navigator.pop(context);
              });
            }),
            CustomListTile(Icon(Icons.stop_circle_rounded, color: Colors.grey[800],), Text("Block Settings"), () {
              setState(() {
                page = BlockSettingsPage();
                appbarText = Text("Block Settings");
                Navigator.pop(context);
              });
            })
          ],
        ),
      ),
      body: page
    );
  }
}

class OtherPage extends StatelessWidget{
  const OtherPage({super.key});

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Center(
        child: Text("something happend"),
      ),
    );
  }
}

class CustomListTile extends StatelessWidget{
  final Text text;
  final Icon icon;
  final VoidCallback onTapFunction;

  const CustomListTile(this.icon, this.text, this.onTapFunction, {super.key});

  @override
  Widget build(BuildContext context){
    return InkWell(
      onTap: onTapFunction,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 6, bottom: 6),
            child: Wrap(
              spacing: 10,
                children: [
                  icon, text
                ]
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(Icons.arrow_right, color: Colors.grey[800]),
          )
        ],
        ),
      )
    );
  }
}