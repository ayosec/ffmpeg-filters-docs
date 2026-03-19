# frozen_string_literal: true

require "rouge"

class VGSLexer < Rouge::RegexLexer
  title "VGS"
  desc "VGS for Drawvg"
  tag "vgs"

  state :root do
    rule /\b[a-z]+@\d+\.\d+\b/, Literal::String

    rule /\b[a-z]{2,}\b/, Name::Function

    rule /\b[0-9]+\b do/, Literal::Number

    rule /./m, Text
  end

end
