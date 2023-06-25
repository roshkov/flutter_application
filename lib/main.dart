import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carp_core/carp_core.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:pedometer/pedometer.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(),
      ),
    );
  }

  /// This is an example of how to set up a the most minimal study
  static Future<void> example() async {
    // Create a study protocol
    SmartphoneStudyProtocol protocol = SmartphoneStudyProtocol(
      ownerId: 'AB',
      name: 'Track patient movement',
    );

    // Define which devices are used for data collection.
    // In this case, its only this smartphone
    var phone = Smartphone();
    protocol.addMasterDevice(phone);

    // Automatically collect step count, ambient light, screen activity, and
    // battery level. Sampling is delaying by 10 seconds.
    protocol.addTriggeredTask(
        DelayedTrigger(delay: Duration(seconds: 10)),
        BackgroundTask(name: 'Sensor Task')
          ..addMeasures([
            Measure(type: SensorSamplingPackage.PEDOMETER),
            Measure(type: SensorSamplingPackage.LIGHT),
            Measure(type: DeviceSamplingPackage.SCREEN),
            Measure(type: DeviceSamplingPackage.BATTERY),
          ]),
        phone);

    // Create and configure a client manager for this phone, and
    // create a study based on the protocol.
    SmartPhoneClientManager client = SmartPhoneClientManager();
    await client.configure();
    Study study = await client.addStudyProtocol(protocol);

    // Get the study controller and try to deploy the study.
    SmartphoneDeploymentController? controller = client.getStudyRuntime(study);
    await controller?.tryDeployment();

    // Configure the controller.
    await controller?.configure();

    // Start the study
    controller?.start();

    // Listening and print all data events from the study
    controller?.data.forEach(print);
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();

  void getNext() {
    current = WordPair.random();
    notifyListeners(); //people who watch this state, will get notified
  }

  var favorites = <WordPair>[]; //list
  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;
  String _status = '?', _steps = '?';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  void onStepCount(StepCount event) {
    print(event);
    setState(() {
      _steps = event.steps.toString();
    });
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    print(event);
    setState(() {
      _status = event.status;
    });
  }

  void onPedestrianStatusError(error) {
    print('onPedestrianStatusError: $error');
    setState(() {
      _status = 'Pedestrian Status not available';
    });
    print(_status);
  }

  void onStepCountError(error) {
    print('onStepCountError: $error');
    setState(() {
      _steps = 'Step Count not available';
    });
  }

  void initPlatformState() {
    _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
    _pedestrianStatusStream
        .listen(onPedestrianStatusChanged)
        .onError(onPedestrianStatusError);

    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(onStepCount).onError(onStepCountError);

    if (!mounted) return;
  }

  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Pedometer Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Steps Taken',
                style: TextStyle(fontSize: 30),
              ),
              Text(
                _steps,
                style: TextStyle(fontSize: 60),
              ),
              Divider(
                height: 100,
                thickness: 0,
                color: Colors.white,
              ),
              Text(
                'Pedestrian Status',
                style: TextStyle(fontSize: 30),
              ),
              Icon(
                _status == 'walking'
                    ? Icons.directions_walk
                    : _status == 'stopped'
                        ? Icons.accessibility_new
                        : Icons.error,
                size: 100,
              ),
              Center(
                child: Text(
                  _status,
                  style: _status == 'walking' || _status == 'stopped'
                      ? TextStyle(fontSize: 30)
                      : TextStyle(fontSize: 20, color: Colors.red),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

//   @override
//   Widget build(BuildContext context) {
//     MyApp.example();
//     Widget page;
//     switch (selectedIndex) {
//       case 0:
//         page = GeneratorPage();
//         break;
//       case 1:
//         page = FavoritesPage();
//         break;
//       default:
//         throw UnimplementedError('no widget for $selectedIndex');
//     }

//     return Scaffold(
//       body: Row(
//         children: [
//           SafeArea(
//             child: NavigationRail(
//               extended: false,
//               destinations: [
//                 NavigationRailDestination(
//                   icon: Icon(Icons.home),
//                   label: Text('Home'),
//                 ),
//                 NavigationRailDestination(
//                   icon: Icon(Icons.favorite),
//                   label: Text('Favorites'),
//                 ),
//               ],
//               selectedIndex: selectedIndex,
//               onDestinationSelected: (value) {
//                 setState(() {
//                   selectedIndex = value;
//                 });
//               },
//             ),
//           ),
//           Expanded(
//             //give me as much space possible as there is
//             child: Container(
//               color: Theme.of(context).colorScheme.primaryContainer,
//               child: page,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BigCard(pair: pair),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var favorites = appState.favorites;

    if (favorites.isEmpty) {
      return Center(
        child: Text('No favs yet'),
      );
    }

    return Center(
      child: ListView(
        children: [
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Favorites: '),
          ),
          for (var fav in favorites)
            ListTile(
              leading: Icon(Icons.favorite),
              title: Text(fav.asLowerCase),
            ),
        ],
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    var theme =
        Theme.of(context); //goes to main widget and takes theme from there
    var style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );
    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Text(
          pair.asLowerCase,
          style: style,
          semanticsLabel: pair.asPascalCase,
        ),
      ),
    );
  }
}
