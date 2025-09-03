import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:desktop_opal/funcs.dart' as funcs;
import 'package:desktop_opal/main.dart' as mainScript;
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class Dashboard extends StatefulWidget{
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => DashboardState();
}

enum ButtonStates{
  notBlocked(widgets: [
    Align(alignment: Alignment.centerLeft, child: Padding(
      padding: EdgeInsets.only(bottom: 3),
      child: Text("Block Now"),
    )),
    Align(alignment: Alignment.centerRight, child: Icon(Icons.block))
  ],),
  blocked(widgets: [
    Align(alignment: Alignment.centerLeft, child: Padding(
      padding: EdgeInsets.only(bottom: 3),
      child: Text("Take A Break?"),
    )),
    Align(alignment: Alignment.centerRight, child: Icon(Icons.pause))],
  ),
  onBreak(widgets: [
    Align(alignment: Alignment.centerLeft, child: Padding(
      padding: EdgeInsets.only(bottom: 3),
      child: Text("Continue Blocking"),
    )),
    Align(alignment: Alignment.centerRight, child: Icon(Icons.play_arrow)),
  ]);

  const ButtonStates({
    required this.widgets,
  });

  final List<Widget> widgets;
}

bool currentlyBlocking = false;
Timer? breakTimer;
bool onBreak = false;
String timerText = "No Active Session";
double timerBarScale = 1;
int blockDuration = 0;
int initBlockDuration = 0;
int breakDuration = 0;
int initBreakDuration = 0;

List<String> barDataKeys = List.from(mainScript.history.keys);
List<double> barDataValues = List.from(mainScript.history.values);
int isTouchedIndex = -1;
double timeToAdd = 0;

class HistoryBarChart extends StatefulWidget{
  HistoryBarChart({super.key});


  State<HistoryBarChart> createState() => HistoryState();
}

class HistoryState extends State<HistoryBarChart>{
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context){
    return BarChart(
      BarChartData(
        barGroups: List.generate(mainScript.history.length, (index) => createBar(x: index, toY: barDataValues[index], width: 22)),
        alignment: BarChartAlignment.spaceEvenly,
        titlesData: FlTitlesData(
          show: true,
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(
              reservedSize: 25,
              showTitles: true
            )
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              reservedSize: 25,
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(barDataKeys[value.toInt()]);
              },
            )
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false))
        ),
        backgroundColor: Colors.grey[800],
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                "${barDataKeys[groupIndex]}:\n${rod.toY.toString()} hours",
                funcs.defaultText
              );
            },
          ),
          touchCallback: (FlTouchEvent event, response) {
            if(!event.isInterestedForInteractions || response == null || response.spot == null){
              setState(() {
                touchedIndex = -1;
              });
            } else{
              setState(() {
                touchedIndex = response.spot!.touchedBarGroupIndex;
              });
            }
          },
        ),
        maxY: 24,
        minY: 0
      )
    );
  }

  BarChartGroupData createBar({required int x, required double toY, required double width}){
  bool isTouched = x == touchedIndex;

  return BarChartGroupData(
    x: x,
    barRods: [
      BarChartRodData(
        toY: toY,
        width: width,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
        color: isTouched ? Colors.cyan[700] : Colors.cyan
      ),
    ],
    showingTooltipIndicators: []
  );
}
}

class BlockTimer with ChangeNotifier{

  Timer? timer;
  int? duration;

  void startTimer(){
    int initDuration = duration!;
    duration = duration!;
    timerText = "Time Remaining: ${funcs.formatTimerRemaining(duration!)}";
    //notifyListeners();
    timer = Timer.periodic(Duration(seconds: 1), (value) {
      print("dont even");
      timeToAdd++; //add time to bar chart
      duration = duration!-1;
      if(duration! <= 0){
        endTimer();
        notifyListeners();
      } else if(!onBreak){
        updateValues(initDuration);
        notifyListeners();
      }
    });
  }

  void updateValues(int initDuration){
    timerText = "Time Remaining: ${funcs.formatTimerRemaining(duration!)}";
    timerBarScale = duration! / initDuration;
  }

