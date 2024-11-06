# frozen_string_literal: true

require_relative "code_examples_lexer"

module FFDocs::SourceDocs
  class HTMLAdapter

    HTMLData = Struct.new(:html, :anchors)

    def initialize(options)
      @options = options
    end

    def process(doc)
      if not @options.no_highlighter
        doc = stylize_code_blocks(doc)
      end

      anchors = doc.search("a[name]").map {|anchor| anchor["name"] }

      HTMLData.new(doc, anchors)
    end

    # Apply syntax highlighting to `<pre>` elements.
    private def stylize_code_blocks(doc)
      doc.search("pre").each do |elem|
        code = elem.inner_text.strip
        if result = SyntaxHighlight.highlight(code)
          # Replace <pre> with the generated HTML.
          elem.set_attribute("data-source", code)
          elem.inner_html = Nokogiri::HTML5.fragment(result)
        end
      end

      doc
    end

    module SyntaxHighlight
      def self.highlight(code)
        if lexer = guess_lexer(code)
          formatter = Rouge::Formatters::HTMLInline.new(Rouge::Themes::Github.new)
          formatter.format(lexer.lex(code))
        end
      end

      def self.guess_lexer(code)
        case code.lstrip
        when /\A__kernel/
          Rouge::Lexers::C.new
        when %r{\A#!.*/sh}, /\Aecho /
          Rouge::Lexers::Shell.new
        when /\A(-i|ffplay|ffmpeg|ffprobe)/, /\A(#.+\n)*(\.\/)?(ffplay|ffmpeg|ffprobe)/
          CodeExamplesLexer.new
        when /\A(\[(\w|-)+\]|\w+=)/, /\A\w+\[\w\]/
          CodeExamplesLexer.new :filtergraph
        end
      end
    end

  end
end
