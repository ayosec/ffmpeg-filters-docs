# frozen_string_literal: true

require "rouge"

class CodeExamplesLexer < Rouge::RegexLexer
  title "CodeExamples"
  desc "Code examples in FFmpeg documentation"
  tag "ffmpegExamples"

  def initialize(initial_state = nil, debug: false)
    super()
    @debug = debug
    @initial_state = initial_state
  end

  start do
    @delimiters = {}
    @current_program = nil
    @input_is_filtergraph = false

    if @initial_state
      goto @initial_state

      # If the initial state is not :root, we assume that the whole code is
      # surrounded by a quote. Thus, spaces will not interpreted as the end
      # of a CLI argument.
      @delimiters[:all] = 0
    end
  end

  CLI_ARGUMENT = Name::Tag

  state :root do
    rule /(?:\.\/)?(ffplay|ffmpeg|ffprobe)\b/ do |m|
      @current_program = m[1]
      token Name::Namespace
    end

    rule %r/#.*$/, Comment

    rule /(-vf|-af|-filter_complex|-lavfi)\b/ do
      token CLI_ARGUMENT

      push_after_spaces :filtergraph
    end

    rule /-f\b/ do
      token CLI_ARGUMENT

      push_after_spaces do
        mixin :shell_word

        rule /lavfi/ do
          token Name::Constant
          @input_is_filtergraph = true
          pop!
        end

        rule(//) do
          @input_is_filtergraph = false
          pop!
        end
      end
    end

    rule /-i\b/ do
      token CLI_ARGUMENT

      if @input_is_filtergraph
        @input_is_filtergraph = false
        push_after_spaces :filtergraph
      end
    end

    rule /-\S+/, CLI_ARGUMENT

    rule /\s+/, Text::Whitespace

    rule /\\\n/, Literal::String::Escape

    rule(//) do
      # Free arguments.
      #
      # If the program is ffplay/ffprobe, and the `-f` is `lavfi`.
      # the free argument is parsed as a filtergraph.
      if %w(ffplay ffprobe).include?(@current_program) and @input_is_filtergraph
        @input_is_filtergraph = false
        push :filtergraph
      else
        push do
          mixin :shell_word
          rule /./m, Text
        end
      end
    end
  end

  state :filtergraph do
    mixin :shell_word
    mixin :link_label
    mixin :filters_separator

    rule /\w+/ do
      token Name::Function

      push do
        rule /@\w+/, Name::Label, :pop!

        rule(//) { pop! }
      end
    end

    rule /\=/, Operator, :filter_params
  end

  state :filter_params do
    mixin :link_label
    mixin :shell_word
    mixin :filters_separator

    rule /(\w+)=/ do |m|
      token Name::Attribute, m[1]
      token Operator, "=".dup
      push :filter_param_value
    end

    rule(//) do
      push :filter_param_value
    end
  end

  state :filter_param_value do
    mixin :link_label
    mixin :shell_word
    mixin :filters_separator

    rule /[()]/, Operator

    rule /:/, Operator, :pop!

    rule /./m, Text
  end

  state :link_label do
    rule /\[\w+([:+-]\w+)*\]/, Literal::Number
  end

  # Tracks quoted strings and space-separated words.
  state :shell_word do

    rule /['"]/ do |m|
      token Str

      delimiter = m[0]
      if stack_size = @delimiters.delete(delimiter)
        # If a delimiter is found after another one is active, we close the
        # current state and jump where the first delimiter was found.

        remove = stack.size - stack_size

        puts "[:shell_word] pop #{remove} items for delimiter #{delimiter.inspect}" if @debug

        if remove > 0
          pop!(remove)
        end
      else
        puts "[:shell_word] set stack size #{stack.size} for delimiter #{delimiter.inspect}" if @debug
        @delimiters[delimiter] = stack.size
      end
    end

    rule /\s+/ do
      token Text::Whitespace

      # A space is found with no active delimiter. The parser is moved
      # to the root state.
      if @delimiters.empty?
        pop!(stack.size - 1)
      end
    end

    # Escaped sequences (like `\n`).
    rule /\\/ do
      token Literal::String::Escape

      push do
        rule /./m, Literal::String::Escape, :pop!
      end
    end
  end

  # Jump to :filtergraph state when either `,` or `;` is found. If a quote
  # is found before the target state, the separator will be emitted as text,
  # and no jump is done.
  state :filters_separator do
    rule /[,;]/ do
      last_quote = @delimiters.values.max || 0

      target_state = stack.each_with_index.filter_map {|s, i| s.name == :filtergraph ? i + 1 : nil }.last
      p [ :filters_separator, target_state, stack.size, last_quote ] if @debug

      if target_state < last_quote
        # Character is inside a quoted string.
        token Text
      else
        token Operator
        if stack.size > target_state
          pop!(stack.size - target_state)
        end
      end
    end
  end

  # Skip whitespaces and jump to another state.
  def push_after_spaces(next_state = nil, &next_state_block)
    push do
      rule /\s+/, Text::Whitespace

      rule(//) do
        pop!

        if next_state
          push(next_state)
        else
          push(&next_state_block)
        end
      end
    end
  end

end
