import 'dart:async';
import 'dart:io';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:pdf_viewer/pdf-viewer_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> _pdfFiles = [];
  List<String> _filteredFiles = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    baseDirectory();
  }
  // get Permission and root directory to get all pdf files from every folder in the storage

  Future<void> baseDirectory() async {
    PermissionStatus permissionStatus =
        await Permission.manageExternalStorage.request();
    if (permissionStatus.isGranted) {
      var rootDirectory = await ExternalPath.getExternalStorageDirectories();
      await getFiles(rootDirectory.first);
    }
  }

// get all pdf files from every folder/directory
  Future<void> getFiles(String directorypath) async {
    try {
      var rootDirectory = Directory(directorypath);
      var directories = rootDirectory.list(recursive: false);
      await for (var element in directories) {
        if (element is File && element.path.endsWith('.pdf')) {
          setState(() {
            _pdfFiles.add(element.path);
            _filteredFiles = _pdfFiles; // assign filteredFiles to pdfFiles
          });
        } else {
          await getFiles(element.path);
        }
      }
    } catch (e) {
      print(e);
    }
  }

// for searching
  void _filterFiles(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredFiles = _pdfFiles; // assign filteredFiles to pdfFiles
      });
    } else {
      setState(() {
        _filteredFiles = _pdfFiles
            .where((file) => file
                .split('/')
                .last
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: !_isSearching
            ? Text("PDF Reader",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
            : TextField(
                decoration: InputDecoration(
                    hintText: "Search PDFS....", border: InputBorder.none),
                onChanged: (value) {
                  _filterFiles(value);
                }),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
              iconSize: 30,
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  _filteredFiles =
                      _pdfFiles; // assign filteredFiles to pdfFiles
                });
              },
              icon: Icon(_isSearching ? Icons.cancel : Icons.search))
        ],
      ),
      body: _filteredFiles.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _filteredFiles.length,
              itemBuilder: (context, index) {
                String filepath = _filteredFiles[index];
                String fileName = path.basename(filepath);
                return Card(
                    color: Colors.white,
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(fileName,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      leading: Icon(
                        Icons.picture_as_pdf,
                        color: Colors.redAccent,
                        size: 30,
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                      ),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PdfViewerScreen(
                                      pdfName: fileName,
                                      pdfPath: filepath,
                                    )));
                      },
                    ));
              }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          //to refresh list of pdf...
          baseDirectory();
        },
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        child: Icon(Icons.refresh),
      ),
    );
  }
}
