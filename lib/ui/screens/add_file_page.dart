import 'dart:developer';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:note_sharing_project/models/files_model.dart';
import 'package:note_sharing_project/services/firebase_service.dart';
import 'package:note_sharing_project/services/notification_service.dart';
import 'package:note_sharing_project/ui/widgets/upload_file_container.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class AddFilePage extends StatefulWidget {
  final String name;
  final String semester;
  final String program;

  const AddFilePage({
    Key? key,
    required this.name,
    required this.semester,
    required this.program,
  }) : super(key: key);

  @override
  State<AddFilePage> createState() => _AddFilePageState();
}

class _AddFilePageState extends State<AddFilePage> {
  File? _file;
  String _name = "";
  String _size = "";
  late TextEditingController nameController;
  bool isLoading = false;
  late String path;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    path = "${widget.program}-${widget.semester}-${widget.name}";
  }

  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        elevation: 0.0,
        title: const Text('Add File Page'),
        actions: [
          IconButton(
              onPressed: () {
                OneSignal.shared.sendTag(path, path);
              },
              icon: const Icon(Icons.upload))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      body: Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
                color: Colors.white),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  UploadFileContainer(
                      changeFile: ((file, name, size) {
                        _chageFile(file, name, size);
                      }),
                      mFile: _file,
                      removePicked: () {
                        setState(() => _file = null);
                      },
                      name: _name,
                      size: _size),
                  const SizedBox(height: 10),
                  _editNameTextField(),
                  const SizedBox(height: 10),
                  _uploadButton(
                      context: context,
                      onTap: () async => await handleUpload()),
                ],
              ),
            ),
          ),
          (isLoading)
              ? const Center(child: CircularProgressIndicator())
              : const Center()
        ],
      ),
    );
  }

  Padding _editNameTextField() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: nameController,
        decoration: InputDecoration(
          label: const Text("Edit Name"),
          border: const OutlineInputBorder(),
          suffix: (_name.isNotEmpty) ? Text(".${_name.split(".")[1]}") : null,
        ),
      ),
    );
  }

  void _chageFile(File file, String name, String size) {
    setState(() {
      _file = file;
      _name = name;
      _size = size;
      nameController.text = _name.split(".")[0];
    });
  }

  Future<void> handleUpload() async {
    if (_file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please Add File'),
        ),
      );
    } else if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please Enter Name'),
        ),
      );
    } else {
      try {
        setState(() {
          isLoading = true;
        });
        final ref = FirebaseStorage.instance.ref("docs/$_name");
        final task = ref.putFile(_file!);

        final url = await task.snapshot.ref.getDownloadURL();
        final newModel = FileModel(
            name: nameController.text,
            date: "2022-01-01",
            time: "02 00 Pm",
            size: _size,
            filePath: "docs/${nameController.text}",
            fileType: _name.split(".")[1],
            url: url);

        await FirebaseService().insertData(path, newModel);

        await NotificationService().sendWithTagNotification(
            heading: "New Notes Added for $path",
            content: "New Notes Added Click to check it out.",
            tag: path);
        setState(() {
          isLoading = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully Added'),
          ),
        );
        Navigator.pop(context);
      } on FirebaseException catch (e) {
        log("firebase exception:$e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
          ),
        );
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  SizedBox _uploadButton(
      {required BuildContext context, required Function() onTap}) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * .8,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(
            Theme.of(context).colorScheme.primary,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.upload),
            Text(
              'Add',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
