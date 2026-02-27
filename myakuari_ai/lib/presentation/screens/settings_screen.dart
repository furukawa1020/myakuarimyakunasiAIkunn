import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('履歴をローカルに保存'),
            value: false,
            onChanged: (val) {},
            activeColor: const Color(0xFFFF007F),
          ),
          SwitchListTile(
            title: const Text('音声再生（ずんだもん）'),
            value: true,
            onChanged: (val) {},
            activeColor: const Color(0xFFFF007F),
          ),
        ],
      ),
    );
  }
}
