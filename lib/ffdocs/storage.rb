require "pathname"
require "zlib"

require_relative "source_docs"

class FFDocs::Storage

  STORAGE_DIR = Pathname.new(File.expand_path("../../../target/storage", __FILE__))

  def initialize
    @repository = ::FFDocs::SourceDocs::Repository.new

    if not STORAGE_DIR.directory?
      STORAGE_DIR.mkpath
      STORAGE_DIR.join("CACHEDIR.TAG").write("")
    end
  end

  # Return a list of tags for the latest release of each major version.
  memoize def releases
    cached_file = STORAGE_DIR.join("release_tags.json")

    # Get existing tags from the repository.
    repository_tags =
      if cached_file.exist?
        JSON.parse(File.read(cached_file))
      else
        @repository.tags.to_a.tap {|t| cached_file.write(t.to_json) }
      end

    # Find newest tag for each major version.
    version_tags = {}
    repository_tags.each do |tag|
      vt = ::FFDocs::SourceDocs::VersionTag.parse(tag)
      next if vt.nil?

      version_tags[vt.major] = [ vt, version_tags[vt.major] ].compact.max
    end

    version_tags.values.sort.reverse
  end

  # Download a blob from a specific tag.
  def download(tag, path)
    # Blob hash.
    cached_file_name = [ "hash", tag, path ].join("--").gsub(/[^a-zA-Z0-9._-]/) { "_%02X_" % $&.ord }
    cached_file = STORAGE_DIR.join(cached_file_name)

    if cached_file.exist?
      hash = cached_file.read
    else
      hash = @repository.blob_hash(tag, path)
      cached_file.write(hash)
    end

    return nil if hash.nil? || hash.empty?

    # Blob data
    gzcache(STORAGE_DIR.join("blob-#{hash}.gz")) do
      ::FFDocs.log.info "Download blob #{hash} for #{tag}:#{path} ..."
      @repository.blob_data(hash)
    end
  end

  # Cache the result of the block in a gzipped file.
  def gzcache(filename, &block)
    cached_file = STORAGE_DIR.join(filename)

    if cached_file.exist?
      Zlib::GzipReader.open(cached_file) do |gz|
        gz.read
      end
    else
      data = block.call
      Zlib::GzipWriter.open(cached_file, 9) do |gz|
        gz.write(data)
      end
      data
    end
  end

end
