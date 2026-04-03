# -*- coding: utf-8 -*-
# 恋愛推論エンジン (日本市場特化型) - logic.rb

class RomanceEngine
  def initialize
    @base_score = 50
  end

  def analyze(input)
    score = @base_score
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

    # スコアの補正とラベル判定
    score = score.clamp(0, 100)
    label = score >= 70 ? "脈アリ" : (score >= 40 ? "五分" : "脈ナシ")

    {
      "score" => score,
      "label" => label,
      "details" => details,
      "engine" => "Ruby(mruby) Native"
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
