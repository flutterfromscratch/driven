// Unfortunately, interacting with the Google API is not strongly typed.
// This means we have to manually jooj the strings to get the results we want

class QueryBuilder {
  static String fileQuery(
    /// The name of the file being looked for.
    final String name,

    /// The mimetype of the file to find. You can use the consts in the MimeType class for easier access.
    final String mimeType, {

    /// The ID of the parent folder to look in.
    final String? parent,

    /// Ignore files that are deleted, defaults to true.
    final bool excludeDeleted = true,
  }) {
    final query = "mimeType='' and name='${name}' and trashed = false ${parent != null ? "and ${parent} in parents" : ""}";
    print('Executing query: ${query}');
    return query;
  }
}

class MimeType {
  /// Folders within Google Drive.
  static const folder = "application/vnd.google-apps.folder";
}
