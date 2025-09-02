import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:desktop_opal/funcs.dart' as funcs;
import 'package:desktop_opal/main.dart' as mainScript;
import 'package:desktop_opal/reworkedDashboard.dart' as dashboard;

import 'package:http/http.dart' as http;

class BlockSettingsPage extends StatefulWidget{
  const BlockSettingsPage({super.key});

  @override
  State<BlockSettingsPage> createState() => BlockSettingsPageState();
}

class BlockSettingsPageState extends State<BlockSettingsPage> with WidgetsBindingObserver, TickerProviderStateMixin{
  final List<double> dimensionWeightings = [0.03, 0.0125];
  final List<double> titleDimensionWeightings = [0.06, 0.025]; //can hardcode for prod
  File settingsFile = File("assets/settings.json");

  late TextStyle defaultText = TextStyle(
    color: Colors.white, 
    fontSize: 16
    //fontSize: funcs.recalculateTextSize(context, dimensionWeightings) //vary this when testing
  );

  late TextStyle titleText = TextStyle(
    color: Colors.grey[400],
    //decoration: TextDecoration.underline,
    fontSize: 45
    //fontSize: funcs.recalculateTextSize(context, titleDimensionWeightings),
  );

  WidgetsBinding get widgetBinding => WidgetsBinding.instance;

  @override
  void didChangeDependencies(){
    super.didChangeDependencies();
    widgetBinding.addObserver(this);
  }

  @override
  void dispose(){
    widgetBinding.removeObserver(this);
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
              child: Text("Settings:", style: titleText,)
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
                  child: ListView(
                    children: [
                      ListTile(
                        leading: Icon(Icons.abc),
                        title: Text("Dark Mode"),
                        trailing: Switch(
                          value: mainScript.settings["darkMode"],
                          onChanged: (value) {
                            mainScript.settings["darkMode"] = value;
                            setState(() {});
                          }
                        )
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
                                icon: Icon(Icons.edit, color: Colors.white,)
                              )
                            ],
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height - 268,
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
          settingsFile.writeAsStringSync(jsonEncode(mainScript.settings));
        },
        child: Icon(Icons.save),
      ),
    );
  }

  Future<void> openConfirmDialog(BuildContext context) async { //TODO: end any existing block session when the button is pressed
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

    TabController controller = TabController(length: 2, vsync: this);
    final TextEditingController textController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    void Function(void Function())? externalSetState;

    void toggle(bool activate, String app){
      if(externalSetState != null){
        externalSetState!(() {
          if(activate){
              excludedApps[app]![1] = false;
              apps[app]![1] = true;
          } else{
              print("Deactivated $app");
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
    }

    void addExecutable({required String executable}){
      print("run");
      mainScript.settings["detectedApps"][executable] = true;
      externalSetState!(() {
        mainScript.settings["enabledApps"].add(executable);
        apps[executable] = [
          editDialogListTile(
          active: true,
          title: executable,
          toggleFunction: () => toggle(false, executable),
          deleteFunction: () => removeExecutable(active: false, executable: executable)
        ),
        true
      ];
      excludedApps[executable] = [
        editDialogListTile(
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
        editDialogListTile(
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
        editDialogListTile(
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
                                validator: (value) {
                                  if(value == null || value.isEmpty){
                                    return "Enter a value";
                                  } else if(value.substring((value.length-4).clamp(0, value.length), value.length) != ".exe"){
                                    return "Ensure your executable ends in .exe";
                                  }
                                  return null;
                                },
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                if(formKey.currentState!.validate()) {
                                  addExecutable(executable: textController.text);
                                };
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
                            TextButton(
                              onPressed: () => {
                                controller.dispose(),
                                textController.dispose(),
                                closeDialog(saved: false)
                              },
                              child: Text("Cancel")
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: TextButton(
                                onPressed: () => {
                                  controller.dispose(),
                                  textController.dispose(),
                                  closeDialog(saved: true, enabledApps: apps, excludedApps: excludedApps)
                                },
                                child: Text("Ok")
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

  List<String> extractAppsFromMap(Map<String, List<dynamic>> map){
    List<String> result = [];
    for(var entry in map.entries){
      if(entry.value[1]) result.add(entry.key);
    }
    return result;
  }

  void closeDialog({required bool saved, Map<String, List<dynamic>>? enabledApps, Map<String, List<dynamic>>? excludedApps}){
    if(saved){
      setState(() {
        mainScript.settings["excludedApps"] = extractAppsFromMap(excludedApps ?? {});
        mainScript.settings["enabledApps"] = extractAppsFromMap(enabledApps ?? {});
      });
    }
    Navigator.pop(context);
  }
}

class editDialogListTile extends StatelessWidget{
  editDialogListTile({required this.active, required this.title, required this.toggleFunction, required this.deleteFunction});

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