import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bloc/bloc.dart';

import 'dart:developer' as devtools show log;

void main() {
  runApp(const MyApp());
}

extension Log on Object {
  void log() => devtools.log(toString());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => PersonsBloc(),
        )
      ],
      child: MaterialApp(
        title: 'FlutterDemo',
        theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}

List<String> names = <String>[
  "Rahul",
  "Rohith",
  "Neethu",
  "Vishnu",
  "Renjeesh",
  "Ajinshad",
  "Hanoy",
  "Sarath",
  "Adarsh",
  "Prabeesh",
  "Unnikrishnan"
];

extension<T> on Iterable<T> {
  T getRadomElement() => elementAt(Random().nextInt(length));
}

class NamesCubit extends Cubit<String?> {
  NamesCubit() : super('');

  void pickRandomName() {
    emit(names.getRadomElement());
  }
}

@immutable
abstract class LoadAction {
  const LoadAction();
}

enum PersonUrl { personOne, personTwo }

class LoadPersonAction extends LoadAction {
  final PersonUrl url;

  const LoadPersonAction({required this.url}) : super();
}

@immutable
class Fetchresult {
  final Iterable<Person> persons;
  final bool isRetrievedFromcache;

  const Fetchresult({
    required this.persons,
    required this.isRetrievedFromcache,
  });

  @override
  String toString() {
    return 'FetchResult(isRetrievedFromcache : $isRetrievedFromcache, persons: $persons)';
  }
}



class PersonsBloc extends Bloc<LoadAction, Fetchresult?> {
  final Map<PersonUrl, Iterable<Person>> _cache = {};
  PersonsBloc() : super(null) {
    on<LoadPersonAction>((event, emit) async {
      final url = event.url;
      if (_cache.containsKey(url)) {
        final cachedPersons = _cache[url];
        final result = Fetchresult(
          persons: cachedPersons ?? [],
          isRetrievedFromcache: true,
        );
        emit(result);
      } else {
        final persons = await fetchPersons(url.urlString);

        _cache[url] = persons;
        

        final result = Fetchresult(
          persons: persons,
          isRetrievedFromcache: false,
        );
        emit(result);
      }
    });
  }
}

extension UrlString on PersonUrl {
  String get urlString {
    switch (this) {
      case PersonUrl.personOne:
        return "lib/api/person1.json";
      case PersonUrl.personTwo:
        return "lib/api/person2.json";
      default:
        return "lib/api/person1.json";
    }
  }
}

// Model

class Person {
  final String name;
  final double age;

  const Person({required this.name, required this.age});

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        name: json["name"],
        age: json["age"],
      );
}

Future<Iterable<Person>> fetchPersons(String url) => HttpClient()
    .getUrl(Uri.parse(url))
    .then((req) => req.close())
    .then((res) => res.transform(utf8.decoder).join())
    .then((str) => json.decode(str) as List<dynamic>)
    .then((list) => list.map((e) => Person.fromJson(e)));

extension Subscript<T> on Iterable<T> {
  T? operator [](int index) => length > index ? elementAt(index) : null;
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final NamesCubit namesCubit;

  @override
  void initState() {
    super.initState();
    namesCubit = NamesCubit();
  }

  @override
  void dispose() {
    namesCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView(
        children: [
          TextButton(
              onPressed: () {
                context
                    .read<PersonsBloc>()
                    .add(const LoadPersonAction(url: PersonUrl.personOne));
              },
              child: const Text("LOAD JSON 1")),
          TextButton(
              onPressed: () {
                context
                    .read<PersonsBloc>()
                    .add(const LoadPersonAction(url: PersonUrl.personTwo));
              },
              child: const Text("LOAD JSON 2")),
          BlocBuilder<PersonsBloc, Fetchresult?>(
            buildWhen: (previous, current) =>
                previous?.persons != current?.persons,
            builder: (context, state) {
              final persons = state?.persons;
              if (persons == null) {
                return const Text("EMPTY LIST OF PERSONS");
              } else {
                return Expanded(
                    child: ListView.builder(
                  itemCount: persons.length,
                  itemBuilder: (context, index) {
                    final person = persons[index];
                    return ListTile(
                      title: Text(person?.name ?? "No name"),
                      subtitle: Text("${person?.age}"),
                    );
                  },
                ));
              }
            },
          ),
          StreamBuilder<String?>(
              stream: namesCubit.stream,
              builder: (context, snapshot) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'NAME :: ${snapshot.data}',
                      ),
                    ],
                  ),
                );
              }),
          ElevatedButton(onPressed: () {}, child: const Text("Load Users"))
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          namesCubit.pickRandomName();
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
