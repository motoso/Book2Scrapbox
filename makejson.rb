#
# 自炊PDFから分解したjpgをS3とGyazoにアップロードしてScrapboxのJSONを作成
#
require 'json'
require 'gyazo'


MAX_RETRIES = 3
retry_count = 0

jsondata = {}
pages = []
jsondata['pages'] = pages

jpegfiles = ARGV.grep /\.(jpg|jpeg)/i

token = ENV['GYAZO_ACCESS_TOKEN']
gyazo = Gyazo::Client.new access_token: token

(0..jpegfiles.length).each { |i|
  file = jpegfiles[i]

  data = nil
  begin
    data = File.read(file)
  rescue
  end

  if data
    STDERR.puts file
  
    # S3にアップロード
    # STDERR.puts "ruby #{home}/bin/upload #{file}"
    # s3url = `ruby #{home}/bin/upload #{file}`.chomp
    # STDERR.puts s3url

    # Gyazoにアップロード
    begin
      STDERR.puts "gyazo-cli #{file}"
      res = gyazo.upload imagefile: file
      gyazourl = res[:permalink_url]
      STDERR.puts gyazourl
    rescue Net::HTTPError, Timeout::Error => e
      if retry_count < MAX_RETRIES
        retry_count += 1
        puts "Network error occurred, retrying in 5 seconds (attempt #{retry_count} of #{MAX_RETRIES})..."
        sleep 5
        retry
      else
        puts "Max retry attempts exceeded, error: #{e.message}"
      end
    end
    
    sleep 2

    page = {}
    page['title'] = sprintf("%03d",i)
    lines = []
    page['lines'] = lines
    lines << page['title']
    if i == 0
      line1 = "[#{sprintf('%03d',i)}]  [#{sprintf('%03d',i+1)}]"
    elsif i == jpegfiles.length - 1
      line1 = "[#{sprintf('%03d',i-1)}]  [#{sprintf('%03d',i)}]"
    else
      line1 = "[#{sprintf('%03d',i-1)}]  [#{sprintf('%03d',i+1)}]"
    end

    lines << line1
    # lines << "[[#{s3url} #{gyazourl}]]"
    lines << "[[#{gyazourl}]]"
    lines << line1
    lines << ""

    pages << page

  end
}

puts jsondata.to_json
