#! ruby -EUTF-8
# encoding: utf-8

def RomanNumeral num
  case num
  when "I"    then num = "Ｉ"
  when "II"   then num = "Ⅱ"
  when "III"  then num = "Ⅲ"
  when "IV"   then num = "Ⅳ"
  when "V"    then num = "Ⅴ"
  when "VI"   then num = "Ⅵ"
  when "VII"  then num = "Ⅶ"
  when "VIII" then num = "Ⅷ"
  when "IX"   then num = "Ⅸ"
  when "X"    then num = "Ⅹ"
  when "XI"   then num = "Ⅺ"
  when "XII"  then num = "Ⅻ"
  end

  num
end

# class Output
#   def preamble
#   def postamble
#   def chapter num
#   def output character
#   def eof
# end
class DebugOutput
  def begindocument
    puts "begindocument"
  end

  def chapter num
    puts "chapter #{num.inspect}"
  end

  def output str
    puts "output #{str.inspect}"
  end

  def beginline
    puts "beginline"
  end

  def newline
    puts "newline"
  end

  def endline
    puts "endline"
  end

  def character chr
    puts "character #{chr.inspect}"
  end

  def ruby kanji, rubi
    puts "ruby #{kanji.inspect}, #{rubi.inspect}"
  end

  def break
    puts "break"
  end

  def eof
    puts "eof"
  end

end


class LaTeX
  attr_accessor :documentstyle
  attr_accessor :documentoptions
  attr_accessor :preamble

  def initialize outstream
    @out = outstream
    @documentstyle = "treport"
    @documentoptions = "a5j"
    @preamble = "\\usepackage{okumacro}\n"
  end

  def escape str
    str.each_char.map{|chr|
      case chr
      when "%"
        "\\%"
      when "\\"
        "\\textbackslash "
      when "_"
        "\\_"
      when "&"
        "\\&"
      else
        chr
      end
    }.join
  end

  def begindocument
    @out.print "\\documentclass[#{@documentoptions}]{#{@documentstyle}}\n"
    @out.print @preamble
    @out.print "\\begin{document}\n"
  end

  def chapter num
    @out.print "\\chapter{#{num}}\n"
  end

  def output str
    @out.print str
  end

  def beginline
  end

  def newline
    @out.print "\\noindent\\null "
  end

  def endline
    @out.print "\n\n"
  end

  def character chr
    @out.print escape(chr)
  end

  def code str
    @out.print "{\\tt "
    @out.print escape(str)
    @out.print "}\n"
  end

  def ruby kanji, rubi
    @out.print "\\ruby{#{kanji}}{#{rubi}}"
  end

  def shortmath str
    @out.print "\\mbox{\\yoko $#{str}$}"
  end

  def math str
    @out.print "$#{str}$\n"
  end

  def break
    @out.print "\\bigbreak\n"
  end

  def eof
    @out.print "\\end{document}\n"
  end
end

