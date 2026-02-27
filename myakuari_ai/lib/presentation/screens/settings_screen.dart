import 'package:flutter/material.dart';
import '../../domain/remote_voicevox_service.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();
  final _tts = RemoteVoicevoxService();
  String _pingStatus = '未確認';
  bool _pinging = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _tts.initialize();
    setState(() => _urlController.text = _tts.serverUrl);
  }

  Future<void> _save() async {
    await _tts.setServerUrl(_urlController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存しました'), duration: Duration(seconds: 1)),
      );
    }
  }

  Future<void> _ping() async {
    await _tts.setServerUrl(_urlController.text.trim());
    setState(() { _pinging = true; _pingStatus = '接続中…'; });
    final ok = await _tts.ping();
    setState(() {
      _pinging = false;
      _pingStatus = ok ? '✅ 接続成功！' : '❌ 接続できませんでした';
    });
  }

  Future<void> _testVoice() async {
    await _tts.setServerUrl(_urlController.text.trim());
    await _tts.speak('こんにちはなのだ！ずんだもんなのだ！');
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── ずんだもんボイス設定 ──
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              '🎙 ずんだもんボイス設定',
              style: TextStyle(color: Color(0xFF00FFFF), fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          GlassCard(
            padding: const EdgeInsets.all(16),
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Voicevox Engine サーバーURL',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  'PCでVoicevox Engineを起動し、同じWi-Fiに接続した状態でAndroid実機から音声が使えます。',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _urlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'http://192.168.x.x:50021',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF00FFFF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: const Color(0xFF00FFFF).withOpacity(0.4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF00FFFF)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _pinging ? null : _ping,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F3460),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _pinging
                            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('接続テスト'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _testVoice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16213E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('声を試す'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF007F),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('保存'),
                      ),
                    ),
                  ],
                ),
                if (_pingStatus.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(_pingStatus, style: TextStyle(
                    color: _pingStatus.startsWith('✅') ? Colors.greenAccent : Colors.orangeAccent,
                    fontSize: 13,
                  )),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          // ── その他設定 ──
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              '⚙️ その他',
              style: TextStyle(color: Color(0xFF00FFFF), fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          GlassCard(
            padding: EdgeInsets.zero,
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('履歴をローカルに保存', style: TextStyle(color: Colors.white)),
                  value: false,
                  onChanged: (val) {},
                  activeColor: const Color(0xFFFF007F),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
