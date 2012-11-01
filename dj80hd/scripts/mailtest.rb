require 'base64'
require 'rubygems'
require 'tmail'
require 'net/smtp'

if (ARGV.size < 1)
        puts "Sends a test message through an smtp server.\n"
        puts "USAGE: perl #{$0} <smtp host> <To: email address> <message>\n"
        puts "e.g. ruby #{$0} 10.1.1.41 werwath@gmail.com This is a test\n"
        exit 0
end
host = ARGV[0]
to = ARGV[1]
subject = 'test'
msg = ARGV[2..(ARGV.size - 1)].join(" ");
puts "host=#{host} to=#{to} msg=#{msg}"
from = "accurev@novarra.com";
data  = "From: Ruby Mailtest<#{from}>\n"
data += "To: You<#{to}>\n"
data += "Subject: #{subject}\n"
data += "\n"
data += msg 


#mail = TMail::Mail.new
#mail.to = to
#mail.from = from
#mail.subject = subject
#mail.date = Time.now
#mail.mime_version = '1.0'
#mail.set_content_type 'text', 'plain', {'charset'=>'utf-8'}
#mail.body = msg

mail = TMail::Mail.new
mail.date = Time.now
mail.to = to
mail.from = from
mail.subject = subject
mail.mime_version = '1.0'
mail.body = "dummy"


attachment = TMail::Mail.new
attachment.body = "It really works!!!"
attachment.transfer_encoding = '7bit'
attachment.set_content_type('text', 'plain')
mail.parts.push(attachment)

filename = "report.csv"
encoded_file = "1,1,1\n"
attachment = TMail::Mail.new
attachment.body = encoded_file
attachment.transfer_encoding = '7bit'
attachment.set_content_type('application', 'csv', 'name' => filename)
attachment.header["Content-Disposition"] = "attachment; filename=" + filename
mail.parts.push(attachment)

if (false)
  filename = "snap.png"
  attachment = TMail::Mail.new
  attachment.body = Base64.encode64(open('c:\jim\snap.png','rb') {|f| f.read})
  #attachment.set_content_type('image', 'jpeg', 'name' => filename)
  attachment.set_content_type('image', 'png', 'name' => filename)
  attachment.transfer_encoding = 'Base64'
  attachment.header["Content-Disposition"] = "attachment; filename=" + filename
  mail.parts.push(attachment)
end
if (true)
  filename = "666.jpg"
  attachment = TMail::Mail.new
  attachment.body = Base64.encode64(open('c:\jim\666.jpg','rb') {|f| f.read})
  #attachment.set_content_type('image', 'jpeg', 'name' => filename)
  attachment.set_content_type('application', 'octet-stream', 'name' => filename)
  attachment.transfer_encoding = 'Base64'
  attachment.header["Content-Disposition"] = "attachment; filename=" + filename
  mail.parts.push(attachment)
end
mail.set_content_type('multipart','mixed')
puts mail.to_s
Net::SMTP.start(host, 25) {|smtp| smtp.send_message(mail.to_s,from,to)}
