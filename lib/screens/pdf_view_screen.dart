import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class PdfViewPage extends StatelessWidget {
  final File file;

  const PdfViewPage({super.key, required this.file});

  void _sharePdf() {
    Share.shareXFiles(
      [XFile(file.path)],
      text: 'Invoice PDF',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice PDF',style: TextStyle(color: Colors.white),),
        backgroundColor: Color(0xFF213D5C),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share,color: Colors.white),
            onPressed: _sharePdf,
          ),
        ],
      ),
      body: SfPdfViewer.file(file),
    );
  }
}
