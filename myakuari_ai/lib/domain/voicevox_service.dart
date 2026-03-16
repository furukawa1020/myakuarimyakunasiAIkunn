// Webビルドを阻害するため、FFI依存のコードをコメントアウトまたはスタブ化
class LocalVoicevoxService {
  static final LocalVoicevoxService _instance = LocalVoicevoxService._internal();
  factory LocalVoicevoxService() => _instance;
  LocalVoicevoxService._internal();

  Future<void> initialize() async {
    // Webでは何もしない
  }

  Future<void> speak(String text) async {
    // Webでは BundledVoiceService に任せるか無視する
    print('Web environment: LocalVoicevoxService is disabled.');
  }

  void dispose() {}
}
