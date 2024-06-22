require 'net/http'
require 'csv'

PICTURE = {
  family: "Resource:icon_family_b.png",
  friend:  "Resource:icon_friend_b.png",
  blacklist:  "Resource:icon_blacklist_b.png"
}

DTMF_CODES = {
  "10" => "1",
  "20" => "2",
  "21" => "A",
  "22" => "B",
  "23" => "C",
  "30" => "3",
  "31" => "D",
  "32" => "E",
  "33" => "F",
  "40" => "4",
  "41" => "G",
  "42" => "H",
  "43" => "I",
  "50" => "5",
  "51" => "J",
  "52" => "K",
  "53" => "L",
  "60" => "6",
  "61" => "M",
  "62" => "N",
  "63" => "O",
  "70" => "7",
  "71" => "P",
  "72" => "Q",
  "73" => "R",
  "74" => "S",
  "80" => "8",
  "81" => "T",
  "82" => "U",
  "83" => "V",
  "90" => "9",
  "91" => "W",
  "92" => "X",
  "93" => "Y",
  "94" => "Z",
  "00" => "0",
  "99" => "NOT"
}

def dtmfdecode(number)
  digits=number.scan(/../)
  not_found = false
  digits.map.with_index  do |digit, index|
    if not_found || index >= 6
      digit
    else
      tmp = DTMF_CODES[digit]
      if tmp == 'NOT'
        not_found = true
      end
      tmp
    end
  end.join('')
end

numbers = {}

servers = %w[44.143.70.4 44.143.78.15 44.143.40.20]
servers.each do |server|
  uri = URI("http://#{server}/voip/db.php")
  Net::HTTP.start(uri.host, uri.port) do |http|
    request = Net::HTTP::Get.new uri
    response = http.request request
    body = response.body
    # this api has broken newlines, fix them
    body.gsub!(/\r\n/, "\n")
    body.gsub!(/\r/, "\n")
    CSV.parse(body, :headers => false, :liberal_parsing => true, :row_sep => "\n") do |row|
      if row.length > 1 && !row[0].nil?
        numbers[dtmfdecode(row[0])] = row[0] unless row[0].include? 'END'
      end
    end
  end
end

call_prefixes = numbers.keys.map{|x| x[0..2]}.select{|x| x.match?(/\d/)}.uniq.sort

call_groups = {}
numbers.each do |k,v|
  prefix = k[0..2];
  unless prefix.match?(/.?[a-z][\d]/i)
    prefix = 'Other'
  end
  call_group = call_groups[prefix] ||= []
  call_group << "<Unit Name=\"#{k}\" default_photo=\"#{PICTURE[:friend]}\" Phone3=\"\" Phone2=\"\" Phone1=\"00#{v}\" />"
end

def generate_prefixes(prefix, call_group)
  return '' if call_group.nil?
  return '' if call_group.size == 0
  "<Menu Name=\"#{prefix}\">" + call_group.sort.join("\n    ") + "\n</Menu>\n"
end

File.open("output.xml", "wb") do |f|
  f.puts '<?xml version="1.0" encoding="UTF-8" ?>'
  f.puts '<YealinkIPPhoneBook>'
  f.puts '  <Title>HamSIP</Title>'
  call_prefixes.each { |prefix| f.write(generate_prefixes(prefix, call_groups[prefix])) }
  f.write generate_prefixes("Other", call_groups['Other'])
  f.puts '</YealinkIPPhoneBook>'
end