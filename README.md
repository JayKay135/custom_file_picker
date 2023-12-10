The file opener hierarchy system allows custom file hierarchies that must not match the running device file system.

## Features
Opens the file picker dialog in a separate window.

## Usage
### Create a custom FileData hierarchy

```dart
final FileData file = FileData.createFolder(
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

### Open the file picker dialog
```dart
FilePicker.openSecondaryWindow(file, (FileData fileData) {
    print("selected: ${fileData.getPath()}");
});
```