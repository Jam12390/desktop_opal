import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart' as mainScript;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

late String debugFilePath;
late File debugFile;

TextStyle defaultText = TextStyle(
  color: Colors.white, 
  fontSize: 20
);

TextStyle titleText = TextStyle(
  color: Colors.grey[400],
  fontSize: 45
);

TextStyle snackBarText = TextStyle(
  color: Colors.white
);

Duration snackBarDuration = Duration(seconds: 2);

TextStyle graphTooltipText = TextStyle(
  fontSize: 16,
  color: Colors.white
);

TextStyle howToSubtitle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w600,
  decoration: TextDecoration.underline,
);

TextStyle errorTitle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  decoration: TextDecoration.underline
);

void initDebugFile() async{
  debugFilePath = (await getApplicationDocumentsDirectory()).path;
  debugFile = File("$debugFilePath\\DesktopOpal\\ErrorLog.txt");
}

Future<Map<String, type>> loadJsonFromFile<type>(String fileName) async{
  //return jsonDecode(await rootBundle.loadString("assets/$fileName")) as Map<String, type>;
  String saveDir = (await getApplicationDocumentsDirectory()).path;
  return jsonDecode(File("$saveDir\\DesktopOpal\\$fileName").readAsStringSync())  as Map<String, type>;
}

String formatTimerRemaining(int timeRemaining){
  int hours = timeRemaining ~/ 3600;
  timeRemaining -= hours * 3600;
  int mins = timeRemaining ~/ 60;
  timeRemaining -= mins * 60;
  String returnString = "${hours < 10 ? "0$hours" : hours}:${mins < 10 ? "0$mins" : mins}:${timeRemaining < 10 ? "0$timeRemaining" : timeRemaining}";

  return returnString;
}

List<List<String>> validateBlockedApps(){
  List<String> validApps = [];
  List<String> excludedApps = [];
  for(var item in mainScript.settings["detectedApps"].entries){
    if(item.value && !mainScript.settings["excludedApps"].contains(item.key)) {
      validApps.add(item.key);
    } else{
      excludedApps.add(item.key);
    }
  }
  return [validApps, excludedApps];
}

String formatDateToJson(DateTime? toEncode){
  toEncode ??= DateTime.now();
  String result = "${toEncode.day < 10 ? "0${toEncode.day}" : toEncode.day}/${toEncode.month < 10 ? "0${toEncode.month}" : toEncode.month}/${toEncode.year.toString().substring(2, 4)}";
  return result;
}

void updateErrorLog({required String logType, required String log}){
  debugFile.writeAsStringSync("\n[$logType] ${DateTime.now()}: $log", mode: FileMode.append);
}