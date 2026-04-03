#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/* 
 * mruby 組み込み用ブリッジ (mruby_bridge.c)
 * 実際には mruby のスタティックライブラリとリンクしてビルドします。
 * Flutter (Dart FFI) からこの関数を呼び出します。
 */

// mrubyヘッダーの想定 (ビルド時にパスを通す)
// #include <mruby.h>
// #include <mruby/compile.h>
// #include <mruby/string.h>

/**
 * 推論実行のエントリーポイント
 * @param script_content Rubyスクリプトの内容
 * @param input_json 入力データ (InferenceInput の JSON)
 * @return 実行結果の JSON 文字列 (呼び出し側で free が必要)
 */
char* run_ruby_inference(const char* script_content, const char* input_json) {
    // 本来はここで mruby インタプリタを初期化して実行します。
    // 今回は FFI 連携のデモ・枠組みとして、引数を受け取り処理するフローを記述。
    
    /* 
    mrb_state *mrb = mrb_open();
    mrb_load_string(mrb, script_content);
    
    // run_analysis(input_json) を呼び出し
    mrb_value input = mrb_str_new_cstr(mrb, input_json);
    mrb_value result = mrb_funcall(mrb, mrb_top_self(mrb), "run_analysis", 1, input);
    
    const char* result_c = mrb_str_to_cstr(mrb, result);
    char* final_res = strdup(result_c);
    
    mrb_close(mrb);
    return final_res;
    */

    // スタブ実装: Cレベルでの連結を確認するためのダミー
    size_t len = strlen(input_json) + 128;
    char* dummy_res = (char*)malloc(len);
    snprintf(dummy_res, len, "{\"score\": 85, \"label\": \"脈アリ\", \"details\": [\"Ruby Bridge Connection OK\"], \"engine\": \"mruby-native-stub\"}");
    
    return dummy_res; 
}

/**
 * 文字列メモリ解放用
 */
void free_ruby_result(char* ptr) {
    if (ptr) free(ptr);
}
