import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class BlockSettingsPage extends StatefulWidget{
  const BlockSettingsPage({super.key});

  @override
  State<BlockSettingsPage> createState() => BlockSettingsPageState();
}

class BlockSettingsPageState extends State<BlockSettingsPage> with WidgetsBindingObserver{
  late Size currentDimensions = MediaQuery.of(context).size;
  late TextStyle defaultText = TextStyle(
    color: Colors.white, 
    fontSize: currentDimensions.width * 0.01 //vary this when testing
  );

  final List<String> listDataItems = ["one", "two", "three"];
  final List<Icon> listDataIcons = [
    Icon(Icons.one_k),
    Icon(Icons.access_alarm),
    Icon(Icons.baby_changing_station)
  ];
  final List<bool> listDataValues = List.filled(3, false);

  WidgetsBinding get widgetBinding => WidgetsBinding.instance;

  @override
  void didChangeDependencies(){
    super.didChangeDependencies();
    currentDimensions = View.of(context).physicalSize;
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
      currentDimensions = MediaQuery.of(context).size;
    });
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Row(
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
                    for(int i=0; i < listDataItems.length; i++)
                      CheckboxListTile(
                        value: listDataValues[i], onChanged: (value) {
                          listDataValues[i] = value!;
                          setState(() {});
                        },
                        title: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              listDataIcons[i],
                              Text(listDataItems[i], style: defaultText,),
                            ],
                          ),
                        ),
                      )
                  ],
                ),
              ),
            )
          )
        ],
      ),
    );
  }
}