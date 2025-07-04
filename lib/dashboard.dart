import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget{
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> with WidgetsBindingObserver{
  late Size currentSize;
  late double blockedWidth = View.of(context).physicalSize.width;
  final double blockedWidthRatio = 3.25; //width ratio of left half to right half of dashboard

  //this is an affront to god.
  //i dont know how i got this equation
  //i know that *(2/3) stopped the variable overflow
  //and then i took away the padding from each widget which solved a problem
  //but then the bottom kept on overflowing on startup and i dont know why so ive ended up with this
  //this works well enough to appease me
  //but just dont try to fix this
  //for your own sake
  late double blockedHeight = View.of(context).physicalSize.height - 91;

  //height ratio of blocked bar to notifications e.g. 1 : 14 with a height of 600px would give 40px : 560px
  late double blockedDurationHeight = 50;
  final double blockedHeightRatio = 10;
  //height ratio to the blocked textbox to the duration bar e.g. 9 : 1 with a height of 600px and a height ratio of 15 would give 36px : 4px
  final double blockedDurationHeightRatio = 10;

  late TextStyle defaultText = TextStyle(
    fontSize: (blockedDurationHeight * ((blockedDurationHeightRatio-1)/blockedDurationHeightRatio)) * (1/3),
    color: Colors.white,
  );

  WidgetsBinding get widgetBinding => WidgetsBinding.instance;

  @override
  void didChangeDependencies(){
    super.didChangeDependencies();
    currentSize = View.of(context).physicalSize;
    widgetBinding.addObserver(this);
  }

  @override
  void dispose(){
    widgetBinding.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics(){
    currentSize = View.of(context).physicalSize;
    setState(() {
      blockedWidth = currentSize.width;
      print(currentSize.height);
      blockedHeight = currentSize.height - 88;
      blockedDurationHeight = blockedHeight * (1/blockedDurationHeightRatio);
      //dont even ask i have no idea why this needs to be divided by 3 flutter thinks that the width of the window is 1200 when its actually 600
    });
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16, right: 16, left: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(topRight: Radius.circular(10), topLeft: Radius.circular(10)),
                    color: Colors.grey[900],
                  ),
                  height: blockedDurationHeight * ((blockedDurationHeightRatio-1)/blockedDurationHeightRatio),
                  width: blockedWidth/blockedWidthRatio,
                  child: Padding(
                    padding: EdgeInsets.all(8 *((blockedDurationHeightRatio-1)/blockedDurationHeightRatio)),
                    child: Text("Currently Blocked Ex.", style: defaultText),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16)),
                        color: Colors.cyan[400],
                      ),
                      width: (blockedWidth/blockedWidthRatio)*(2/3),
                      height: blockedDurationHeight * (1/blockedDurationHeightRatio),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(bottomRight: Radius.circular(16)),
                        color: Colors.blueGrey[800],
                      ),
                      width: (blockedWidth/blockedWidthRatio)*(1/3),
                      height: blockedDurationHeight * (1/blockedDurationHeightRatio),
                    )
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                      color: Colors.grey,
                    ),
                    width: blockedWidth/blockedWidthRatio,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("no worky", style: defaultText,),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            //Padding(
            //  padding: EdgeInsets.all(16),
            //  child: Container(
            //    decoration: BoxDecoration(
            //      color: Colors.grey[900],
            //    ),
            //    width: blockedWidth/blockedWidthRatio,
            //    height: blockedHeight * ((blockedHeightRatio-1)/blockedHeightRatio),
            //    child: Text("Notifications Ex.", style: TextStyle(color: Colors.white),),
            //  ),
            //)
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.all(Radius.circular(16))
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Pie Chart", style: defaultText,)
                    ],
                  ),
                ),
              ),
            )
          )
        ],
      ),
    );
  }
}