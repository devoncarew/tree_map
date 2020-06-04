import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' hide log;

import 'package:flutter/material.dart';

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
      home: MyHomePage(title: 'Flutter Demo Home Page'),
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
  TreeModel model;

  Timer _timer;

  @override
  void initState() {
    super.initState();

    model = TreeModel.create();
  }

  void _throwException1() {
    print('throwing');

    int sdf = 34345;
    String dsdf = "dfsf";

    throw 'bar';
  }

  void _throwException2() {
    throw DateTime.now();
  }

  void _toggleChanges() async {
    developer.log(
      'toggling changes',
      name: 'foo-log',
      error: "I'm an error",
    );

    final myMap = <String, dynamic>{
      'item': 1,
      'stuff': '4rwr',
      'and': DateTime.now(),
    };

    _processMapStatic(myMap);

    _processMapFunction(myMap);

    await Future.sync(() {
      return 'stuff';
    });

    (String parameter) {
      var closureLocalInsideMethod = '$myMap/$parameter';
      print(closureLocalInsideMethod);
      return closureLocalInsideMethod; // Breakpoint: nestedClosure
    }('myParam');

    final mySet = {0, 1, 2, 3, 4};

    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    } else {
      setState(model.jiggle);
      _timer = Timer.periodic(Duration(milliseconds: 1000), (timer) {
        setState(model.jiggle);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TreeMap(model),
        ),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: _toggleChanges,
            tooltip: 'Toggle Changes',
            child: Icon(Icons.aspect_ratio),
          ),
          SizedBox(width: 12.0),
          FloatingActionButton(
            onPressed: _throwException1,
            tooltip: 'Throw exception',
            child: Icon(Icons.camera),
          ),
          SizedBox(width: 12.0),
          FloatingActionButton(
            onPressed: _throwException2,
            tooltip: 'Throw exception',
            child: Icon(Icons.camera),
          ),
        ],
      ),
    );
  }

  static void _processMapStatic(Map<String, dynamic> map) {
    map['static'] = true;
  }
}

void _processMapFunction(Map<String, dynamic> map) {
  map['function'] = true;
}

class TreeMap extends StatefulWidget {
  TreeMap(this.model);

  final TreeModel model;

  @override
  _TreeMapState createState() => _TreeMapState();
}

const kDivider = 2.0;

class _TreeMapState extends State<TreeMap> {
  @override
  Widget build(BuildContext context) {
    // todo: try using a Stack and n AnimatedPositioneds widgets

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Map<TreeNode, Rect> positions = widget.model.layout(constraints);

        return Container(
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: Colors.black, width: kDivider),
            borderRadius: BorderRadius.circular(kDivider * 2),
          ),
          child: Stack(
            children: widget.model.nodes.map((node) {
              Rect rect = positions[node];
              return AnimatedPositioned.fromRect(
                key: ObjectKey(node),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                rect: rect,
                child: TreeNodeWidget(node),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class TreeModel {
  static TreeModel create() {
    final TreeModel model = TreeModel([
      _rnd('one', Colors.blue[200]),
      _rnd('two', Colors.blue[300]),
      _rnd('three', Colors.blue[400]),
      _rnd('four', Colors.blue[500]),
      _rnd('five', Colors.blue[600]),
      _rnd('six', Colors.red[200]),
      _rnd('seven', Colors.red[300]),
    ]);

    model.sort();

    for (TreeNode node in model.nodes.sublist(0, 3)) {
      final int count = Random().nextInt(3) * 2 + 1;
      for (int i = 0; i < count; i++) {
        // todo: mutate the color
        node.children.add(_rnd('${node.name}-$count', node.color));
      }
    }

    return model;
  }

  static TreeNode _rnd(String name, Color color) {
    return TreeNode(name, color, Random().nextDouble() * 100);
  }

  TreeModel(this.nodes);

  final List<TreeNode> nodes;

  void sort() {
    nodes.sort((a, b) {
      if (a.size == b.size) return 0;
      return a.size - b.size > 0.0 ? -1 : 1;
    });
  }

  void jiggle() {
    final rnd = Random();

    for (final node in nodes) {
      node.size = node.size * (1.0 + (rnd.nextDouble() - 0.5) / 5.0);
    }

    sort();

    print('largest node: ${nodes.first}');
  }

  Map<TreeNode, Rect> layout(BoxConstraints constraints) {
    Map<TreeNode, Rect> layouts = {};
    _layout(
      layouts,
      Rect.fromLTWH(
        0,
        0,
        constraints.maxWidth,
        constraints.maxHeight,
      ),
      nodes,
    );
    return layouts;
  }

  void _layout(Map<TreeNode, Rect> layouts, Rect rect, List<TreeNode> nodes) {
    TreeNode node = nodes.first;

    if (nodes.length == 1) {
      layouts[node] = rect;
      return;
    }

    final total = nodes.map((n) => n.size).fold<double>(0.0, (a, b) => a + b);
    final ratio = node.size / total;

    if (rect.width > rect.height) {
      layouts[node] =
          Rect.fromLTWH(rect.left, rect.top, rect.width * ratio, rect.height);
      _layout(
        layouts,
        Rect.fromLTWH(
          rect.left + rect.width * ratio,
          rect.top,
          rect.width * (1 - ratio),
          rect.height,
        ),
        nodes.sublist(1),
      );
    } else {
      _layout(
        layouts,
        Rect.fromLTWH(
          rect.left,
          rect.top,
          rect.width,
          rect.height * (1 - ratio),
        ),
        nodes.sublist(1),
      );
      layouts[node] = Rect.fromLTWH(
        rect.left,
        rect.top + rect.height * (1 - ratio),
        rect.width,
        rect.height * ratio,
      );
    }
  }
}

class TreeNode {
  TreeNode(this.name, this.color, this.size) {
    size *= size;
  }

  final String name;
  final Color color;

  double size;

  List<TreeNode> children = [];

  String toString() => '$name $size';
}

class TreeNodeWidget extends StatelessWidget {
  TreeNodeWidget(this.node);

  final TreeNode node;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: node.color,
        border: Border.all(color: Colors.black, width: kDivider),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Flexible(
                child: Text(
                  node.name,
                  style: TextStyle(fontSize: 18.0),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              Flexible(
                child: Text(
                  _sizeLabel(node.size),
                  style: TextStyle(fontSize: 18.0),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _sizeLabel(double size) {
    return (size / 1024.0).toStringAsFixed(2) + 'k';
  }
}
