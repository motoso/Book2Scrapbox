#
# ScrapboxページにGyazoが含まれているときOCRテキストを追加
#
# Gyazo APIのためのアクセストークンは環境変数GYAZO_ACCESS_TOKENに設定しておく必要がある
#
#  アクセストークンは以下から取得
#    https://gyazo.com/api?lang=ja
#
# 手順
#  1. ScrapboxプロジェクトのJSONデータをエクスポートする
#  2. GyazoのOCRテキストをデータに追加する
#     % ruby addocr.rb origdata.json > newdata.json
#  3. 作成されたJSONデータをインポートする


require 'json'
require 'gyazo'

jsonfile = ARGV[0]
unless jsonfile && File.exist?(jsonfile)
  STDERR.puts "JSON file not found"
  STDERR.puts "Usage: ruby addocr.rb orig.json > new.json"
  exit
end

# token = `op get item YOUR_1password_UUID | jq -r '.details.sections[0].fields[] | select(.n == "credential").v'`.chomp
token = ENV['GYAZO_ACCESS_TOKEN']
gyazo = Gyazo::Client.new access_token: token

origdata = JSON.parse(File.read(jsonfile))

newdata = {}
newdata['pages'] = []

origdata['pages'].each { |origpage|
  STDERR.puts origpage['title']
  newpage = {}
  newpage['title'] = origpage['title']
  newpage['lines'] = []
  gyazoids = []
  ocr_done = false
  origpage['lines'].each { |origline|
    newpage['lines'] << origline
    if origline =~ /gyazo\.com\/([0-9a-f]{32})/i
      gyazoids << $1
    end
    if origline =~ /OCR text/
      ocr_done = true
    end
  }
  if gyazoids.length > 0 && !ocr_done
    newpage['lines'] << ""
    newpage['lines'] << "(OCR text)"
    gyazoids.each { |gyazoid|
      res = gyazo.image image_id: gyazoid
      if res && res[:ocr]
        res[:ocr][:description].split(/\n/).each { |ocrline|
          newpage['lines'] << "> #{ocrline}"
        }
      end
    }
    newdata['pages'] << newpage
  end
}

puts newdata.to_json