  void endTimer(){
    if(timer!=null) timer!.cancel();
    timerText = "No Active Session";
    timerBarScale = 1;
    currentlyBlocking = false;
    onBreak = false;
    (mainSetState == null) ? updateBarChart() : mainSetState!(() => updateBarChart());
    timeToAdd = 0;
    http.post(
      Uri.parse("http://127.0.0.1:8000/toggleBreak"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "goingOnBreak": true,
        "keys": funcs.validateBlockedApps()[0]
      })
    );
  }

  void updateBarChart(){
    String formattedDate = funcs.formatDateToJson(null);
    if(mainScript.history[formattedDate] != null){
      mainScript.history[formattedDate] = double.parse((mainScript.history[formattedDate]! + timeToAdd/3600).toStringAsFixed(2));
    } else{
      mainScript.history[formattedDate] = double.parse((timeToAdd/3600).toStringAsFixed(2));
    }
    File("assets/barchartdata.json").writeAsStringSync(jsonEncode(mainScript.history));
    int index = barDataKeys.indexOf(formattedDate);
    barDataValues[index] = mainScript.history[formattedDate]!;
}
}

class BreakTimer with ChangeNotifier{

  Timer? timer;
  int? duration;

  void startTimer(){
    onBreak = true;
    int initDuration = duration!;
    timerText = "On Break For: ${funcs.formatTimerRemaining(duration!)}";
    timer = Timer.periodic(Duration(seconds: 1), (value) {
      print("think about it");
      timeToAdd--; //take break time away from addition to bar chart - could add separate bars for breaktime in a future update?
      duration = duration! - 1;
      if(duration! <= 0){
        endTimer();
        notifyListeners();
      } else{
        updateValues(initDuration);
        notifyListeners();
      }
    });
  }

  void updateValues(int initDuration){
    if(!currentlyBlocking) {
      endTimer();
      return;
    }
    timerText = "On Break For: ${funcs.formatTimerRemaining(duration!)}";
    timerBarScale = duration! / initDuration;
  }

  void endTimer(){
    if(timer!=null) timer!.cancel();
    timerText = "No Active Session";
    onBreak = false;
    http.post(
      Uri.parse("http://127.0.0.1:8000/toggleBreak"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "goingOnBreak": currentlyBlocking ? false : true,
        "keys": funcs.validateBlockedApps()[0]
      })
    );
    http.post(Uri.parse("http://127.0.0.1:8000/terminateBlockedApps"));
  }
}

BlockTimer blockTim = BlockTimer();
BreakTimer breakTim = BreakTimer();

Function(void Function())? mainSetState;

bool breaksAllowed = true;

class DashboardState extends State<Dashboard> with WidgetsBindingObserver{
  final BoxDecoration defaultDecor = BoxDecoration(
    color: Colors.grey[900],
    borderRadius: BorderRadius.all(Radius.circular(16))
  );
  late TextStyle defaultText = TextStyle(
    color: Colors.white,
    fontSize: funcs.recalculateTextSize(context, []) //0.05 and 0.025 are the weightings that the width and height of the window have in respect to the fontsize
  );
  bool validDuration = false;
  late DateTime time;
  bool timeChosen = false;
  late DateTime startingTime;

  final double defaultWidth = 450;

  final SnackBar denyBlock = SnackBar(
    content: Text("Blocking has been disabled for this session.", style: TextStyle(color: Colors.white),),
    backgroundColor: Colors.grey[900],
  );

  List<double> sliderValues = List.filled(5, 0);

  WidgetsBinding get widgetBinding => WidgetsBinding.instance;

  @override
  void didChangeDependencies(){
    super.didChangeDependencies();
    widgetBinding.addObserver(this);
  }

  @override
  void dispose(){
    super.dispose();
    widgetBinding.removeObserver(this);
    mainSetState = null;
  }

