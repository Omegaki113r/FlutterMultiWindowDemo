import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// this code will be on github soon

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MainApp(args));
}

// i would like to launch the secondary screen on app launch. but you can use a button to launch the second screen later if you want
class MainApp extends StatelessWidget {
  final List<String> args;
  const MainApp(this.args, {super.key});

  @override
  Widget build(BuildContext context) {
    return args.firstOrNull == "multi_window"
        ? SecondaryWindow(windowID: int.parse(args[1]))
        : const PrimaryWindow(windowID: 0);
  }
}

class PrimaryWindow extends StatelessWidget {
  final int windowID;
  const PrimaryWindow({super.key, required this.windowID});

  @override
  Widget build(BuildContext context) {
    DesktopMultiWindow.createWindow(jsonEncode({'args1': 'Sub window'}))
        .then((value) {
      value
        ..setFrame(const Offset(0, 0) & const Size(1280, 720))
        ..center()
        ..setTitle("Secondary Window")
        ..show();
    });

    return ChangeNotifierProvider(
      create: (context) => CounterProvider(),
      builder: (context, child) {
        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: Row(
                children: [
                  const Spacer(),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<CounterProvider>().decrement();
                        DesktopMultiWindow.invokeMethod(1, "update",
                            "${context.read<CounterProvider>().idx}");
                      },
                      child: const Text(
                        "-",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "${context.watch<CounterProvider>().idx}", // this needs to be changes in to watch
                    style: const TextStyle(fontSize: 40),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<CounterProvider>().increment();
                        DesktopMultiWindow.invokeMethod(1, "update",
                            "${context.read<CounterProvider>().idx}");
                      },
                      child: const Text(
                        "+",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class SecondaryWindow extends StatefulWidget {
  final int windowID;
  const SecondaryWindow({super.key, required this.windowID});

  @override
  State<SecondaryWindow> createState() => _SecondaryWindowState();
}

class _SecondaryWindowState extends State<SecondaryWindow> {
  int _count = 0;

  // this is the function that handles the incoming calls from the main screen.
  Future<dynamic> _handleMethodCallback(
      MethodCall call, int fromWindowID) async {
    if (call.method.toString() == "update") {
      setState(() {
        _count = int.parse(call.arguments as String);
      });
      return 0;
    }
    return 1;
  }

  @override
  void initState() {
    DesktopMultiWindow.setMethodHandler(
        _handleMethodCallback); // we need to register that function. So that we get the calls
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          body: Center(
        child: Text(
          "$_count",
          style: const TextStyle(fontSize: 100),
        ),
      )),
    );
  }
}

class CounterProvider with ChangeNotifier {
  int idx = 0;

  void decrement() {
    --idx;
    notifyListeners();
  }

  void increment() {
    ++idx;
    notifyListeners();
  }
}
