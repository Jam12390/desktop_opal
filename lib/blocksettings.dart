import 'dart:convert';
import 'dart:io';
import 'dart:nativewrappers/_internal/vm/lib/ffi_native_type_patch.dart';

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
  File settingsFile = File("assets/settings.json");

  late TextStyle defaultText = TextStyle(
    color: Colors.white, 
    fontSize: funcs.recalculateTextSize(context, dimensionWeightings) //vary this when testing
  );

  late TextStyle titleText = TextStyle(
    color: Colors.white,
    decoration: TextDecoration.underline,
    fontSize: funcs.recalculateTextSize(context, [0.05, 0.02])
  );

  final List<String> listDataItems = ["one", "two", "three"];
  //final List<Icon> listDataIcons = [
  //  Icon(Icons.one_k),
  //  Icon(Icons.access_alarm),
  //  Icon(Icons.baby_changing_station)
  //];
  final List<bool> listDataValues = List.filled(3, false);

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
    setState(() {
      defaultText = TextStyle(
        color: Colors.white,
        fontSize: funcs.recalculateTextSize(context, dimensionWeightings) //0.05 and 0.025 are the weightings that the width and height of the window have in respect to the fontsize
      );
      titleText = TextStyle(
        color: Colors.white,
        decoration: TextDecoration.underline,
        fontSize: funcs.recalculateTextSize(context, [0.05, 0.02])
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
          Text("Settings:", style: titleText,),
          Divider(height: 100,),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    color: Colors.grey[900],
                  ),
                  width: MediaQuery.of(context).size.width/2,
                  height: MediaQuery.of(context).size.height,
                  child: Text("waaaaaaaa", style: defaultText),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Container(
                    width: MediaQuery.of(context).size.width/2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                      color: Colors.grey[900]
                    ),
                    child: Column(
                      children: [
                        Text("Blocked Apps:", style: titleText,),
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
        onPressed: () => {
          settingsFile.writeAsStringSync(jsonEncode(mainScript.settings))
        }
      ),
    );
  }
}