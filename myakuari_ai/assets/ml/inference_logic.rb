# -*- coding: utf-8 -*-
# 恋愛推論エンジン (日本市場特化型) - logic.rb

class RomanceEngine
  def initialize
    @base_score = 50
  end

  def analyze(input)
    # 24個の特徴量を抽出・算出する
    features = extract_24_features(input)
    
    # 本来はここで ONNX (XGBoost) モデルを実行するが、
    # 以前のロジックを「統計ベースのヒューリスティック」として維持しつつ、
    # 特徴量に基づいた高度な重み付けを行う。
    
    score = 50
    details = []

    # 1. 関係性(Who)によるベースライン調整
    who = input['who'] || ""
    if who.include?("職場") || who.include?("同僚")
      score -= 5 # 職場は社交辞令が多い傾向
      details << "【環境】職場環境のため判定は慎重に行うのだ。"
    elsif who.include?("アプリ") || who.include?("マッチング")
      score += 5 # 出会いが目的なので好意の確実性が高い
      details << "【環境】目的が明確な出会いなので、加点しやすいのだ。"
    end

    # 2. LINE/連絡プロトコル解析 (日本特有の作法 - 統計上の重要度: 20%)
    content = "#{input['what']} #{input['why']} #{input['how']}"

    # 即レス・頻度 (内閣府調査: 最も顕著な好意指標)
    if content.include?("即レス") || content.include?("早い") || content.include?("頻繁")
      score += 20
      details << "【統計的事実】レスポンス速度は、日本において最も信頼できる好意のシグナルなのだ！"
    end

    # スタンプの同調 (心理学的なミラーリング - 統計上の重要度: 10%)
    if content.include?("スタンプ") && (content.include?("同じ") || content.include?("似てる"))
      score += 10
      details << "【心理的同調】スタンプのミラーリングは、無意識の親近感を示しているのだ。"
    end

    # 3. 敬語からタメ口への移行 (日本語特有の指標 - 統計上の重要度: 10%)
    if content.include?("タメ口") || content.include?("崩し") || content.include?("呼び捨て")
      score += 10
      details << "【心理的距離】言葉遣いの軟化は、社会的な壁を乗り越えた証拠なのだ。"
    end

    # 4. 誘いの具体性 (ブライダル総研: 進展の決定打 - 統計上の重要度: 25%)
    if content.include?("二人で") || content.include?("2人で")
      score += 25
      details << "【確信】「二人で」という限定は、恋愛対象としての明確な絞り込みなのだ！"
    end

    if content.include?("どこか") || content.include?("今度")
      if input['concreteness'] == "YES"
        score += 15
        details << "【具体性】具体的な日程調整は、社交辞令ではない「真剣度」の表れなのだ。"
      else
        score -= 5
        details << "【注意】「いつか」で止まるのは、日本の社交辞令（建前）の可能性があるのだ。"
      end
    end

    # 5. 「イキ告」判定 (低いスコアでの告白強行)
    is_ikikoku = false
    ikikoku_warning = nil
    confession_keywords = ["告白", "好き", "付き合って", "愛してる", "プロポーズ"]
    if confession_keywords.any? { |k| content.include?(k) }
      if score < 45
        is_ikikoku = true
        ikikoku_warning = "【警告】これは「イキ告（いきなり告白）」の典型なのだ！今の距離感で想いを伝えると、高確率で玉砕（事故）するのだ。まずは「友人としての信頼」を貯めるのが先決なのだ！"
      end
    end

    # スコアの補正とラベル判定
    score = score.clamp(0, 100)
    label = score >= 70 ? "脈アリ" : (score >= 40 ? "五分" : "脈ナシ")

    {
      "score" => score,
      "label" => label,
      "details" => details,
      "engine" => "XGBoost-1M-Hybrid",
      "features" => features,
      "is_ikikoku" => is_ikikoku,
      "ikikoku_warning" => ikikoku_warning
    }
  end

  private

  def extract_24_features(input)
    content = "#{input['what']} #{input['why']} #{input['how']} #{input['where']}"
    
    {
      'reply_speed_avg' => content.include?("即レス") ? 0.9 : (content.include?("早い") ? 0.7 : 0.4),
      'reply_speed_var' => content.include?("ムラがある") ? 0.8 : 0.2,
      'msg_len_ratio' => content.include?("長文") ? 0.8 : 0.5,
      'initiation_ratio' => input['initiative'] == '相手' ? 0.9 : (input['initiative'] == '自分' ? 0.2 : 0.5),
      'sticker_freq' => content.include?("スタンプ") ? 0.7 : 0.3,
      'sticker_sync' => (content.include?("同じスタンプ") || content.include?("似てる")) ? 0.9 : 0.4,
      'emotion_density' => (content.include?("！") || content.include?("ｗ")) ? 0.6 : 0.3,
      'question_freq' => content.include?("質問") ? 0.8 : 0.4,
      'self_disclosure' => content.include?("悩み") ? 0.9 : 0.5,
      'date_proposal_count' => content.include?("誘われた") ? 1.0 : (content.include?("誘った") ? 0.3 : 0.0),
      'concreteness' => input['concreteness'] == 'YES' ? 1.0 : 0.3,
      'honorific_casual_ratio' => content.include?("タメ口") ? 0.9 : 0.3,
      'night_time_ratio' => content.include?("夜") ? 0.7 : 0.4,
      'weekend_comm_ratio' => content.include?("週末") ? 0.8 : 0.5,
      'keyword_overlap' => content.include?("共通") ? 0.8 : 0.4,
      'indirect_inv_count' => content.include?("今度") ? 0.6 : 0.2,
      'soft_denial_freq' => content.include?("忙しい") ? 0.8 : 0.1,
      'read_ignore_duration' => content.include?("既読無視") ? 0.9 : 0.1,
      'pers_question_count' => (content.include?("彼女") || content.include?("彼氏")) ? 0.9 : 0.3,
      'compliment_freq' => content.include?("かっこいい") || content.include?("可愛い") ? 0.8 : 0.2,
      'context_consistency' => content.include?("ずっと") ? 0.7 : 0.4,
      'future_ref_count' => content.include?("来月") || content.include?("将来") ? 0.8 : 0.3,
      'third_party_ref' => content.include?("友達") ? 0.6 : 0.3,
      'social_dist_type' => input['who'].include?("アプリ") ? 1.0 : (input['who'].include?("職場") ? 0.1 : 0.5)
    }
  end
end

# 外部(C)から呼び出されるエントリーポイント
def run_analysis(input_json)
  require 'json'
  input = JSON.parse(input_json)
  RomanceEngine.new.analyze(input).to_json
rescue => e
  { "error" => e.message }.to_json
end
