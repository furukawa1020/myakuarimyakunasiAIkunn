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

    # 2. LINE/連絡プロトコル解析 (日本特有の作法)
    content = "#{input['what']} #{input['why']} #{input['how']}"

    # 即レス・頻度
    if content.include?("即レス") || content.include?("早い") || content.include?("頻繁")
      score += 15
      details << "【連絡】レスポンスが早いのは、優先順位が高い証拠なのだ！"
    end

    # スタンプの同調 (ミラーリング)
    if content.include?("スタンプ") && (content.include?("同じ") || content.include?("似てる"))
      score += 10
      details << "【共感】スタンプのミラーリングは心理的距離が近い証拠なのだ。"
    end

    # 日常報告 (俺通信・私通信)
    if content.include?("写真") || content.include?("食べた") || content.include?("今ここ")
      score += 12
      details << "【共有】何気ない日常の共有は、あなたを特別な存在と思っている証拠なのだ。"
    end

    # 3. 敬語からタメ口への移行 (日本特有の距離感)
    if content.include?("タメ口") || content.include?("崩し") || content.include?("呼び捨て")
      score += 15
      details << "【距離感】言葉遣いが崩れるのは、心の壁がなくなってきた証拠なのだ。"
    elsif content.include?("敬語") && content.include?("ずっと")
      score -= 5
      details << "【距離感】丁寧すぎる敬語は、まだ壁を感じている可能性があるのだ。"
    end

    # 4. 遠回しな誘いと具体性
    if content.include?("二人で") || content.include?("2人で")
      score += 20
      details << "【確信】「二人で」という言葉が出るのは、もう脈アリ確定に近いのだ！"
    end

    if content.include?("どこか") || content.include?("今度")
      if input['concreteness'] == "YES"
        score += 10
        details << "【具体性】具体的な日程調整があれば、社交辞令ではないのだ。"
      else
        score -= 5
        details << "【注意】「今度」だけで予定が決まらないのは、社交辞令の恐れがあるのだ。"
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
