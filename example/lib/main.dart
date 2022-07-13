import 'dart:async';
import 'dart:io';

import 'package:driven/driven.dart';
import 'package:driven/querybuilder/driveExtensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart' as auth;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _driven = Driven(iAcceptTheRisksOfUsingDriven: true);

  @override
  void initState() {
    // _driven = Driven(iAcceptTheRisksOfUsingDriven: true);
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: StreamBuilder<auth.GoogleSignInAccount?>(
        initialData: null,
        stream: _driven.signedInStream.stream,
        builder: (context, account) {
          return Column(
            // Column is also a layout widget. It takes a list of children and
            // arranges them vertically. By default, it sizes itself to fit its
            // children horizontally, and tries to be as tall as its parent.
            //
            // Invoke "debug painting" (press "p" in the console, choose the
            // "Toggle Debug Paint" action from the Flutter Inspector in Android
            // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
            // to see the wireframe for each widget.
            //
            // Column has various properties to control how it sizes itself and
            // how it positions its children. Here we use mainAxisAlignment to
            // center the children vertically; the main axis here is the vertical
            // axis because Columns are vertical (the cross axis would be
            // horizontal).
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (account.data == null)
                ElevatedButton(
                  onPressed: () async {
                    showLoading(context);
                    _driven.authenticateWithGoogle().then((value) {
                      Navigator.of(context).pop();
                    });
                  },
                  child: Text('SIGN INTO GOOGLE SERVICES'),
                ),
              if (account.data != null)
                Column(
                  children: [
                    if (account.data?.photoUrl != null)
                      Card(
                        child: Column(
                          children: [
                            Text(
                              'Signed in as...',
                              style: Theme.of(context).textTheme.headline5,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                CircleAvatar(
                                  child: Image.network(account.data!.photoUrl!),
                                  // maxRadius: 50,
                                  radius: 100,
                                ),
                                Text(account.data!.displayName ?? 'No display name?')
                              ],
                            ),
                          ],
                        ),
                      ),
                    ElevatedButton(
                        onPressed: () {
                          showLoading(context);
                          _driven.signOut().then((value) => Navigator.of(context).pop());
                        },
                        child: Text('SIGN OUT')),
                    ElevatedButton(
                      onPressed: () {
                        showDialog<String>(
                            context: context,
                            builder: (builder) {
                              String path = "";
                              return AlertDialog(
                                title: Text('Create a new folder'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('What path should we create? It must be a path/like/this.'),
                                    TextField(
                                      onChanged: (newPath) => path = newPath,
                                    ),
                                    ElevatedButton(
                                      child: Text('CREATE'),
                                      onPressed: () {
                                        showLoading(context);

                                        _driven.createFolderPath(path).then((value) => Navigator.of(context).pop()).onError((error, stackTrace) {
                                          Navigator.pop(context);
                                          showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                    title: Text('Error'),
                                                    content: Text(error.toString()),
                                                  ));
                                        });
                                      },
                                    )
                                  ],
                                ),
                              );
                            });
                        final authenticated = GoogleAuthClient();

                        // drive.DriveApi().files.create(request)
                      },
                      child: Text('CREATE A FOLDER'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        showDialog(
                          context: context,
                          builder: (context) {
                            String? filePath;
                            String? fileContents;
                            return AlertDialog(
                              title: Text('Create a text file'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    decoration: InputDecoration(hintText: 'File Path on Google Drive (like /path/to/file.txt)'),
                                    onChanged: (val) {
                                      filePath = val;
                                    },
                                  ),
                                  TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Contents of file',
                                    ),
                                    onChanged: (val) {
                                      fileContents = val;
                                    },
                                  ),
                                  ElevatedButton(
                                      onPressed: () async {
                                        if (filePath == null || fileContents == null) {
                                          showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                    title: Text('Please fill out the fields.'),
                                                  ));
                                        } else {
                                          final tempFile = await getTemporaryDirectory();
                                          final file = File(tempFile.path + '/tempfile.txt');
                                          file.writeAsString(fileContents ?? 'Test from driven!');
                                          await drive.DriveApi(GoogleAuthClient()).pushFile(file, filePath!); // already checked for null
                                        }
                                      },
                                      child: Text('CREATE FILE')),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: Text('CREATE A PLAIN TEXT FILE'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        showDialog(
                          context: context,
                          builder: (context) => SimpleDialog(
                            contentPadding: EdgeInsets.all(20),
                            title: Text('Create a folder with contents'),
                            children: [
                              Text(
                                  'This will create a folder on your local device with some files in it, and then send that folder to Google Drive.'),
                              ElevatedButton(
                                onPressed: () async {
                                  final tempDirectory = await getTemporaryDirectory();
                                  final tempPath = (await tempDirectory.createTemp()).path;
                                  for (int i = 0; i < 10; i++) {
                                    final newDir = Directory('$tempPath/${i.toString()}/${i.toString()}/${i.toString()}/${i.toString()}');
                                    await newDir.create(recursive: true);
                                    final testFile = File('${newDir.path}/testfile.txt');
                                    await testFile.writeAsString('Its just test content.');
                                    print('created test file ${testFile.path} with some content.');
                                  }

                                  final created =
                                      await drive.DriveApi(GoogleAuthClient()).pushFolder(Directory(tempPath), 'Driven Folder Test').toList();
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Created some files and folders.'),
                                      content: Text(
                                        created.last.toString(),
                                      ),
                                    ),
                                  );
                                },
                                child: Text('MAKE IT SO'),
                              )
                            ],
                          ),
                        );
                      },
                      child: Text('CREATE AND COPY FOLDER'),
                    )
                  ],
                )
            ],
          );
        },
      ),
    );
  }

  void showLoading(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) => Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ));
  }
}

// class LoginManager{
//   // Normally, this would be in a BLOC or something
//
//   final loginStatus = StreamController<auth.GoogleSignInAccount>();
//
//
//
// }
