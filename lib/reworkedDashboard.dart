import 'dart:convert';
import 'dart:io';

import 'package:day_night_time_picker/day_night_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:desktop_opal/funcs.dart' as funcs;
import 'package:desktop_opal/main.dart' as mainScript;
import 'package:http/http.dart' as http;

class Dashboard extends StatefulWidget{
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => DashboardState();
}

enum ButtonStates{
  notBlocked(widgets: [Text("Block Now"), Icon(Icons.block)],),
  blocked(widgets: [Text("Take A Break?"), Icon(Icons.pause)],);

  const ButtonStates({
    required this.widgets,
  });

  final List<Widget> widgets;
}

bool currentlyBlocking = false;

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
  late bool timeChosen = false;
  late DateTime startingTime;
  //late String timeAsText = "";

  final double defaultWidth = 510;

  WidgetsBinding get widgetBinding => WidgetsBinding.instance;

  void Function(void Function())? mainSetState;

  @override
  void didChangeDependencies(){
    super.didChangeDependencies();
    widgetBinding.addObserver(this);
  }

  @override
  void dispose(){
    super.dispose();
    widgetBinding.removeObserver(this);
  }

  @override
  void didChangeMetrics(){
    if(!mounted) return;
    setState(() {
      defaultText = TextStyle(
        color: Colors.white,
        fontSize: funcs.recalculateTextSize(context, []) //0.05 and 0.025 are the weightings that the width and height of the window have in respect to the fontsize
      );
    });
  }

  @override
  Widget build(BuildContext context){
    mainSetState = setState;
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Dashboard:", style: funcs.titleText,),
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
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))
                          ),
                          width: defaultWidth,
                          height: 65,
                          child: Text("data", style: defaultText,),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.cyan[400],
                            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16))
                          ),
                          height: 10,
                          width: defaultWidth,
                          child: Text("data", style: defaultText,),
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 16, left: 16, right: 8),
                    child: Container(
                      decoration: defaultDecor,
                      width: defaultWidth,
                      height: 308,
                      //height: MediaQuery.of(context).size.height,
                      child: Text("data", style: defaultText,),
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
                  width: defaultWidth,
                  height: 399,
                  child: Text("data2", style: defaultText,),
                  ),
              )
            ],
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 130,
        child: FloatingActionButton(
          onPressed: () async {
            if(currentlyBlocking){
              await openBreakDialog(context); //will probably need context here too
            } else{
              await openBlockDialog(context);
            }
          },
          backgroundColor: Colors.cyan[400],
          hoverColor: Colors.cyan[700],
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: currentlyBlocking ? ButtonStates.blocked.widgets : ButtonStates.notBlocked.widgets
            ),
          ),
        ),
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
    double duration = 5;
    TimeOfDay selectedTime = TimeOfDay.now();
    bool timeChosen = false;
    bool isUnblockable = true;

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
                                        duration = double.parse(value.toString());
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
                                  value: isUnblockable,
                                  onChanged: (value) {
                                    isUnblockable = value ?? true;
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
                              onPressed: () => closeDialog(blocked: true, isFixedDuration: isFixedDuration, duration: duration, endTime: selectedTime, unblockable: isUnblockable),
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
              //actions: [
              //  TextButton(
              //    onPressed: () => {
              //      timeChosen = false,
              //      closeDialog(blocked: false, isFixedDuration: false)
              //    },
              //    child: Text("Nu uh")
              //  ),
              //  TextButton(
              //    onPressed: () => closeDialog(blocked: true, isFixedDuration: isFixedDuration, duration: duration, endTime: selectedTime, unblockable: isUnblockable),
              //    child: Text("Yuh huh")
              //  )
              //],
            );
          }
        );
      }
    );
  }

  Future<void> openBlockingDialog(BuildContext context) async{
    late String timeAsText = "";
    return await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState){
            return AlertDialog(
              content: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("DateTime"),
                      Text(timeAsText),
                      TextButton(
                        onPressed: () => {
                          startingTime = DateTime.now(),
                          time = DateTime.now(),
                          setState(() {
                            timeChosen = true;
                            print(time);
                          }),
                          Navigator.of(context).push(
                            showPicker(
                              value: Time(hour: DateTime.now().hour, minute: DateTime.now().minute+1),
                              //minHour: DateTime.now().hour.toDouble(),
                              //minMinute: time.hour == startingTime.hour ? DateTime.now().minute.toDouble() : 0,
                              is24HrFormat: true,
                              onChange: (p0) {},
                              onChangeDateTime: (datetime) => {
                                setState(() {
                                  time = datetime;
                                  timeAsText = '${time.hour}:${time.minute}';
                                })
                              }
                            )
                          )
                        },
                        child: Text("Choose")
                      )
                    ],
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => {
                    timeChosen = false,
                    closeDialog(blocked: false, isFixedDuration: false)
                  },
                  child: Text("Nu uh")
                ),
                TextButton(
                  onPressed: () => closeDialog(blocked: true, isFixedDuration: true),
                  child: Text("Yuh huh")
                )
              ],
            );
          }
        );
      }
    );
  }

  Future<void> openBreakDialog(BuildContext context) async{
    double duration;

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
                width: 600,
                height: 300,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Break Length:"),
                          DropdownMenu(
                            dropdownMenuEntries: durationValues,
                            onSelected: (value) {
                              duration = double.parse(value.toString());
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
                            onPressed: () async {
                              Navigator.pop(context);
                              await http.post(
                                Uri.parse("http://127.0.0.1:8000/toggleBreak"),
                                headers: {"Content-Type": "application/json"},
                                body: jsonEncode({
                                  "value": 0
                                })
                              );
                              //TODO: create second timer and setState it to replace the current block timer (can probably use mainSetState)
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

  void closeDialog({required bool blocked, required bool isFixedDuration, double? duration, TimeOfDay? endTime, bool? unblockable}) async{
    setState(() {
      currentlyBlocking = blocked;
    });
    if(mounted) Navigator.pop(context);
    if(blocked){
      final List<List<String>> categorisedApps = validateBlockedApps();
      await http.post(
        Uri.parse("http://127.0.0.1:8000/deleteRegKeys"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "values": categorisedApps[1]
        })
      );

      await http.post(
        Uri.parse("http://127.0.0.1:8000/createRegKeys"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "values": categorisedApps[0]
        })
      );
      setState(() {
        isWaiting = false;
      });
    }
    print("Blocking: $blocked for fixed ($isFixedDuration) duration $duration or until $endTime for ${getDurationInSeconds(endTime ?? TimeOfDay.now(), null)} seconds. Blockable: $unblockable");
    validDuration = false;
  }
}