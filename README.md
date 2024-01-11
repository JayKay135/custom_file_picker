# Custom File Picker
[![pub package](https://img.shields.io/pub/v/custom_file_picker.svg)](https://pub.dev/packages/custom_file_picker)
[![pub points](https://img.shields.io/pub/points/custom_file_picker.svg)](https://pub.dev/packages/custom_file_picker)
[![package publisher](https://img.shields.io/pub/publisher/custom_file_picker.svg)](https://pub.dev/packages/custom_file_picker/publisher)

## Features
This package adds a file opener hierarchy system that is device-independent.
So it does not reflect the file system of the running device but can show other custom-specified file hierarchies.

## Usage
### Create a custom FileData hierarchy

```dart
final FileData fileHistory = FileData.createFolder(
    "data",
    DateTime.now(),
    [
      FileData.createFolder("images", DateTime.now(), [
        FileData.createFileFromFileName("next_img.png", DateTime.now()),
        FileData.createFileFromFileName("something.txt", DateTime.now()),
        FileData.createFolder("files", DateTime.now(), [
          FileData.createFileFromFileName("idk.xml", DateTime.now()),
          FileData.createFileFromFileName("something.png", DateTime.now()),
          FileData.createFileFromFileName("test.txt", DateTime.now()),
        ]),
      ]),
      FileData.createFileFromFileName("test.txt", DateTime.now()),
      FileData.createFileFromFileName("idk.urdf", DateTime.now()),
    ],
  );
```

### File Selection
```dart
FilePicker.open(fileHistory, ['txt', 'pdf'], (String filePath) {
  // Handle the selected file path
});
```

### File Saving
```dart
FileData suggestedFile = FileData.createFile("newFile", "txt", DateTime.now());

FilePicker.saveAs(fileHistory, suggestedFile, (String path) {
  // Handle the selected file path
});
```

## Async Variants
There are also async variants of the `open` and `saveAs` functions, in case the whole file history should not be provided right from the start. 
Whenever the user changes the current file hierarchy level (opens a folder or goes back to the parent) the `onSelectedFile` function is called where the new file structure for the required hierarchy level can be provided.


### Async File Selection
```dart
FilePicker.openAsync(fileHistory, ['txt', 'pdf'], (String path) async {
  // Return the FileData for the requested hierarchy path
  return FileData ...
}, (String filePath) {
  // Handle the selected file path
});
```

### Async File Saving
```dart
FileData suggestedFile = FileData.createFile("newFile", "txt", DateTime.now());

FilePicker.saveAsAsync(fileHistory, suggestedFile, (String path) async {
  // Return the FileData for the requested hierarchy path
  return FileData ...
}, (String path) {
  // Handle the selected file path
});
```