class Input
  def proc state, str, out
    eol = /\r?\n/

    if state == :NEWLINE && str[0] == "\uFEFF"
      ## BOM
      puts "BOM" if $DEBUG
      newstr = str[1..-1]

      # discard

      newstate = :NEWLINE

    elsif state == :NEWLINE && str =~ /\A　　(Ｉ|II|III|Ⅳ|V|VI|VII|VIII|IX|X|XI|XII)#{eol}+/
      num = $1
      newstr = Regexp.last_match.post_match
      p ["chapter", num, newstr[0..9]] if $DEBUG

      out.chapter(RomanNumeral(num))

      newstate = :NEWLINE

    elsif state == :NEWLINE && str =~ /\A#{eol}/
      ## 空行
      newstr = Regexp.last_match.post_match
      p ["break", newstr[0..9]] if $DEBUG

      out.break

      newstate = :NEWLINE

    elsif str =~ /\A#{eol}/
      ## 行末
      newstr = Regexp.last_match.post_match
      p ["endline", newstr[0..9]] if $DEBUG

      out.endline

      newstate = :NEWLINE

    # elsif state == :NEWLINE && str =~ /\A　?(%? ?ruby .*?)#{eol}/
    #   ## コード
    #   newstr = Regexp.last_match.post_match

    #   out.code $1

    #   newstate = :NEWLINE

    elsif state == :NEWLINE && str =~ /\A(　| +)/
      ## 段落字下げ
      newstr = Regexp.last_match.post_match
      p ["beginline", newstr[0..9]] if $DEBUG

      out.beginline

      newstate = :NORMAL

    elsif state == :NEWLINE && str =~ /\A(.)/
      ## 字下げの無い改行
      newstr = str
      p ["newline", newstr[0..9]] if $DEBUG

      out.newline

      newstate = :NORMAL

    elsif state == :NORMAL && str =~ /\A([0-9א]+[_^][0-9]+)/
      ## 10^12
      newstr = Regexp.last_match.post_match
      p ["shortmath", newstr[0..9]] if $DEBUG

      out.shortmath $1

      newstate = :NORMAL

    elsif state == :NORMAL && str =~ /\A(([-a-zA-Z^\/λ ])+ *= *([-0-9a-zA-Z^\/λ= (){}（）｛｝])+)/
      ## math
      expr = $1
      newstr = Regexp.last_match.post_match
      p ["math", newstr[0..9]] if $DEBUG

      expr.tr! "（）｛｝", "(){}"
      expr.gsub!(/λ/, "\\lambda ")
      out.math expr

      newstate = :NORMAL

    # elsif state == :NORMAL && str =~ /\A(ruby [a-zA-Z0-9.]*)/
    #   ## コード
    #   newstr = Regexp.last_match.post_match
    #   p ["code", newstr[0..9]] if $DEBUG

    #   out.code $1

    #   newstate = :NORMAL

    elsif state == :NORMAL && str =~ /\A\#\{([^}]*)\}\{([^}]*)\}/
      ## #{漢字}{るび}
      newstr = Regexp.last_match.post_match
      p ["ruby", newstr[0..9]] if $DEBUG

      out.ruby $1, $2

      newstate = :NORMAL

    elsif state == :NORMAL && str =~ /\A([a-zA-Z][-a-zA-Z_0-9]{2,})/
      ## 英単語、略語
      chr = $1
      newstr = Regexp.last_match.post_match
      p [chr, newstr[0..9]] if $DEBUG

      out.character chr

      newstate = :NORMAL

    elsif str =~ /\A(.)/
      chr = str[0]
      newstr = str[1..-1]
      p [chr, newstr[0..9]] if $DEBUG

      out.character chr

      newstate = :NORMAL

    elsif str == ""
      newstr = ""
      p "EOF" if $DEBUG

      out.eof

      newstate = :EOF

    else
      fail
    end

    [newstate, newstr]
  end
end

def scan str, input, output
  output.begindocument
  state = :NEWLINE
  while state != :EOF
    p [state, str[0..10]] if $DEBUG
    state, str = input.proc(state, str, output)
  end
end

def setup_tankobon out
  out.documentstyle = "treport"
  out.documentoptions = "a5j"
  out.preamble = <<'EOS'
\usepackage{okumacro}
\setlength\textheight{18\Cvs}
\setlength\textwidth{43\Cwd}
\setlength\bigskipamount{1\Cvs}
\makeatletter
\def\@makechapterhead#1{\hbox{}%
  \vskip1\Cvs
  {\parindent\z@
   \raggedright
   \leavevmode
   \null\hskip10\Cwd#1\relax}\nobreak\vskip2\Cvs}
\makeatother
EOS
end

def main
  str = ARGF.read
  input = Input.new
  output = LaTeX.new $stdout
  setup_tankobon output
  # output = DebugOutput.new
  scan str, input, output
end

main
