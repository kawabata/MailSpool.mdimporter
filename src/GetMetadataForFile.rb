##
## Spotlight plugin for MailSpool
## Copyright 2005 by Yoshida Masato <yoshidam@yoshidam.net>
##

require 'tmail'
require 'iconv'
require 'nkf'
require 'ymhtml'
require 'base64'

SPECIAL_CHARS = {
  0x86cb => [0x21c6].pack('U'),
  0x86d4 => [0x21e6].pack('U')
}

def getHtmlText(html, charset)
  body = ""
  parser = YmHTML::Parser.new
  parser.eliminateWhiteSpace = true
  ignore = false
  block = Regexp.new(YmHTML::Parser::BLOCK)
  parser.parse(YmHTML::InputStream.new(html, charset)) do |t, n, d|
    case t
    when :CDATA
      body << d unless ignore
    when :START_ELEM
      body << " " + d['alt'] + " " if d['alt']
      ignore = true if n == 'style' || n == 'script'
    when :END_ELEM
      body << "\n" if n =~ block
      ignore = false if n == 'style' || n == 'script'
    end
  end
  body
end

def japanese2utf8(body)
  cbody = ""
  begin
    cbody << Iconv.iconv('utf-8', 'cp932', NKF.nkf('-sx', body)).join('')
  rescue Iconv::IllegalSequence
    failedcode = ($!.failed[0][0] << 8) | $!.failed[0][1]
    $stderr.printf("error: %04x\n", failedcode)
    cbody <<  $!.success.join('') +
      (SPECIAL_CHARS[failedcode] || "[%04x]" % failedcode)
    body = $!.failed.join('')[2..-1] ## skip 2 bytes
    retry
  rescue
    stderr.puts $!.inspect
  end
  cbody
end

def getText(mail)
  if mail.multipart?
    body = ""
    mail.parts.each do |m|
      b = getText(m)
      body << " " + b if b
    end
  else
    mt = (mail.main_type || "text").downcase
    st = (mail.sub_type || "plain").downcase
    charset = mail.charset
    charset.downcase! if charset
#    p [mt, st, charset]
    body = nil
    if mt == "text"
      begin
        body = mail.body
        cte = mail.transfer_encoding
        case cte
        when 'base64'
          body = Base64.decode64(body.tr(" \r\n", ""))
        when 'quoted-printable'
          body.gsub!(/=([0-9a-fA-F][0-9a-fA-F])/) {|m| $1.hex.chr }
          body.gsub!(/=\s*\n/, '') ## soft break
        end
        case charset
        when 'iso-2022-jp','shift_jis','shift-jis','x-sjis','euc-jp'
          body = japanese2utf8(body)
          charset = 'utf-8'
        when 'iso-8859-1'
          body = Iconv.iconv("utf-8", "iso-8859-1", body).join('')
          charset = 'utf-8'
        when 'iso-8859-13'
          body = Iconv.iconv("utf-8", "iso-8859-13", body).join('')
          charset = 'utf-8'
        when 'iso-8859-15'
          body = Iconv.iconv("utf-8", "iso-8859-15", body).join('')
          charset = 'utf-8'
        when 'windows-1251'
          body = Iconv.iconv("utf-8", "windows-1251", body).join('')
          charset = 'utf-8'
        when 'windows-1252'
          body = Iconv.iconv("utf-8", "windows-1252", body).join('')
          charset = 'utf-8'
        when 'windows-1258'
          body = Iconv.iconv("utf-8", "windows-1258", body).join('')
          charset = 'utf-8'
        when 'koi8-r'
          body = Iconv.iconv("utf-8", "koi8-r", body).join('')
          charset = 'utf-8'
        when 'utf-8', 'us-ascii'
          charset = 'utf-8'
          # nothing to do
        when nil
          ## ???
        else
          body = "Unknown charset: #{charset}"
        end

        body = getHtmlText(body, charset) if st == 'html'

      rescue Iconv::IllegalSequence
        $stderr.puts "Iconv error #{charset}"
        body = nil
      rescue
        $stderr.puts $!.inspect
        body = nil
      end
    end
  end
#  p body
  body
end

def GetMetadataForFile(dict, ctype, path)
#  p [dict, ctype, path]
  authorAddresses = nil
  authors = nil
  recipientAddresses = nil
  recipients = nil
  title = nil
  date = nil
  body = nil

  begin
    mail = TMail::Mail.load(path)
    title = mail.subject
    date = mail.date
    authorAddresses = mail.from
    auhtors = mail.header_string('from').to_s.split(',').map! do |i|
      i = i.gsub(/<.*>/, '').gsub(/\A\s*"?|"?\s*\z/, '')
    end
    recipientAddresses = mail.to
    recipients = mail.header_string('to').to_s.split(',').map! do |i|
      i = i.gsub(/<.*>/, '').gsub(/\A\s*"?|"?\s*\z/, '')
    end
    body = getText(mail)
  rescue TMail::SyntaxError
    $stderr.puts "#{$0}: invalid mail"
    return nil
  rescue
    $stderr.puts $!.inspect
    return nil
  end

  if dict
    dict["kMDItemTitle"] = title if title
    dict["kMDItemDisplayName"] = title if title
    dict["kMDItemContentCreationDate"] = date if date
    dict["kMDItemAuthorEmailAddresses"] = authorAddresses if authorAddresses
    dict["kMDItemAuthors"] = auhtors if auhtors
    dict["kMDItemRecipientEmailAddresses"] = recipientAddresses if recipientAddresses
    dict["kMDItemRecipients"] = recipients if recipients
    dict["kMDItemTextContent"] = body if body

    dict["kMDItemContentType"] = "com.apple.mail.emlx"
    dict["kMDItemKind"] = { ""=>"emlx" }
  end
  true
end

if $0 == __FILE__
  ARGV.each do |f|
    p f
    dict = {}
    GetMetadataForFile(dict, "public.data", f)
    p dict
  end
end
