// Unfortunately, interacting with the Google API is not strongly typed.
// This means we have to manually jooj the strings to get the results we want

import 'package:flutter/foundation.dart';

class QueryBuilder {
  static String fileQuery(
    /// The name of the file being looked for.
    final String name, {

    /// The mimetype of the file to find. You can use the consts in the MimeType class for easier access.
    final String? mimeType,

    /// The ID of the parent folder to look in.
    final String? parent,

    /// Whether the search should include or exclude trashed items. Excluded by default.
    final bool trashed = false,
  }) {
    String queryBuilder = "name='$name' and trashed = $trashed ";
    if (mimeType != null) {
      queryBuilder += "and mimeType = '$mimeType' ";
    }
    if (parent != null) {
      queryBuilder += "and $parent in parents ";
    }
    // final query = "name='${name}' and trashed = false ${mimeType == null ? '' : 'mimeType=''} ${parent != null ? "and ${parent} in parents" : ""}";
    print('Executing query: $queryBuilder');
    return queryBuilder;
  }
}

class MimeType {
  /// Folders within Google Drive.
  static const folder = "application/vnd.google-apps.folder";
}

class FileDetail {
  final String name;
  final int bytes;
  final DateTime lastModified;
  final String md5;

  FileDetail(this.name, this.bytes, this.lastModified, this.md5);
}

// class CopyOptions {
//   final Function(FileDetail localFile, FileDetail remoteFile) onExisting;
//   CopyOptions(this.onExisting);
// }
//
// enum FileCopyChoice {
//   overwrite,
//   ignore,
//   cancel,
// }
