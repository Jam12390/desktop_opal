import 'dart:convert';
import 'dart:io';
import 'package:desktop_opal/blocksettings.dart' as blockSettings;
import 'package:desktop_opal/reworkedDashboard.dart' as dashboard;
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:desktop_opal/funcs.dart' as funcs;
import 'package:process_run/shell.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

Map<String, dynamic> settings = {};
Map<String, dynamic> initialSettings = {};
Map<String, dynamic> initSettings = {};
bool isDarkMode = false;
Widget page = dashboard.Dashboard();

class AppThemes{
  static final lightMode = ThemeData(
    primaryColor: (Colors.grey[500]),
    brightness: Brightness.light
  );
  static final darkMode = ThemeData(
    primaryColor: Colors.grey[900],
    brightness: Brightness.dark
  );
}

void main() async{
  var shell = Shell();

  shell.run('''
cd C:\\Users\\natha\\OneDrive\\Documents\\Python\\'VSCode Python'\\'Hack Club Stuff'\\desktop_opal\\desktop_opal
dir
start winregBackend.py
''');

  //shell.run("start C:\\Users\\natha\\OneDrive\\Documents\\Python\\'VSCode Python'\\'Hack Club Stuff'\\desktop_opal\\desktop_opal\\lib\\scripts\\winregBackend.py");

  const double maxSizeX = 1600;
  const double maxSizeY = 1200;
  const double minSizeX = 800;
  const double minSizeY = 600;

  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  if (Platform.isWindows) {
    //WindowManager.instance.setMinimumSize(const Size(minSizeX, minSizeY));
    WindowManager.instance.setSize(Size(1200, 600));
    WindowManager.instance.setResizable(false);
  }
  settings = await funcs.loadJsonFromFile<dynamic>("settings.json");
  initialSettings = jsonDecode(jsonEncode(settings)); //makes a deep copy (unlinked) of the object

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: AppThemes.lightMode,
      darkTheme: AppThemes.darkMode,
      home: const MainPage(title: 'Example Text'),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.title});

  final String title;

  @override
  State<MainPage> createState() => ReworkedMPState();
}

class MainPageState extends State<MainPage> {
  Text appbarText = Text("Dashboard", style: TextStyle(color: Colors.white),);

  File settingsFile = File("assets/settings.json");

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
                page = dashboard.Dashboard();
                appbarText = Text("Dashboard");
                Navigator.pop(context);
              });
              }
            ),
            CustomListTile(Icon(Icons.stop_circle_rounded, color: Colors.grey[800],), Text("Block Settings"), () {
              setState(() {
                page = blockSettings.BlockSettingsPage();
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

class ReworkedMPState extends State<MainPage> {
  Widget page = dashboard.Dashboard();

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(right: BorderSide(color: Color.fromARGB(255, 66, 66, 66), width: 2))
            ),
            height: MediaQuery.of(context).size.height,
            width: 100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: CustomListTile(Icon(Icons.dashboard_rounded, color: Colors.grey[800],), Text("Dashboard"), () async {
                    if(jsonEncode(initialSettings) == jsonEncode(settings)){
                      setState(() {
                        page = dashboard.Dashboard();
                      });
                    } else{
                      await openUnsavedChangesDialog(context, dashboard.Dashboard());
                    }
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CustomListTile(Icon(Icons.settings, color: Colors.grey[800],), Text("Settings"), () {
                    setState(() {
                      page = blockSettings.BlockSettingsPage();
                    });
                  }),
                ),
              ],
            ),
          ),
          Expanded(child: page)
        ],
      ),
    );
  }

  Future<void> openUnsavedChangesDialog(BuildContext context, Widget attemptedTravelPage) async{
    File settingsFile = File("assets/settings.json");

    return await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: 300,
              height: 100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("You have unsaved changes! Would you like to save them now?"),
                  Wrap(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() {
                                settings = jsonDecode(jsonEncode(initialSettings));
                                page = attemptedTravelPage;
                              });
                            },
                            child: Text("Discard Changes")
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              setState(() {
                                initialSettings = jsonDecode(jsonEncode(settings));
                                page = attemptedTravelPage;
                              });
                              settingsFile.writeAsStringSync(jsonEncode(settings));
                            },
                            child: Text("Save Changes")
                          )
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      }
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
    return AnimatedContainer(
      width: 100,
      duration: Duration(milliseconds: 1500),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTapFunction,
          splashColor: Colors.grey[700],
          child: Padding(
            padding: EdgeInsets.only(top: 8, bottom: 8),
            child: Column(
              children: [
                icon,
                text
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//class CustomListTile extends StatelessWidget{
//  final Text text;
//  final Icon icon;
//  final VoidCallback onTapFunction;
//
//  const CustomListTile(this.icon, this.text, this.onTapFunction, {super.key});
//
//  @override
//  Widget build(BuildContext context){
//    return InkWell(
//      onTap: onTapFunction,
//      splashColor: Colors.orange,
//      child: Padding(
//        padding: const EdgeInsets.only(top: 8, bottom: 8),
//        child: Container(
//          //height: 60,
//          child: Column(
//          children: [
//            icon,
//            text
//            //Padding(
//            //  padding: const EdgeInsets.all(6),
//            //  child: Wrap(
//            //    spacing: 10,
//            //      children: [
//            //        icon, text
//            //      ]
//            //  ),
//            //),
//            //Padding(
//            //  padding: const EdgeInsets.only(right: 8),
//            //  child: Icon(Icons.arrow_right, color: Colors.grey[800]),
//            //)
//          ],
//          ),
//        ),
//      )
//    );
//  }
//}