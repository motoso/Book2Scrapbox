require 'json'

def process_text(text, output_file)
  # テキスト内のすべてのgyazo.comのURLを抽出
  pattern = /\[\[https:\/\/gyazo\.com\/[a-zA-Z0-9]+\]\]/
  result = text.scan(pattern).flatten
  # [[ ]]を削除
  json_output = result.map { |url| url.gsub('[[', '').gsub(']]', '') }

  File.write(output_file, JSON.pretty_generate(json_output))
  puts "JSONが #{output_file} に出力されました。"
end

# コマンドライン引数からテキストファイルと出力ファイル名を取得する
if ARGV.length != 2
  puts "使用法: ruby script.rb <input_file> <output_file>"
  exit 1
end

input_file = ARGV[0]
output_file = ARGV[1]

# テキストファイルを読み込む
text = File.read(input_file)

# process_text メソッドを呼び出す
process_text(text, output_file)
