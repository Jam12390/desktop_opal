import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart' as mainScript;
import 'reworkedDashboard.dart' as dashboard;
import 'package:http/http.dart' as http;

TextStyle defaultText = TextStyle(
  color: Colors.white, 
  fontSize: 16
  //fontSize: funcs.recalculateTextSize(context, dimensionWeightings) //vary this when testing
);

TextStyle titleText = TextStyle(
  color: Colors.grey[400],
  //decoration: TextDecoration.underline,
  fontSize: 45
  //fontSize: funcs.recalculateTextSize(context, titleDimensionWeightings),
);

double recalculateTextSize(BuildContext context, List<double> dimensionWeightings){
  final Size dimensions = MediaQuery.of(context).size;
  if (dimensionWeightings.length == 2){
    return ((dimensions.height * dimensionWeightings[0]) + (dimensions.width * dimensionWeightings[1])) / 2;
  }
  return ((dimensions.height * 0.04) + (dimensions.width * 0.015)) / 2; //default to these weightings
}

Future<Map<String, type>> loadJsonFromFile<type>(String fileName) async{
  return jsonDecode(await rootBundle.loadString("assets/$fileName")) as Map<String, type>;
}