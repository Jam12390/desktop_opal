import 'dart:convert';
import 'dart:io';
import 'package:desktop_opal/blocksettings.dart' as blockSettings;
import 'package:desktop_opal/reworkedDashboard.dart' as dashboard;
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:desktop_opal/funcs.dart' as funcs;
import 'package:process_run/shell.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
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

void checkForExistingFiles(String path, Shell shell) {
  List<String> missingFiles = [];
  Directory saveFolder = Directory("$path\\DesktopOpal");
  if(!saveFolder.existsSync()){
    shell.runSync("mkdir $path\\DesktopOpal");
  }
  path = "$path\\DesktopOpal";
  if(!File("$path\\settings.json").existsSync()){
    missingFiles.add("settings.json");
  }
  if(!File("$path\\barchartdata.json").existsSync()){
    missingFiles.add("barchartdata.json");
  }
  if(!File("$path\\ErrorLog.txt").existsSync()){
    missingFiles.insert(0, "ErrorLog.txt"); //ensure that the error log is created first
  }
  for(String fileName in missingFiles){
    funcs.updateErrorLog(logType: "NOTICE", log:"File $fileName not found, creating instance at $path\\$fileName");
    try{
      File("$path\\$fileName").createSync();
      if(fileName.substring(fileName.length-5, fileName.length) == ".json" && fileName=="settings.json"){
        File("$path\\$fileName").writeAsStringSync(jsonEncode({
          "detectedApps": {},
          "enabledApps": [],
          "excludedApps": [],
          "blacklistedApps": ["explorer.exe", "regedit.exe"],
          "darkMode": true,
        }));
      } else if(fileName.substring(fileName.length-5, fileName.length) == ".json"){
        File("$path\\$fileName").writeAsStringSync(jsonEncode({}));
      }
      if(fileName == "ErrorLog.txt") {
        funcs.initDebugFile(path: path);
        funcs.ableToWriteErrors = true;
      }
    } catch(e) {
      funcs.updateErrorLog(logType: "ERROR", log:"File $fileName failed to create due to error: $e");
    }
  }
}

void ensureChartDataFilled(){
  List<String> dayKeys = List.from(history.keys);
  for(int index=0; index<dayKeys.length; index++){
    
    if(index == dayKeys.length-1 && decodeString(dayKeys[index]) == DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)){ //covers if the final index is today
      historyBuffer.addAll({dayKeys[index]: history[dayKeys[index]]!});
    } 
    else if(index == dayKeys.length-1 || dayKeys.length == 1){ //covers if the final index isnt today
      DateTime temp = DateTime.now();
      historyBuffer.addAll({dayKeys[index]: history[dayKeys[index]]!});
      fillGaps(dayKeys[index], "${temp.day}/${temp.month}/${temp.year.toString().substring(2, 4)}", finalAddition: true);
    } 
    else if(decodeString(dayKeys[index]).add(Duration(days: 1)) == decodeString(dayKeys[index+1])){ //covers if index and index+1 are consecutive days
      historyBuffer.addAll({dayKeys[index]: history[dayKeys[index]]!});
    } 
    else {
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

  String saveDir = (await getApplicationDocumentsDirectory()).path;
  
  checkForExistingFiles(saveDir, shell);

  try{
    settings = await funcs.loadJsonFromFile<dynamic>("settings.json");
  } catch(e){
    funcs.updateErrorLog(logType: "WARNING", log: "Settings file could not be read due to reason $e. Resetting values.");
    settings = {
      "detectedApps": {},
      "enabledApps": [],
      "excludedApps": [],
      "blacklistedApps": [],
      "darkMode": false,
    };
  }
  try{
    history = (await funcs.loadJsonFromFile<dynamic>("barchartdata.json")).map((key, value) => MapEntry(key, double.parse(value.toString())),);
  } catch(e){
    funcs.updateErrorLog(logType: "WARNING", log: "Bar chart history could not be read due to reason $e. Resetting history.");
    history = {};
  }

  initialSettings = jsonDecode(jsonEncode(settings)); //makes a deep copy (unlinked) of the object

  ensureChartDataFilled();

  File("$saveDir\\DesktopOpal\\barchartdata.json").writeAsStringSync(jsonEncode(history));

  //try{
  //  bool apiInitialised = false;
  //  shell.runSync(r"start $pwd/../winregBackend.py");
  //  //shell.runSync(r'start winregBackend.exe');
  //  while(!apiInitialised){
  //    try{
  //      await http.post(Uri.parse("http://127.0.0.1:8000/apiTest"));
  //      apiInitialised = true;
  //    } catch(_){
  //      apiInitialised = false;
  //    }
  //  }
  //  Future.delayed(Duration(seconds: 2));
  //  await http.post(
  //    Uri.parse("http://127.0.0.1:8000/initLog"),
  //    headers: {
  //      "Content-Type": "application/json"
  //    },
  //    body: jsonEncode({
  //      "firstOpen": settings["firstOpen"]
  //    })
  //  );
  //  settings["firstOpen"] = false;
  //  File("$saveDir\\DesktopOpal\\settings.json").writeAsStringSync(jsonEncode(settings));
  //} catch (e) {
  //  funcs.updateErrorLog(logType: "ERROR", log: "Backend failed to start with exception $e");
  //}

  //shell.runSync(r"start $pwd/../desktop_opal.py"); //TODO: in build versions, make sure this ISNT ran

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
  //Widget page = dashboard.Dashboard();
  Widget page = dashboard.Dashboard();

  void initState(){
    super.initState();

    http.post(Uri.parse("http://127.0.0.1:8000/initLog")); //TODO: run this in build versions
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
                              String saveDir = (await getApplicationDocumentsDirectory()).path;
                              try{
                                //fndkfjdkfnkfndkfdn; //testing error
                                File("$saveDir\\DesktopOpal\\settings.json").writeAsStringSync(jsonEncode(settings));
                              } catch(e){
                                funcs.updateErrorLog(logType: "ERROR", log: "Failed to save settings due to $e");
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 16),
                                          child: Icon(Icons.warning, color: Colors.white,),
                                        ),
                                        Text("Settings failed to save. Please try again or consult the error log for more info.")
                                      ],
                                    )
                                  )
                                  );
                              }
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