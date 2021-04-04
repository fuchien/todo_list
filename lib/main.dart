import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(home: Home()));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _toDoController = TextEditingController();
  List _todoList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _readData().then((data) {
      setState(() {
        _todoList = json.decode(data);
      });
    });
  }

  void _addToDo() {
    if (_toDoController.text.isEmpty) return;
    setState(() {
      Map<String, dynamic> _newTodo = Map();
      _newTodo['title'] = _toDoController.text;
      _toDoController.text = '';
      _newTodo['ok'] = false;
      _todoList.add(_newTodo);
      _saveData();
    });
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _todoList.sort((a, b) {
        if (a['ok'] && !b['ok'])
          return 1;
        else if (!a['ok'] && b['ok'])
          return -1;
        else
          return 0;

        _saveData();
      });

      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Tarefas!'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(children: [
              Expanded(
                  child: TextField(
                controller: _toDoController,
                decoration: InputDecoration(
                    labelText: 'Nova Tarefa',
                    labelStyle: TextStyle(color: Colors.blueAccent)),
              )),
              ElevatedButton(
                onPressed: _addToDo,
                child: Text(
                  'ADD',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(primary: Colors.blueAccent),
              )
            ]),
          ),
          Expanded(
              child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
                padding: EdgeInsets.only(top: 10),
                itemCount: _todoList.length,
                itemBuilder: buildItem),
          ))
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().microsecondsSinceEpoch.toString()),
      background: Container(
          color: Colors.red,
          child: Align(
              alignment: Alignment(0.9, 0),
              child: Icon(Icons.delete, color: Colors.white))),
      direction: DismissDirection.endToStart,
      child: CheckboxListTile(
        title: Text(_todoList[index]['title']),
        value: _todoList[index]['ok'],
        secondary: CircleAvatar(
          child: Icon(_todoList[index]['ok'] ? Icons.check : Icons.error),
        ),
        onChanged: (c) {
          setState(() {
            _todoList[index]['ok'] = c;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_todoList[index]);
          _lastRemovedPos = index;
          _todoList.removeAt(index);

          _saveData();

          final snack = SnackBar(
            content: Text('Tarefa \"${_lastRemoved['title']}\" removida!'),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    _todoList.insert(_lastRemovedPos, _lastRemoved);
                    _saveData();
                  });
                }),
            duration: Duration(seconds: 3),
          );

          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/data.json');
  }

  Future<File> _saveData() async {
    String data = json.encode(_todoList);

    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (error) {
      return null;
    }
  }
}
