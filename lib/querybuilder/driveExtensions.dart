import 'dart:async';
import 'dart:io';

import 'package:driven/tools/md5.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart' as googleAuth;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

import '../driven.dart';
import 'shared.dart';
import 'package:path/path.dart' as p;

extension Folder on drive.DriveApi {
  /// Creates a folder, and returns the Google Drive File type.
  /// parents: Pass a list of folder ID's that form the path to where this file should be. Use `getFolderPathAsIds` to get these.
  Future<drive.File> createFolder(final String folderName, {final String? parent}) async {
    final folderId = await files.create(
      drive.File(name: folderName, mimeType: MimeType.folder, parents: parent == null ? [] : [parent]),
    );
    return folderId;
  }

  /// Converts a specified path like 'path/to/folder' to folders.
  /// Ignores already created folders, and creates requested folders within them.
  /// Returns a list of FolderPathBit
  Future<List<FolderPathBit>> createFoldersRecursively(final String folderPath) async {
    final folderRecursion = await getFolderPathAsIds(folderPath);
    final processedPaths = <FolderPathBit>[];

    int depth = 0;

    for (final folder in folderRecursion) {
      if (folder.id != null) {
        print('${folder.name} already exists, moving to the next folder down the tree...');
        processedPaths.add(folder);
      } else {
        print('creating ${folder.name} in tree...');
        final folderId = await createFolder(
          folder.name,
          parent: processedPaths.isNotEmpty ? processedPaths.last.id : null, // only folders with ID's are added to the list
        );
        processedPaths.add(FolderPathBit(folderId.name!, folderId.id, depth++));
      }
      print('processed ${folder.name}');
    }
    return processedPaths;
  }

  /// Copies a file from the users' device to Google Drive.
  /// Path must be supplied like path/to/file.txt. Last entry after the final forward-slash must not end
  /// with a forward slash, and will be treated as the file name.
  Future<drive.File> pushFile(final File file, final String path, {final String? mimeType}) async {
    String? containingFolderId;
    if (path.contains('/')) {
      final containingFolders = path.substring(0, path.lastIndexOf('/'));
      final foldersId = await createFoldersRecursively(containingFolders);
      containingFolderId = foldersId.last.id;
    }
    final fileName = path.contains('/') ? path.split('/').last : path;

    final existingFileQuery = QueryBuilder.fileQuery(
      fileName,
      mimeType: lookupMimeType(path),
    );

    final existingFileData = await files.list(
      q: existingFileQuery,
      $fields: 'files(kind,id,name,mimeType,md5Checksum)',
    );

    if (existingFileData.files!.isNotEmpty) {
      final remoteMd5 = existingFileData.files?.first.md5Checksum;
      final localMd5 = await getMD5(file.path);
      if (remoteMd5 == localMd5) {
        print('Remote file is the same, not pushing file.');
        return existingFileData.files!.first;
      }
    }
    final driveFile =
        drive.File(name: fileName, mimeType: mimeType ?? lookupMimeType(fileName), parents: containingFolderId == null ? [] : [containingFolderId]);

    final length = await file.length();
    final fileContents = file.openRead();

    final destinationFile = await drive.DriveApi(GoogleAuthClient()).files.create(
          driveFile,
          uploadMedia: drive.Media(
            fileContents,
            length,
          ),
        );
    return destinationFile;
  }

  /// Copies a local filesystem folder to Google Drive. Mimetypes are interpreted from the files
  /// Specify a destinationDirectory to use. Cannot copy to root of drive.
  Stream<FolderTransferProgress> pushFolder(final Directory directory, final String destinationDirectory) async* {
    int fileCount = 0;
    final rootPath = directory.path;

    final totalFileCount = await directory.list(recursive: true).length;

    await for (final file in directory.list(recursive: true).where((event) => event.statSync().type == FileSystemEntityType.file)) {
      fileCount++;
      final remotePath = '$destinationDirectory/${file.path.substring(rootPath.length)}';
      yield FolderTransferProgress(FolderPushStatus.sending, path: file.path, copiedFiles: fileCount, totalCount: totalFileCount);
      // todo keep track of folders we have already created, so we don't recheck these folders needlessly
      await pushFile(File(file.path), remotePath);
    }
    yield FolderTransferProgress(FolderPushStatus.completed);
  }

