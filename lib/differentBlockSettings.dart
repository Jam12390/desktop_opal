import 'package:flutter/material.dart';
import 'main.dart' as main;

class settingsPage extends StatefulWidget{
  const settingsPage({super.key});

  State<settingsPage> createState() => settingsPageState();
}

class settingsPageState extends State<settingsPage>{
  ThemeMode theme = main.isDarkMode ? ThemeMode.dark : ThemeMode.light;
  Icon themeIcon = Icon(Icons.brightness_1);

  void updateTheme(ThemeMode mode){
    setState(() {
      theme = mode;
    });
  }

  void initState(){
    super.initState();
    print(""); //TODO: call a python function here to detect installed apps
  }

  Widget build(BuildContext context){
    themeIcon = theme==ThemeMode.light ? Icon(Icons.brightness_1_rounded) : Icon(Icons.dark_mode_rounded);

    return Scaffold(
      body: Column(
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: Colors.grey[700], size: 50,),
              Text("Settings", style: TextStyle(
                fontSize: 50,
                color: Colors.black,
              ),)
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              themeIcon,
              Text("App Theme"),
              Switch(
                value: main.isDarkMode, 
                onChanged: (isDarkMode) => {
                  main.isDarkMode = isDarkMode,
                  main.isDarkMode ? updateTheme(ThemeMode.dark) : updateTheme(ThemeMode.light)
                }
              ),
            ],
          ),
          Text("Blocked Apps"),
          ListBody(
            children: [
              ListTile()
            ],
          )
        ],
      ),
    );
  }
}