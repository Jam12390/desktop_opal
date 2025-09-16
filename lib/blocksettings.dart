import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:desktop_opal/funcs.dart' as funcs;
import 'package:desktop_opal/main.dart' as mainScript;
import 'package:desktop_opal/reworkedDashboard.dart' as dashboard;

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'constants/helpText.dart' as helpStrings;


Map<String, bool> shownErrors = {
  "notices": true,
  "warnings": false,
  "errors": false,
  "criticalErrors": false};

List<String> allErrors = [];

class BlockSettingsPage extends StatefulWidget{
  const BlockSettingsPage({super.key});

  @override
  State<BlockSettingsPage> createState() => BlockSettingsPageState();
}

class BlockSettingsPageState extends State<BlockSettingsPage> with WidgetsBindingObserver, TickerProviderStateMixin{
  late TabController controller;
  late TextEditingController textController;

  WidgetsBinding get widgetBinding => WidgetsBinding.instance;

  @override
  void didChangeDependencies(){
    super.didChangeDependencies();
    widgetBinding.addObserver(this);
  }

  @override
  void initState(){
    super.initState();
    controller = TabController(length: 2, vsync: this);
    textController = TextEditingController();
  }

  @override
  void dispose(){
    widgetBinding.removeObserver(this);
    controller.dispose();
    textController.dispose();
    super.dispose();
  }

