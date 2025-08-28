import 'package:day_night_time_picker/day_night_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:desktop_opal/funcs.dart' as funcs;
import 'package:desktop_opal/main.dart' as mainScript;

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

class DashboardState extends State<Dashboard> with WidgetsBindingObserver{
  final BoxDecoration defaultDecor = BoxDecoration(
    color: Colors.grey[900],
    borderRadius: BorderRadius.all(Radius.circular(16))
  );
  late TextStyle defaultText = TextStyle(
    color: Colors.white,
    fontSize: funcs.recalculateTextSize(context, []) //0.05 and 0.025 are the weightings that the width and height of the window have in respect to the fontsize
  );

  late bool currentlyBlocking = true; //dont change using a json later as the glory of enums are here
  bool validDuration = false;
  late DateTime time;
  late bool timeChosen = false;
  late DateTime startingTime;
  //late String timeAsText = "";

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
    return Scaffold(
      body: Row(
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
                      width: MediaQuery.of(context).size.width/2,
                      height: 65,
                      child: Text("data", style: defaultText,),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.cyan[400],
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16))
                      ),
                      height: 10,
                      width: MediaQuery.of(context).size.width/2,
                      child: Text("data", style: defaultText,),
                    )
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16, left: 16, right: 8),
                  child: Container(
                    decoration: defaultDecor,
                    width: MediaQuery.of(context).size.width/2,
                    height: MediaQuery.of(context).size.height,
                    child: Text("data", style: defaultText,),
                  ),
                ),
              )
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 16, left: 8, right: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.all(Radius.circular(16))
                ),
                width: MediaQuery.of(context).size.width/2 - 24,
                height: MediaQuery.of(context).size.height,
                child: Text("data2", style: defaultText,),
              ),
            )
          )
        ],
      ),
      floatingActionButton: SizedBox(
        width: 130,
        child: FloatingActionButton(
          onPressed: () async {
            if(currentlyBlocking){
              await openBreakDialog(); //will probably need context here too
            } else{
              await openBlockingDialog(context);
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
                                  timeAsText = time.hour.toString() + ':' + time.minute.toString();
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
                    closeDialog(blocked: false)
                  },
                  child: Text("Nu uh")
                ),
                TextButton(
                  onPressed: () => closeDialog(blocked: true),
                  child: Text("Yuh huh")
                )
              ],
            );
          }
        );
      }
    );
  }

  //Future openBlockingDialog() => showDialog(
  //  context: context, 
  //  builder: (context) => AlertDialog(
  //    content: Column(
  //      children: [
  //        Row(
  //          mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //          children: [
  //            Text("DateTime"),
  //            Text(timeAsText),
  //            TextButton(
  //              onPressed: () => {
  //                startingTime = DateTime.now(),
  //                time = DateTime.now(),
  //                setState(() {
  //                  timeChosen = true;
  //                  print(time);
  //                }),
  //                Navigator.of(context).push(
  //                  showPicker(
  //                    value: Time(hour: DateTime.now().hour, minute: DateTime.now().minute+1),
  //                    //minHour: DateTime.now().hour.toDouble(),
  //                    //minMinute: time.hour == startingTime.hour ? DateTime.now().minute.toDouble() : 0,
  //                    is24HrFormat: true,
  //                    onChange: (p0) {},
  //                    onChangeDateTime: (datetime) => {
  //                      setState(() {
  //                        time = datetime;
  //                        timeAsText = time.hour.toString() + ' ' + time.minute.toString();
  //                      })
  //                    }
  //                  )
  //                )
  //              },
  //              child: Text("Choose")
  //            )
  //          ],
  //        )
  //      ],
  //    ),
  //    actions: [
  //      TextButton(
  //        onPressed: () => {
  //          timeChosen = false,
  //          closeDialog(blocked: false)
  //        },
  //        child: Text("Nu uh")
  //      ),
  //      TextButton(
  //        onPressed: () => closeDialog(blocked: true),
  //        child: Text("Yuh huh")
  //      )
  //    ],
  //  )
  //);

  Future openBreakDialog() => showDialog(
    context: context,
    builder: (context) => AlertDialog(
      content: Column(

      ),
    )
  );

  void closeDialog({bool blocked = false, int? duration}){
    setState(() {
      currentlyBlocking = blocked;
    });
    validDuration = false;
    Navigator.pop(context);
  }
}