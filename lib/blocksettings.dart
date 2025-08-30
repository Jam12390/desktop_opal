import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:desktop_opal/funcs.dart' as funcs;
import 'package:desktop_opal/main.dart' as mainScript;

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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Settings:", style: titleText,)
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
                  height: MediaQuery.of(context).size.height - 150,
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
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8, left: 16),
                            child: Text("Blocked Apps:", style: funcs.titleText,),
                          )
                        ),
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
                            ),
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

  Future<void> openEditDialog(BuildContext context) async{
    List<String> availableApps = appEntries;

    Map<String, List<dynamic>> apps = {};
    Map<String, List<dynamic>> excludedApps = {};

    TabController controller = TabController(length: 2, vsync: this);

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

    for(var app in availableApps){
      apps[app] = [
        ListTile(
          title: Text(app),
          trailing: IconButton(
            onPressed: () => toggle(false, app),
            icon: Icon(Icons.close)
          ),
        ),
        true
      ];
      excludedApps[app] = [ //TODO: populate excludedApps with SAVED data from settings.json
        ListTile(
          title: Text(app),
          trailing: IconButton(
            onPressed: () => toggle(true, app),
            icon: Icon(Icons.check)
          ),
        ),
        false
      ];
    }
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
                width: 300,
                height: 400,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Edit Apps"),
                      ),
                      TabBar(
                        controller: controller,
                        tabs: [
                          Tab(icon: Icon(Icons.check, color: Colors.white), text: "Active Apps",),
                          Tab(icon: Icon(Icons.stop_circle, color: Colors.white,), text: "Removed Apps")
                        ]
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: controller,
                          children: [
                            ListView(
                              children: [
                                for(var entry in apps.keys) apps[entry]![1] ? apps[entry]![0] : Container()
                              ],
                            ),
                            ListView(
                              children: [
                                for(var entry in excludedApps.keys) excludedApps[entry]![1] ? excludedApps[entry]![0] : Container()
                              ],
                            )
                          ]
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => {
                                controller.dispose(),
                                closeDialog(saved: false)
                              },
                              child: Text("Cancel")
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: TextButton(
                                onPressed: () => {
                                  controller.dispose(),
                                  closeDialog(saved: true, enabledApps: apps, excludedApps: excludedApps)
                                },
                                child: Text("Ok")
                              ),
                            )
                          ],
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