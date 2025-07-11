import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget{
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => DashboardState();
}

class DashboardState extends State<Dashboard> with WidgetsBindingObserver{
  late Size dimensions;

  final BoxDecoration defaultDecor = BoxDecoration(
    color: Colors.grey[900],
    borderRadius: BorderRadius.all(Radius.circular(16))
  );
  late TextStyle defaultText = TextStyle(
    color: Colors.white,
    fontSize: ((dimensions.height * 0.03) + (dimensions.width * 0.02)) / 2 //0.05 and 0.025 are the weightings that the width and height of the window have in respect to the fontsize
  );

  WidgetsBinding get widgetBinding => WidgetsBinding.instance;

  @override
  void didChangeDependencies(){
    super.didChangeDependencies();
    dimensions = MediaQuery.of(context).size;
    widgetBinding.addObserver(this);
  }

  @override
  void dispose(){
    super.dispose();
    widgetBinding.removeObserver(this);
  }

  @override
  void didChangeMetrics(){
    setState(() {
      dimensions = MediaQuery.of(context).size;
      defaultText = TextStyle(
        color: Colors.white,
        fontSize: ((dimensions.height * 0.025) + (dimensions.width * 0.01)) / 2 //0.05 and 0.025 are the weightings that the width and height of the window have in respect to the fontsize
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
                child: Container(
                  decoration: defaultDecor,
                  width: MediaQuery.of(context).size.width/2,
                  height: 75,
                  child: Text("data"),
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
    );
  }
}