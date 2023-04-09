module FFDocs
  def self.log
    @logger ||= Logger.new(STDERR)
  end
end

require_relative "ffdocs/std_patches"

require_relative "ffdocs/source_docs"
require_relative "ffdocs/storage"
require_relative "ffdocs/view"