  List<String> appEntries = List.from(mainScript.settings["detectedApps"].keys);
  List<bool> appValues = List.from(mainScript.settings["detectedApps"].values);

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Settings:", style: funcs.titleText,)
            ),
          ),
          Divider(height: 50,),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16, left: 16, bottom: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    color: Colors.grey[900],
                  ),
                  width: MediaQuery.of(context).size.width * (2/5),
                  height: MediaQuery.of(context).size.height - 146,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.amber
                        ),
                        height: MediaQuery.of(context).size.height - 396,
                        child: ListView(
                          shrinkWrap: true,
                            children: [
                              ListTile(
                                leading: Icon(Icons.dark_mode),
                                title: Text("Dark Mode"),
                                subtitle: Text("(Coming... at one point)"),
                                trailing: Switch(
                                  value: mainScript.settings["darkMode"],
                                  onChanged: (value) {
                                    mainScript.settings["darkMode"] = value;
                                    setState(() {});
                                  }
                                )
                              ),
                              ListTile(
                                leading: Icon(Icons.warning),
                                title: Text("The Uh Oh Button"),
                                subtitle: Text("For when the windows registry decides you no longer have access to any apps"),
                                trailing: IconButton(
                                  onPressed: () {
                                    http.post(Uri.parse("http://127.0.0.1:8000/wipeEntries"));
                                    dashboard.blockTim.endTimer();
                                    dashboard.breakTim.endTimer();
                                  },
                                  icon: Icon(Icons.restore),
                                  tooltip: "Uh Oh",
                                ),
                              ),
                          ],
                        ),
                      ),
                      Wrap(
                        children: [
                          ListTile(
                            leading: Icon(Icons.question_mark),
                            title: Text("How To Use"),
                            trailing: IconButton(
                              onPressed: () async {await openHelpDialog(context);},
                              icon: Icon(Icons.help),
                              tooltip: "Open Help",
                            ),
                          ),
                          ListTile(
                            leading: Icon(Icons.bug_report),
                            title: Text("Error Logs"),
                            trailing: IconButton(
                              onPressed: () async {await openErrorLogDialog(context);},
                              icon: Icon(Icons.developer_mode),
                              tooltip: "Open Error Log",
                            ),
                          )
                        ]
                      )
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: Container(
                    width: MediaQuery.of(context).size.width/2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                      color: Colors.grey[900]
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text("Blocked Apps:", style: TextStyle(color: Colors.grey[400], fontSize: 35)),
                              ),
                              IconButton(
                                onPressed: () async{
                                  await openEditDialog(context);
                                },
                                tooltip: "Edit Apps",
                                icon: Icon(Icons.edit, color: Colors.white,)
                              )
                            ],
                          ),
                        ),
                        Divider(height: 10,),
                        SizedBox(
                          height: MediaQuery.of(context).size.height - 288,
                          child: ListView(
                            children: [
                              for(int i=0; i < appEntries.length; i++)
                                mainScript.settings["excludedApps"].contains(appEntries[i]) ?
                                Container() :
                                CheckboxListTile(
                                  value: appValues[i], onChanged: (value) {
                                    appValues[i] = value!;
                                    mainScript.settings["detectedApps"][appEntries[i]] = appValues[i];
                                    setState(() {}); //update view
                                  },
                                  title: Padding(
                                    padding: const EdgeInsets.only(top: 8, left: 16),
                                    child: Text(appEntries[i], style: funcs.defaultText,)
                                    ),
                                  )
                              ],
                          ),
                        ),
                        Divider(height: 10,),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Wrap(
                                children: [
                                  IconButton(
                                    onPressed: () async {
                                      final response = await http.get(Uri.parse("http://127.0.0.1:8000/checkForDesktopExecutables?"));
                                      List<String> executables = jsonDecode(response.body).cast<String>();
                                      setState(() {
                                        for(String executable in executables){
                                          if(!appEntries.contains(executable)){
                                            mainScript.settings["detectedApps"][executable] = true;
                                            mainScript.settings["enabledApps"].add(executable);
                                            appEntries.add(executable);
                                            appValues.add(true);
                                          }
                                        }
                                      });
                                    },
                                    tooltip: "Auto-detect Executables",
                                    icon: Icon(Icons.restart_alt, color: Colors.white,)
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      await openConfirmDialog(context);
                                    },
                                    tooltip: "Delete ALL App Entries",
                                    icon: Icon(Icons.delete_forever, color: Colors.white,)
                                  )
                                ]
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                )
              )
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: "Apply Settings",
        onPressed: () async {
          mainScript.initialSettings = mainScript.settings;
          String saveDir = (await getApplicationDocumentsDirectory()).path;
          File("$saveDir\\DesktopOpal\\settings.json").writeAsStringSync(jsonEncode(mainScript.settings));
        },
        child: Icon(Icons.save),
      ),
    );
  }

  Future<void> openHelpDialog(BuildContext context) async{
    return await showDialog(
      context: context, 
      builder: (context) {
        return Dialog(
          child: SizedBox(
            width: 900,
            height: 400,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("How To Use", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),)
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Align(alignment: Alignment.centerLeft, child: Text("Blocking Apps:", style: funcs.howToSubtitle,)),
                          Text(helpStrings.Help.blockedHelp),
                          Align(alignment: Alignment.centerLeft, child: Text("Break Time:", style: funcs.howToSubtitle,)),
                          Text(helpStrings.Help.breakHelp),
                          Align(alignment: Alignment.centerLeft, child: Text("Editing Blocked Apps:", style: funcs.howToSubtitle,)),
                          Text(helpStrings.Help.editHelp),
                          Align(alignment: Alignment.centerLeft, child: Text("Tools for editing apps:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, decoration: TextDecoration.underline))),
                          Text(helpStrings.Help.advEditHelp)
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Ok")
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Future<void> openConfirmDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: SizedBox(
            height: 100,
            width: 400,
            child: Padding(
              padding: const EdgeInsets.only(top: 15, left: 20, right: 10, bottom: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Text("Are you sure you want to delete ALL app entries?")
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => closeDialog(saved: false),
                        child: Text("No")
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          setState(() {
                            mainScript.settings["detectedApps"] = {};
                            mainScript.settings["enabledApps"] = [];
                            mainScript.settings["excludedApps"] = [];
                            appEntries = [];
                            appValues = [];
                          });
                          await http.post(
                            Uri.parse("http://127.0.0.1:8000/wipeEntries")
                          );
                        },
                        child: Text("Yes")
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

  Future<void> openEditDialog(BuildContext context) async{
    List<String> availableApps = appEntries;

    Map<String, List<dynamic>> apps = {};
    Map<String, List<dynamic>> excludedApps = {};

    final formKey = GlobalKey<FormState>();

    void Function(void Function())? externalSetState;

    bool test = false;

    void toggle(bool activate, String app){
      if(externalSetState != null){
        externalSetState!(() {
          if(activate){
              excludedApps[app]![1] = false;
              apps[app]![1] = true;
          } else{
              apps[app]![1] = false;
              excludedApps[app]![1] = true;
          }
        });
      }
    }

    void removeExecutable({required bool active, required String executable}){
      externalSetState!(() {
        mainScript.settings["detectedApps"].remove(executable);
        int index = appEntries.indexOf(executable);
        appEntries.remove(executable);
        appValues.removeAt(index);
        apps.remove(executable);
        excludedApps.remove(executable);
        if(active){
          mainScript.settings["enabledApps"].remove(executable);
        } else{
          mainScript.settings["excludedApps"].remove(executable);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Successfully deleted entry $executable!", style: funcs.snackBarText),
        backgroundColor: Colors.grey[900],
        duration: funcs.snackBarDuration,
      ));
    }

    void addExecutable({required String executable}){
      mainScript.settings["detectedApps"][executable] = true;
      externalSetState!(() {
        mainScript.settings["enabledApps"].add(executable);
        apps[executable] = [
          EditDialogListTile(
          active: true,
          title: executable,
          toggleFunction: () => toggle(false, executable),
          deleteFunction: () => removeExecutable(active: false, executable: executable)
        ),
        true
      ];
      excludedApps[executable] = [
        EditDialogListTile(
          active: false,
          title: executable,
          toggleFunction: () => toggle(true, executable),
          deleteFunction: () => removeExecutable(active: false, executable: executable)
        ),
        false
        ];
      });
      appEntries.add(executable);
      appValues.add(true);
    }

    apps = {
      for(var app in availableApps) app: [
        EditDialogListTile(
          active: true,
          title: app,
          toggleFunction: () => toggle(false, app),
          deleteFunction: () => removeExecutable(active: true, executable: app)
        ),
        true
      ]
    };
    excludedApps = {
      for(var app in availableApps) app: [
        EditDialogListTile(
          active: false,
          title: app,
          toggleFunction: () => toggle(true, app),
          deleteFunction: () => removeExecutable(active: false, executable: app)
        ),
        false
      ]
    };

    for(var excludedApp in mainScript.settings["excludedApps"]){
      apps[excludedApp]![1] = false;
      excludedApps[excludedApp]![1] = true;
    }

    return await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState){
            externalSetState = setState;
            return Dialog(
              child: SizedBox(
                width: 400,
                height: 500,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Edit Apps", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))
                          ),
                          child: TabBar(
                            controller: controller,
                            tabs: [
                              Tab(icon: Icon(Icons.check, color: Colors.white), text: "Visible Apps",),
                              Tab(icon: Icon(Icons.stop_circle, color: Colors.white,), text: "Excluded Apps")
                            ]
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16))
                            ),
                            child: TabBarView(
                              controller: controller,
                              children: [
                                ListView(
                                  shrinkWrap: true,
                                  children: [
                                    for(var entry in apps.keys) apps[entry]![1] ? apps[entry]![0] : Container() //[0] - ListTile widget [1] - Enabled?
                                  ],
                                ),
                                ListView(
                                  shrinkWrap: true,
                                  children: [
                                    for(var entry in excludedApps.keys) excludedApps[entry]![1] ? excludedApps[entry]![0] : Container()
                                  ],
                                ),
                              ]
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Manual Addition:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, decoration: TextDecoration.underline),)
                        ),
                      ),
                      Form(
                        key: formKey,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: textController,
                                decoration: InputDecoration(
                                  border: UnderlineInputBorder(),
                                  labelText: "Enter executable"
                                ),
                                validator: (value) { //id prefer to use a switch case here however I cant due to switch case restricting the variable
                                  if(value == null || value.isEmpty){
                                    return "Enter a value";
                                  } else if(value.contains("'") || value.contains('"')){
                                    return "Speech marks aren't necessary.";
                                  } else if(value.substring((value.length-4).clamp(0, value.length), value.length) != ".exe"){
                                    return "Ensure your executable ends in .exe";
                                  } else if(mainScript.settings["blacklistedApps"].contains(value)){
                                    return "This app is blacklisted from blockable apps";
                                  } else if(value.contains("\\") || value.contains("/")){
                                    return "Don't enter the path to the application, just the exe";
                                  } else if(mainScript.settings["detectedApps"].keys.contains(value)){
                                    return "Value already exists in apps";
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (value) {
                                  if(formKey.currentState!.validate()){
                                    addExecutable(executable: value);
                                    textController.clear();
                                  }
                                },
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                if(formKey.currentState!.validate()) {
                                  addExecutable(executable: textController.text);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text("Successfully added entry ${textController.text}!", style: funcs.snackBarText),
                                    backgroundColor: Colors.grey[900],
                                    duration: funcs.snackBarDuration,
                                  ));
                                  textController.clear();
                                }
                              },
                              icon: Icon(Icons.arrow_right, color: Colors.white,)
                            )
                          ]
                        )
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: TextButton(
                                onPressed: () => {
                                  if(formKey.currentState!.validate()){
                                    addExecutable(executable: textController.text),
                                    textController.clear()
                                  } else{
                                    test = true
                                  },
                                  if(test){
                                    test = false,
                                    closeDialog(saved: true, enabledApps: apps, excludedApps: excludedApps)
                                  }
                                },
                                child: Text("Close Menu")
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        );
      }
    );
  }

  Future<void> openErrorLogDialog(BuildContext context) async{
    String logPath = "${(await getApplicationDocumentsDirectory()).path}\\DesktopOpal\\ErrorLog.txt";
    allErrors = File(logPath).readAsLinesSync();
    
    Map<String, List<ErrorTile>> errors = {
      "notices": [],
      "warnings": [],
      "errors": [],
      "criticalErrors": []
    };

    if(allErrors.isNotEmpty) allErrors.removeAt(0);

    Function(void Function())? externalSetState;
    List<String> errorTypes = List.from(errors.keys);

    List<Widget> generateErrorList(){
      print("e");
      List<Widget> errorList = [];
      for(String key in errorTypes){
        if(shownErrors[key]!) errorList.addAll(errors[key]!);
      }
      return errorList.isEmpty ? [Text("No errors to show (yay!).", style: funcs.errorTitle,)] : errorList;
    }

    List<String> filterButtonTitles = List.generate(errorTypes.length, (index) {
      String toReturn = "";
      if(errorTypes[index] == "criticalErrors"){
        toReturn = "Critical Errors";
      } else{
        toReturn = "${errorTypes[index][0].toUpperCase()}${errorTypes[index].substring(1).toLowerCase()}";
      }
      return toReturn;
    });

    List<Widget> listChildren = [];

    void deleteError({required String error, required String errorType}){
      externalSetState!(() {
        allErrors.remove(error);
        errors[errorType]!.removeWhere((errTile) => errTile.error == error);
        listChildren = generateErrorList();
      });
    }

    void wipeLog(){
      externalSetState!(() {
        errors = {
          "notices": [],
          "warnings": [],
          "errors": [],
          "criticalErrors": []
        };
        allErrors = [];
        listChildren = [];
        File(logPath).writeAsStringSync("");
      });
    }

    for(String error in allErrors){
      String errorType = error.split("]")[0].substring(1); //Splits the error into [0] - [$error and [1] - $log, taking [$error after the first character as the error type
      switch(errorType){
        case("NOTICE"):
          errors["notices"]!.add(ErrorTile(error: error, deleteFunction: () => deleteError(error: error, errorType: "notices"),));
          break;
        case("WARNING"):
          errors["warnings"]!.add(ErrorTile(error: error, deleteFunction: () => deleteError(error: error, errorType: "warnings")));
          break;
        case("ERROR"):
          errors["errors"]!.add(ErrorTile(error: error, deleteFunction: () => deleteError(error: error, errorType: "errors")));
          break;
        case("CRITICAL ERROR" || "OH NO"):
          errors["criticalErrors"]!.add(ErrorTile(error: error, deleteFunction: () => deleteError(error: error, errorType: "criticalErrors")));
          break;
        default:
          errors["notices"]!.add(ErrorTile(error: error, deleteFunction: () => deleteError(error: error, errorType: "notices")));
          break;
      }
    }

    double dialogWidth = 800;
    double dialogHeight = 400;

    return await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            externalSetState = setState;
            listChildren = generateErrorList();
            List<FilterButton> buttons = List.generate(errorTypes.length, (index) {
              return FilterButton(
                title: filterButtonTitles[index],
                enabled: errorTypes[index] == "notices" ? true : false,
                toggleFunction: () => listChildren = generateErrorList(),
                externalSetState: externalSetState,
                width: dialogWidth * 0.02 * filterButtonTitles[index].length, //TODO: idea - multiply a percentage by the length of the title for varying width
                overrideWidth: errorTypes[index] == "criticalErrors" ? 125 : null,
              );
            });
            return Dialog(
              child: SizedBox(
                width: dialogWidth,
                height: dialogHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Error Logs", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, decoration: TextDecoration.underline),)
                      ),
                      Row(
                        children: buttons,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                          color: Colors.grey[900]
                        ),
                        width: dialogWidth,
                        height: dialogHeight*(0.6),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: ListView(
                            shrinkWrap: true,
                            children: listChildren
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: onPressed,
                            child: Text("Wipe Logs")
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              String write = "";
                              for(String error in allErrors) {write += "\n$error";}
                              File(logPath).writeAsStringSync(write);
                            },
                            child: Text("Close")
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
    );
  }

  List<String> extractAppsFromMap(Map<String, List<dynamic>> map){
    List<String> result = [];
    for(var entry in map.entries){
      if(entry.value[1]) result.add(entry.key);
    }
    return result;
  }

  void closeDialog({required bool saved, Map<String, List<dynamic>>? enabledApps, Map<String, List<dynamic>>? excludedApps}){
    Navigator.pop(context);
    if(saved){
      setState(() {
        mainScript.settings["excludedApps"] = extractAppsFromMap(excludedApps ?? {});
        mainScript.settings["enabledApps"] = extractAppsFromMap(enabledApps ?? {});
      });
    }
  }

  Future<void> openWipeConfirmDialog(BuildContext context) async {
    final double dialogWidth = 400;
    final double dialogHeight = 200;

    return await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: Column(
              children: [//TODO: here

              ],
            ),
          ),
        );
      }
    );
  }
}