  @override
  Widget build(BuildContext context){
    mainSetState = setState;
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Dashboard:", style: funcs.titleText,),
                  SizedBox(
                    width: 185,
                    height: 64,
                    child: ListenableBuilder(
                      listenable: Listenable.merge([blockTim, breakTim]),
                      builder: (context, Widget? child) {
                        return ElevatedButton(
                          onPressed: () async {
                            if(currentlyBlocking && onBreak){
                              breakTim.endTimer();
                            } else if(currentlyBlocking){
                              !breaksAllowed ? ScaffoldMessenger.of(context).showSnackBar(denyBlock) :
                              await openBreakDialog(context);
                            } else{
                              await openBlockDialog(context);
                            }
                          },
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: currentlyBlocking && onBreak ? 
                                ButtonStates.onBreak.widgets : currentlyBlocking ?
                                ButtonStates.blocked.widgets : ButtonStates.notBlocked.widgets
                            ),
                        );
                      }
                    ),
                  )
                ],
              ),
            ),
          ),
          Divider(
            height: 50,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8, left: 16, right: 8),
                    child: ListenableBuilder(
                      listenable: Listenable.merge([blockTim, breakTim]),
                      builder: (context, Widget? child) {
                        return Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))
                              ),
                              width: defaultWidth,
                              height: 65,
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 10, top: 10),
                                  child: Text(timerText, style: defaultText,),
                                )
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.cyan[400],
                                    borderRadius: currentlyBlocking?
                                      BorderRadius.only(bottomLeft: Radius.circular(16)) :
                                      BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16))
                                  ),
                                  height: 10,
                                  width: defaultWidth * timerBarScale,
                                ),
                                currentlyBlocking ?
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.cyan[800],
                                      borderRadius: BorderRadius.only(bottomRight: Radius.circular(16))
                                    ),
                                    width: defaultWidth * (1 - timerBarScale),
                                    height: 10,
                                  ) :
                                  Container()
                              ],
                            )
                          ],
                        );
                      }
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 16, left: 16, right: 8),
                    child: Container(
                      decoration: defaultDecor,
                      width: defaultWidth,
                      height: 308,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16, top: 8),
                              child: Text("oooo Sliders (i forgot what i wanted to put here)", style: defaultText,),
                            )
                          ),
                          for(int x=0; x<5; x++) Slider(value: sliderValues[x], onChanged: (value) {
                            sliderValues[x] = value;
                            setState(() {});
                          })
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 16, left: 8, right: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.all(Radius.circular(16))
                  ),
                  width: 586,
                  height: 399,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14, right: 20, left: 12),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 16),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text("Statistics (Time Blocked):", style: defaultText,),
                          ),
                        ),
                        ListenableBuilder(
                          listenable: Listenable.merge([blockTim]),
                          builder: (context, child) {
                            return Expanded(child: HistoryBarChart());
                          }
                        ),
                      ],
                    ),
                  ),
                  ),
              )
            ],
          ),
        ],
      ),
    );
  }

  bool checkIfNextDay(TimeOfDay selectedTime){
    TimeOfDay currentTime = TimeOfDay.now();
    if(selectedTime.hour < currentTime.hour) return true;
    if(selectedTime.hour == currentTime.hour && selectedTime.minute < currentTime.minute) return true;
    return false;
  }

  double getDurationInSeconds(TimeOfDay endTime, TimeOfDay? debugStartTime){
    TimeOfDay currentTime = debugStartTime ?? TimeOfDay.now();
    if(checkIfNextDay(endTime)) return ((23-currentTime.hour)*60 + (60-currentTime.minute) + endTime.hour*60 + endTime.minute) * 60;
    return ((endTime.hour - currentTime.hour) * 60 + (endTime.minute - currentTime.minute)) * 60;
  }

  bool isWaiting = false;

  Future<void> openBlockDialog(BuildContext context) async{
    late bool isFixedDuration = true;
    int duration = 5;
    TimeOfDay selectedTime = TimeOfDay.now();
    bool timeChosen = false;

    List<DropdownMenuEntry> durationValues = List.generate(6, (index) => DropdownMenuEntry(
      value: index+1 > 3 ? 
        (index-1) * 15 :
        (index+1) * 5,
      label: '${index+1 > 3 ? 
        (index-1) * 15 :
        (index+1) * 5} mins',
      ),
      growable: false
    );

    return await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState){
            return Dialog(
              child: SizedBox(
                width: 600,
                height: 300,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Wrap(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Duration Type:"),
                                DropdownMenu(
                                  initialSelection: true,
                                  dropdownMenuEntries: [
                                    DropdownMenuEntry(
                                      value: true, label: "Fixed Length"
                                    ),
                                    DropdownMenuEntry(
                                      value: false, label: "Until xx:xx"
                                    )
                                  ],
                                  onSelected: (value) => {
                                    setState(() {
                                      isFixedDuration = value ?? true;
                                      timeChosen = isFixedDuration ? true : false;
                                    })
                                  }
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Duration: ${isFixedDuration ? "" : 'Until ${selectedTime.hour}:${selectedTime.minute}'}"),
                                    isFixedDuration ?
                                    DropdownMenu(
                                      initialSelection: 5,
                                      dropdownMenuEntries: durationValues,
                                      onSelected: (value) {
                                        duration = int.parse(value.toString());
                                        setState(() {});
                                      },
                                    ) :
                                    TextButton(
                                      onPressed: () async {
                                        startingTime = DateTime.now();
                                        time = DateTime.now();
                                        selectedTime = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.now()
                                        ) ?? TimeOfDay.now();
                                        setState(() {
                                          timeChosen = true;
                                          print(time);
                                        });
                                      },
                                      child: Text("${timeChosen ? "Change" : "Choose"} Time")
                                    )
                                  ],
                                ),
                                checkIfNextDay(selectedTime) && !isFixedDuration ? Container(
                                  width: MediaQuery.of(context).size.width,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.all(Radius.circular(8)),
                                    color: const Color.fromARGB(100, 255, 168, 38),
                                    border: Border(top: BorderSide(color: Colors.orange[600]!, width: 3), bottom: BorderSide(color: Colors.orange[600]!, width: 3)),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Row(
                                      children: [
                                        Icon(Icons.warning, color: Colors.orange,),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8),
                                          child: Text("Warning: Selected time references tomorrow. Please make sure this is correct."),
                                        )
                                      ],
                                    ),
                                  ),
                                ) :
                                Container(),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Breaks Allowed"),
                                Checkbox(
                                  value: breaksAllowed,
                                  onChanged: (value) {
                                    breaksAllowed = value ?? true;
                                    setState(() {});
                                  }
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => {
                              timeChosen = false,
                              closeDialog(blocked: false, isFixedDuration: false)
                              },
                              child: Text("Nu uh")
                            ),
                            TextButton(
                              onPressed: () => closeDialog(blocked: true, isFixedDuration: isFixedDuration, fixedDuration: duration, endTime: selectedTime),
                              child: Text("Yuh huh")
                            ),
                            isWaiting ? CircularProgressIndicator() : Container(),
                          ],
                        )
                      )
                    ]
                  ),
                ),
              ),
            );
          }
        );
      }
    );
  }

  Future<void> openBreakDialog(BuildContext context) async{
    int duration = 300;

    List<DropdownMenuEntry> durationValues = List.generate(6, (index) => DropdownMenuEntry(
      value: index+1 > 3 ? 
        (index-1) * 15 :
        (index+1) * 5,
      label: '${index+1 > 3 ? 
        (index-1) * 15 :
        (index+1) * 5} mins',
      ),
      growable: false
    );

    return await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              child: SizedBox(
                width: 400,
                height: 128,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Break Length:"),
                          DropdownMenu(
                            initialSelection: durationValues[0],
                            dropdownMenuEntries: durationValues,
                            onSelected: (value) {
                              duration = int.parse(value.toString()) * 60;
                              setState(() {});
                            },
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => closeDialog(blocked: false, isFixedDuration: true),
                            child: Text("Cancel")
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              blockTim.endTimer();
                            },
                            child: Text("End Session Now")
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await http.post(
                                Uri.parse("http://127.0.0.1:8000/toggleBreak"),
                                headers: {"Content-Type": "application/json"},
                                body: jsonEncode({
                                  "goingOnBreak": true,
                                  "keys": funcs.validateBlockedApps()[0]
                                })
                              );
                              breakTim.duration = duration;
                              breakTim.startTimer();
                            },
                            child: Text("Ok")
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  void closeDialog({required bool blocked, required bool isFixedDuration, int? fixedDuration, TimeOfDay? endTime}) async{
    int duration = 0;
    if(mounted) Navigator.pop(context);
    if(blocked){
      setState(() {
        currentlyBlocking = true;
      });
      final List<List<String>> categorisedApps = funcs.validateBlockedApps();
      await http.post(
        Uri.parse("http://127.0.0.1:8000/deleteRegKeys"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "values": categorisedApps[1] //categorisedApps[validApps, excludedApps]
        })
      );

      await http.post(
        Uri.parse("http://127.0.0.1:8000/createRegKeys"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "values": categorisedApps[0]
        })
      );
      if(!isFixedDuration){
        DateTime now = DateTime.now();
        if(checkIfNextDay(endTime!)){
          duration =
            (23 - now.hour) * 3600 +
            (59 - now.minute) * 60 +
            (60 - now.second) +
            endTime.hour * 3600 +
            endTime.minute * 60;
        } else{
          int hoursToAdd = (endTime.hour - now.hour - 1) * 3600;
          hoursToAdd = hoursToAdd < 0 ? 0 : hoursToAdd;
          int minutesToAdd = (endTime.minute - now.minute - 1) * 60;
          minutesToAdd = minutesToAdd < 0 ? 0 : minutesToAdd;
          duration = hoursToAdd + minutesToAdd + 60 - now.second;
        }
      }else{
        duration = fixedDuration! * 60;
      }
      blockTim.duration = duration;
      blockTim.startTimer();
    }
    //print("Blocking: $blocked for fixed ($isFixedDuration) duration $duration or until $endTime for ${getDurationInSeconds(endTime ?? TimeOfDay.now(), null)} seconds. Blockable: $unblockable");
    validDuration = false;
  }
}