import 'package:flutter/material.dart';
import 'package:hi_chart/src/barChart/hi_bar_chart.dart';
import 'package:hi_chart/src/bean/chart_bean.dart';
import 'package:hi_chart/src/lineChart/hi_line_chart.dart';
import 'dart:math' as math;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: '123'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int value = 22;
  int value2 = 30;

  void _incrementCounter() {
    setState(() {
      value = math.Random().nextInt(50);
      value2 = math.Random().nextInt(50);
    });
  }

  @override
  Widget build(BuildContext context) {
    List<ChartBean> lineData = [
      ChartBean('river', 120),
      ChartBean('mike', value),
      ChartBean('nini', 36),
      ChartBean('iko', 33),
      ChartBean('goust', value2),
      ChartBean('faker', 99.8),
      ChartBean('jake', 77),
      ChartBean('ant', 45),
      ChartBean('lolo', 56),
      ChartBean('banana', 20),
      ChartBean('apple', 18),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HiLineChart(
              data: lineData,
              height: 300,
            ),
            Container(
              margin: EdgeInsets.only(top: 30),
              child: HiBarChart(
                data: lineData,
                height: 300,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
