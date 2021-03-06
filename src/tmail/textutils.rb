#
# textutils.rb
#
# Copyright (c) 1998-2004 Minero Aoki
#
# This program is free software.
# You can distribute/modify this program under the terms of
# the GNU Lesser General Public License version 2.1.
#

module TMail

  class SyntaxError < StandardError; end


  module TextUtils

    private

    def new_boundary
      'mimepart_' + random_tag()
    end

    @@uniq = 0

    def random_tag
      @@uniq += 1
      t = Time.now
      sprintf('%x%x_%x%x%d%x',
              t.to_i, t.tv_usec,
              $$, Thread.current.id, @@uniq, rand(255))
    end

    aspecial     = '()<>[]:;.@\\,"'
    tspecial     = '()<>[];:@\\,"/?='
    lwsp         = " \t\r\n"
    control      = '\x00-\x1f\x7f-\xff'

    ATOM_UNSAFE   = /[#{Regexp.quote aspecial}#{control}#{lwsp}]/n
    PHRASE_UNSAFE = /[#{Regexp.quote aspecial}#{control}]/n
    TOKEN_UNSAFE  = /[#{Regexp.quote tspecial}#{control}#{lwsp}]/n
    CONTROL_CHAR  = /[#{control}]/n
    RFC2231_UNSAFE = /[#{Regexp.quote tspecial}#{control}#{lwsp}\*\'\%]/n

    def atom_safe?(str)
      ATOM_UNSAFE !~ str
    end

    def quote_atom(str)
      (ATOM_UNSAFE =~ str) ? dquote(str) : str
    end

    def quote_phrase(str)
      (PHRASE_UNSAFE =~ str) ? dquote(str) : str
    end

    def token_safe?(str)
      TOKEN_UNSAFE !~ str
    end

    def quote_token(str)
      (TOKEN_UNSAFE =~ str) ? dquote(str) : str
    end

    def dquote(str)
      '"' + str.gsub(/["\\]/n) {|s| '\\' + s } + '"'
    end
    private :dquote

    def join_domain(arr)
      arr.map {|i| (/\A\[.*\]\z/ =~ i) ? i : quote_atom(i) }.join('.')
    end

    ZONESTR_TABLE = {
      'jst' =>   9 * 60,
      'eet' =>   2 * 60,
      'bst' =>   1 * 60,
      'met' =>   1 * 60,
      'gmt' =>   0,
      'utc' =>   0,
      'ut'  =>   0,
      'nst' => -(3 * 60 + 30),
      'ast' =>  -4 * 60,
      'edt' =>  -4 * 60,
      'est' =>  -5 * 60,
      'cdt' =>  -5 * 60,
      'cst' =>  -6 * 60,
      'mdt' =>  -6 * 60,
      'mst' =>  -7 * 60,
      'pdt' =>  -7 * 60,
      'pst' =>  -8 * 60,
      'a'   =>  -1 * 60,
      'b'   =>  -2 * 60,
      'c'   =>  -3 * 60,
      'd'   =>  -4 * 60,
      'e'   =>  -5 * 60,
      'f'   =>  -6 * 60,
      'g'   =>  -7 * 60,
      'h'   =>  -8 * 60,
      'i'   =>  -9 * 60,
      # j not use
      'k'   => -10 * 60,
      'l'   => -11 * 60,
      'm'   => -12 * 60,
      'n'   =>   1 * 60,
      'o'   =>   2 * 60,
      'p'   =>   3 * 60,
      'q'   =>   4 * 60,
      'r'   =>   5 * 60,
      's'   =>   6 * 60,
      't'   =>   7 * 60,
      'u'   =>   8 * 60,
      'v'   =>   9 * 60,
      'w'   =>  10 * 60,
      'x'   =>  11 * 60,
      'y'   =>  12 * 60,
      'z'   =>   0 * 60
    }

    def timezone_string_to_unixtime(str)
      if m = /([\+\-])(\d\d?)(\d\d)/.match(str)
        sec = (m[2].to_i * 60 + m[3].to_i) * 60
        (m[1] == '-') ? -sec : sec
      else
        min = ZONESTR_TABLE[str.downcase] or
                raise SyntaxError, "wrong timezone format '#{str}'"
        min * 60
      end
    end

    WDAY = %w( Sun Mon Tue Wed Thu Fri Sat TMailBUG )
    MONTH = %w( TMailBUG Jan Feb Mar Apr May Jun
                         Jul Aug Sep Oct Nov Dec TMailBUG )

    def time2str(tm)
      # [ruby-list:7928]
      gmt = Time.at(tm.to_i)
      gmt.gmtime
      offset = tm.to_i - Time.local(*gmt.to_a[0,6].reverse).to_i

      # DO NOT USE strftime: setlocale() breaks it
      sprintf '%s, %s %s %d %02d:%02d:%02d %+.2d%.2d',
              WDAY[tm.wday], tm.mday, MONTH[tm.month],
              tm.year, tm.hour, tm.min, tm.sec,
              *(offset / 60).divmod(60)
    end

    MESSAGE_ID = /<[^\@>]+\@[^>\@]+>/

    def message_id?(str)
      MESSAGE_ID =~ str
    end

    def mime_encoded?(str)
      /=\?[^\s?=]+\?[QB]\?[^\s?=]+\?=/i =~ str
    end

    def decode_params(hash)
      new = Hash.new
      encoded = nil
      hash.each do |key, value|
        if m = /\*(?:(\d+)\*)?\z/.match(key)
          ((encoded ||= {})[m.pre_match] ||= [])[(m[1] || 0).to_i] = value
        else
          new[key] = to_kcode(value)
        end
      end
      if encoded
        encoded.each do |key, strings|
          new[key] = decode_RFC2231(strings.join(''))
        end
      end

      new
    end

    NKF_FLAGS = {
      'EUC'  => '-e -m',
      'SJIS' => '-s -m',
      'UTF8' => '-w -m'
    }

    def to_kcode(str)
      flag = NKF_FLAGS[$KCODE] or return str
      NKF.nkf(flag, str)
    end

    RFC2231_ENCODED = /\A(?:iso-2022-jp|euc-jp|shift_jis|us-ascii)?'[a-z]*'/in

    def decode_RFC2231(str)
      m = RFC2231_ENCODED.match(str) or return str
      NKF.nkf(NKF_FLAGS[$KCODE],
              m.post_match.gsub(/%[\da-f]{2}/in) {|s| s[1,2].hex.chr })
    end

  end

end
