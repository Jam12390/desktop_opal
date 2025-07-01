import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget{
  const DashboardPage({super.key});

  State<DashboardPage> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage>{
  Widget build(BuildContext context){
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              "wow",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}