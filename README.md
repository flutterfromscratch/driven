![logo](logo.jpg)

# Driven

### An easier Google Drive experience

Features:

* Use path constructs that you are familiar with to operate within Google Drive
* Copy files to Google Drive
* Copy folders *recursively* to Google Drive
* Uses Dart Extension Methods to build on existing functionality in the Google Drive API, so you can still use the vanilla Google Drive API for specific use cases
* Copy files *recursively* to local device from Google Drive (coming soon)
* One-way sync from local folders to Google Drive (coming soon)

In the future:

* All the things noted with "coming soon" above
* A way to copy to "application storage" instead of the users' drive
* Tests 🔬



### Why?

Trying to use the official Google libraries to copy files and folders to Google Drive is a true experience. They allow for incredible flexibility and an almost endless array of choices. However, this leads to the humble developer (read: me) being like "okay, but I just want to copy a folder to the users' Google Drive?".

Driven aims to resolve this by letting you use plain `Directory` or `File` objects from Dart to upload files to the users' Google Drive. Once the user allows your app to interact with their Drive, you can just copy stuff to where you would like.

Also, Driven copies to the users' Google Drive. It does not make use of the "application storage" feature that Google Drive offers. The reason for this is that it does not seem easy to navigate the files and folders created in app storage. So, if an app uses this hidden storage within Google Drive and then the app becomes unmaintained or is abandoned, what would you do then? The obvious tradeoff is that copying files directly into Google Drive means that the user can manually modify files and possibly break things. In the future, copying to the users' app storage within Google Drive will be added to Driven.

### Caveats

I'm not aware of any immediate, world-stopping issues with Driven, and I use it in my apps. *However*, interacting with a users' Google Drive, where they keep their stuff, is **serious business**. Depending on how you configure your app, you could wind up overwriting or deleting files on the users' Drive. That's obviously a really poor experience. Don't do that.

You should also read and familiarise yourself with the code before using it in your projects, to at least give yourself some kind of assurance that this library behaves in a safe way. Don't just slap it in `pubspec.yaml` and hope for the best - if you are interacting with a users' Drive, they expect you to do so responsibly. So do the responsible thing, and skim the library, to make sure it doesn't just delete everything.

### Usage

In order to use Driven, there is a bit of confusing setup you have to do. Configuring your apps with Firebase in Flutter is pretty epic in itself, and there is a lot of conflicting information out there on how to do this. My steps to get this working are as follows:

1. Create a new project on the Google Cloud Console (https://console.cloud.google.com/apis/dashboard)
2. Enable the Google Drive API
3. Create the same app on Firebase
4. Download appropriate .json or .plist file for your app, and copy it to the appropriate location within your app. Or, 

*In the future, I plan to create a video showing these steps, and how to use Driven in a sample project*.

### API

Most of what Driven provides are extensions to the `DriveApi` object provided by the Google Drive API. These are the functions at the moment:

```dart
Future<drive.File> createFolder(final String folderName, {final String? parent}) 
```

Creates an empty folder on Google Drive. If the parent variable is specified, creates the folder within the specified parent. (Note: the parent is the ID of the folder on Google Drive).

```dart
Future<List<FolderPathBit>> createFoldersRecursively(final String folderPath)
```

Creates a `path/like/this` on the users' Google Drive. Returns a list of created folders, and their ID's.

```dart
Future<drive.File> pushFile(final File file, final String path, {final String? mimeType})
```

Copies a file from the local device to the users' Google Drive, within the `path` variable. If the specified path does not exist, creates the path, and then copies the file to it. You can specify the `mimeType` of the file manually, or if you don't, Driven will use the `mime` package to try to guess the mime type by file extension.

```dart
Stream<FolderPushProgress> pushFolder(final Directory directory, final String destinationDirectory)
```

Recursively copies a local `Directory` object to Google Drive. This function is a little bit slow at the moment, but work is being done to speed it up.

```dart
Future<List<FolderPathBit>> getFolderPathAsIds(final String path) 
```

If you have a `path/like/this`, this function will retrieve the ID's of these folders for you. You can use these to determine if a folder exists already.

#### Query Helpers

Driven also ships with a very short amount of "Query Helpers" that help you write queries for the Google Drive API. As of right now, there is only the `fileQuery`, which helps you write a query for a file that has not been trashed, and also checks for files in directories.

## Support

Creating plugins like Driven takes a lot of time, so if you have a few dollars to spare, feel free to sponsor me on GitHub: https://github.com/sponsors/flutterfromscratch

You can also buy me a coffee: https://www.buymeacoffee.com/flutterscratch

Or, you can subscribe to my YouTube channel: https://www.youtube.com/channel/UCYZ6TTC9EgfDTFGz4UC-GJw