import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('免責事項・About'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Padding(
        padding: EdgeInsets.all(24.0),
        child: Text(
          '免責事項:\n\n本アプリの推論結果はエンタメ目的の独自ルールに基づいており、確実性を保証するものではありません。ストーカー行為、尾行、つきまとい、その他違法行為や相手に迷惑をかける行為は絶対に行わないでください。本アプリを利用した際に生じたいかなるトラブルについても、開発者は一切の責任を負いません。',
          style: TextStyle(fontSize: 16, height: 1.5, color: Colors.white),
        ),
      ),
    );
  }
}