class EditDialogListTile extends StatelessWidget{
  const EditDialogListTile({super.key, required this.active, required this.title, required this.toggleFunction, required this.deleteFunction});

  final bool active;
  final String title;
  final VoidCallback toggleFunction;
  final VoidCallback deleteFunction;
  
  @override
  Widget build(BuildContext context){
    return SizedBox(
        width: MediaQuery.of(context).size.width,
        height: 50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(title),
            ),
            Wrap(
              children: [
                IconButton(
                  onPressed: deleteFunction,
                  icon: Icon(Icons.delete_forever, color: Colors.white,)
                ),
                IconButton(
                  onPressed: toggleFunction,
                  icon: Icon(active ? Icons.close : Icons.check, color: Colors.white),
                )
              ],
            )
          ],
        ),
      );
  }
}

class FilterButton extends StatefulWidget{
  const FilterButton({super.key, required this.title, required this.enabled, required this.toggleFunction, required this.externalSetState, required this.width, this.overrideWidth});

  final String title;
  final bool enabled;
  final void Function() toggleFunction;
  final Function(void Function())? externalSetState;
  final double width;
  final double? overrideWidth;

  @override
  State<FilterButton> createState() => FilterButtonState(enabled: enabled);
}

class FilterButtonState extends State<FilterButton>{
  FilterButtonState({required this.enabled});