  /// Retrieves a folder from a Google Drive location to the local device
  /// If the remote folder does not exist, function will throw
  Stream<FolderTransferProgress> receiveFolder(String remoteFolderId, final Directory localDirectory) async* {
    print('Copying ID ${remoteFolderId} to ${localDirectory.path}...');
    final filesInFolder = await files.list(q: GoogleDriveQueryHelper.fileListQuery(remoteFolderId));
    if (filesInFolder.files != null) {
      for (final entity in filesInFolder.files!) {
        // Could either be a file or a folder
        if (entity.mimeType == MimeType.folder) {
          final childDirectory = Directory(p.join(localDirectory.path, entity.name));
          if (!(await childDirectory.exists())) {
            await childDirectory.create(recursive: true);
          }
          if (entity.id == null) {
            print('ID of found google drive folder is null? This is a bug, please open a bug report');
          } else {
            print('Found ${entity.name} folder, (ID: ${entity.id}). Recursively copying.');
            yield* receiveFolder(entity.id!, childDirectory);
          }
        } else {
          print('Processing file copy for ${entity.name} (with mimetype of ${entity.mimeType}, copying to directory ${localDirectory.path}');
          final file = await files.get(entity.id!, downloadOptions: drive.DownloadOptions.fullMedia);
          if (file is drive.Media) {
            final filePath = p.join(localDirectory.path, entity.name);
            final destinationFile = File(filePath);
            await for (final bytes in file.stream) {
              // calling append on a nonexistant file creates that file.
              destinationFile.writeAsBytes(bytes, mode: FileMode.append);
            }
          } else {
            print("WARNING: Received a file that wasn't of type media. Instead, it was of type ${file.runtimeType.toString()}");
          }
        }
      }
    }
    // final folderIdTree = ['root', ...remoteFolderIds.map((e) => e.id)];
  }

  /// Converts a folder path, like, "path/like/this" to a set of folder id's.
  /// If a specified folder doesn't exist, returns null for that Path Bit's ID.
  Future<List<FolderPathBit>> getFolderPathAsIds(final String path) async {
    print('DEBUG: Looking for $path');
    int depth = 0;
    final pathBits = path.split('/')..removeWhere((element) => element == "");
    final folderIds = <FolderPathBit>[];
    bool exists = false;
    for (final bit in pathBits) {
      print('DEBUG: Looking for $bit');
      if (folderIds.isNotEmpty) {
        if (folderIds.last.id == null) {
          // Last time in the loop, we didn't get a good hit
          folderIds.add(FolderPathBit(bit, null, depth));
          continue; // skip this iteration, so the function from this point will just put entries in with no id's
        }
      }
      final folder = await files.list(
        q: GoogleDriveQueryHelper.fileQuery(
          bit,
          mimeType: MimeType.folder,
          parent: folderIds.isEmpty ? null : folderIds.last.id,
        ),
      );
      if (folder.files == null) {
        print('DEBUG: When searching for $bit, no folders were returned. Are you logged in?');
        throw ('Files are null.');
      }
      // if (folder.files!.isEmpty) {
      //   break;
      // }
      if (folder.files!.length > 1) {
        print('DEBUG: More than one result found, picking the first one!');
      }
      if (folder.files!.isNotEmpty) {
        folderIds.add(FolderPathBit(folder.files![0].name!, folder.files![0].id!, depth));
      } else {
        folderIds.add(FolderPathBit(bit, null, depth));
      }
      depth++;
    }
    return folderIds;
  }
}

class GoogleDriveQueryHelper {
  /// Creates a query that searches for a particular file, name, and mimetype.
  static String fileQuery(
    final String name, {

    /// The mime type to search for. You can specify your own, but you're probably better off using the pre-written ones in the MimeType class.
    required final String mimeType,

    /// The ID of the parent folder
    final String? parent,
  }) {
    final query = "mimeType='$mimeType' and name='$name' and trashed = false ${parent != null ? "and '$parent' in parents" : ""}";
    print('Prepared query: $query');
    return query;
  }

  static String fileListQuery(final String folderId) {
    final query = "'$folderId' in parents and trashed = false";
    print('Prepared query: $query');
    return query;
  }
}

class FolderTransferProgress {
  final String? path;
  final int? totalCount;
  final int? copiedFiles;
  final FolderPushStatus status;
  final List<String>? successfulCopies;
  final Map<String, Exception>? errorCopies;

  FolderTransferProgress(
    this.status, {
    this.path,
    this.totalCount,
    this.copiedFiles,
    this.successfulCopies,
    this.errorCopies,
  });

  double progress() {
    if (copiedFiles == null || totalCount == null) {
      return 0;
    }
    return copiedFiles! / totalCount! * 100;
  }

  @override
  String toString() {
    return 'Folder Push Progress: ${status.name}, Path: $path, Total Count: ${totalCount ?? 'null'}, Copied Files: ${copiedFiles ?? 'null'}';
    // TODO: implement toString
    //return super.toString();
  }
}

enum FolderPushStatus {
  initializing,
  sending,
  completed,
  recoverableError,
  unrecoverableError,
}
