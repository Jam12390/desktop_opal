import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:desktop_opal/funcs.dart' as funcs;
import 'package:desktop_opal/main.dart' as mainScript;

class BlockSettingsPage extends StatefulWidget{
  const BlockSettingsPage({super.key});

  @override
  State<BlockSettingsPage> createState() => BlockSettingsPageState();
}

class BlockSettingsPageState extends State<BlockSettingsPage> with WidgetsBindingObserver{
  final List<double> dimensionWeightings = [0.03, 0.0125];
  final List<double> titleDimensionWeightings = [0.06, 0.025]; //can hardcode for prod
  File settingsFile = File("assets/settings.json");

  late TextStyle defaultText = TextStyle(
    color: Colors.white, 
    fontSize: funcs.recalculateTextSize(context, dimensionWeightings) //vary this when testing
  );

  late TextStyle titleText = TextStyle(
    color: Colors.white,
    decoration: TextDecoration.underline,
    fontSize: funcs.recalculateTextSize(context, titleDimensionWeightings),
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

  @override
  void didChangeMetrics(){
    if(!mounted) return;
    setState(() {
      defaultText = TextStyle(
        color: Colors.white,
        fontSize: funcs.recalculateTextSize(context, dimensionWeightings) //0.05 and 0.025 are the weightings that the width and height of the window have in respect to the fontsize
      );
      titleText = TextStyle(
        color: Colors.white,
        decoration: TextDecoration.underline,
        fontSize: funcs.recalculateTextSize(context, titleDimensionWeightings)
  );
    });
  }

  List<String> appEntries = List.from(mainScript.settings["detectedApps"].keys);
  List<bool> appValues = List.from(mainScript.settings["detectedApps"].values);

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 16),
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
                            child: Text("Blocked Apps:", style: titleText,),
                          )
                        ),
                        for(int i=0; i < appEntries.length; i++)
                          CheckboxListTile(
                            value: appValues[i], onChanged: (value) {
                              appValues[i] = value!;
                              mainScript.settings["detectedApps"][appEntries[i]] = appValues[i];
                              setState(() {}); //do shit here for enabling and disabling app blocking
                            },
                            title: Padding(
                              padding: const EdgeInsets.only(top: 8, left: 16),
                              child: Text(appEntries[i], style: defaultText,)
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
        onPressed: () => {
          mainScript.initialSettings = mainScript.settings,
          settingsFile.writeAsStringSync(jsonEncode(mainScript.settings))
        },
        child: Icon(Icons.save),
      ),
    );
  }
}

//probably not needed BUT it could be useful for mass changing some list items
class SettingsListItem extends StatelessWidget{
  const SettingsListItem({
    super.key,
    required this.icon,
    required this.settingTitle,
    this.settingSubtitle,
    required this.trailing,
  });

  final Icon icon;
  final String settingTitle;
  final String? settingSubtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context){
    return ListTile(
      
    );
  }
}