  bool enabled;
  late Color colour;

  @override
  void dispose(){
    super.dispose();
  }

  @override
  void initState(){
    super.initState();
    colour = widget.enabled ? Colors.blue[400]! : Colors.grey[900]!;
  }

  @override
  Widget build(BuildContext context){
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          color: colour
        ),
        width: widget.overrideWidth ?? widget.width, //use overrideWidth if defined during initialisation, otherwise use default width
        height: 30,
        child: TextButton(
          onPressed: () {
            setState(() {
              enabled = !enabled;
              colour = enabled ? Colors.blue[400]! : Colors.grey[900]!;
              List<String> shownErrorKeySplit = widget.title.toLowerCase().split(" ");
              String shownErrorKey = shownErrorKeySplit[0];
              for(int x=1; x < shownErrorKeySplit.length; x++){
                shownErrorKey += "${shownErrorKeySplit[x][0].toUpperCase()}${shownErrorKeySplit[x].substring(1)}";
              }
              shownErrors[shownErrorKey] = !shownErrors[shownErrorKey]!;
            });
            widget.externalSetState!(() => widget.toggleFunction());
          },
          child: Text(widget.title),
        ),
      )
    );
  }
}

class ErrorTile extends StatelessWidget{
  const ErrorTile({super.key, required this.error, required this.deleteFunction});
  
  final String error;
  final VoidCallback deleteFunction;

  @override
  Widget build(BuildContext context){
    final List<String> errorComponents = [ //in order: errortype, datetime, error
      error.split(" ")[0],
      "${error.split(": ")[0].split(" ")[1]} ${error.split(": ")[0].split(" ")[2].split(".")[0]}",
      error.split(": ")[1]
    ];
    return SizedBox(
      height: 125,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${errorComponents[1]} - ${errorComponents[0]}:", style: funcs.errorTitle,),
              IconButton(
                onPressed: deleteFunction, //TODO: implement deletion of specific errors
                icon: Icon(Icons.delete)
              )
            ],
          ),
          SingleChildScrollView(
            child: Text(errorComponents[2]),
          )
        ],
      ),
    );
  }
}