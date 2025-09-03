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
bool isDarkMode = false;
Widget page = dashboard.Dashboard();

Map<String, double> history = {};
Map<String, double> historyBuffer = {};

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

DateTime decodeString(String date){
  if(date.length != 8){
    List<String> splitDate = date.split("/");
    date = "${splitDate[0].length==2 ? splitDate[0] : "0${splitDate[0]}"}/${splitDate[1].length==2 ? splitDate[1] : "0${splitDate[1]}"}/${splitDate[2].length==2 ? splitDate[2] : "0${splitDate[2]}"}";
  }
  return DateTime(int.parse("20${date.substring(6, 8)}"), int.parse(date.substring(3, 5)), int.parse(date.substring(0, 2)));
}

void fillGaps(String date1, String date2, {bool finalAddition = false}){
  DateTime date1Decoded = decodeString(date1);
  DateTime date2Decoded = decodeString(date2);

  while(date1Decoded.add(Duration(days: 1)) != date2Decoded){
    String buffer = funcs.formatDateToJson(date1Decoded.add(Duration(days: 1)));
    buffer = verifyFormat(buffer);
    historyBuffer.addAll({buffer : 0});
    date1Decoded = date1Decoded.add(Duration(days: 1));
  }
  if(finalAddition) historyBuffer.addAll({verifyFormat(funcs.formatDateToJson(date2Decoded)) : 0});
}

String verifyFormat(String toCheck){
  if(toCheck.length > 8){
    toCheck = toCheck.substring(1, 11);
    toCheck = "${toCheck.substring(8, 10)}/${toCheck.substring(5, 7)}/${toCheck.substring(2, 4)}";
  }
  return toCheck;
}

void main() async{
  var shell = Shell();
  
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  if (Platform.isWindows) {
    await windowManager.waitUntilReadyToShow(
      WindowOptions(
        size: Size(1200, 600),
        maximumSize: Size(1200, 600),
        minimumSize: Size(1200, 600)
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      }
    );
  }

  settings = await funcs.loadJsonFromFile<dynamic>("settings.json");
  initialSettings = jsonDecode(jsonEncode(settings)); //makes a deep copy (unlinked) of the object
  history = (await funcs.loadJsonFromFile<dynamic>("barchartdata.json")).map((key, value) => MapEntry(key, double.parse(value.toString())),);

  shell.run(r'start $pwd/../assets/winregBackend.py');

  runApp(
    const MyApp()
  );
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

class ReworkedMPState extends State<MainPage> {
  Widget page = dashboard.Dashboard();

  @override
  void initState() {
    super.initState();

    List<String> dayKeys = List.from(history.keys);
    for(int index=0; index<dayKeys.length; index++){
      if(index == dayKeys.length-1 && decodeString(dayKeys[index]) == DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)){ //covers if the final index is today
        historyBuffer.addAll({dayKeys[index]: history[dayKeys[index]]!});
      } else if(index == dayKeys.length-1 || dayKeys.length == 1){ //covers if the final index isnt today
        DateTime temp = DateTime.now();
        historyBuffer.addAll({dayKeys[index]: history[dayKeys[index]]!});
        fillGaps(dayKeys[index], "${temp.day}/${temp.month}/${temp.year.toString().substring(2, 4)}", finalAddition: true);
      } else if(decodeString(dayKeys[index]).add(Duration(days: 1)) == decodeString(dayKeys[index+1])){ //covers if index and index+1 are consecutive days
        historyBuffer.addAll({dayKeys[index]: history[dayKeys[index]]!});
      } else {
        historyBuffer.addAll({dayKeys[index]: history[dayKeys[index]]!});
        fillGaps(dayKeys[index], dayKeys[index+1]);
      }
    }
  
    if(historyBuffer.isEmpty) historyBuffer.addAll({funcs.formatDateToJson(null): 0.0});
  
    if(historyBuffer.length > 7){
      dayKeys = List.from(historyBuffer.keys);
      while(historyBuffer.length > 7){
        historyBuffer.remove(dayKeys[0]);
        dayKeys.removeAt(0);
      }
    }
    history = historyBuffer;
    File("assets/barchartdata.json").writeAsStringSync(jsonEncode(history));
  }

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