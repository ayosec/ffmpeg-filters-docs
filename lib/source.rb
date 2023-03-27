# frozen_string_literal: true

require "nokogiri"
require "digest/sha2"

class Source

  SOURCE_FILE =  "doc/filters.texi"

  class SourceNotFound < StandardError; end

  Group = Data.define(:media_type, :component, :items)

  Item = Data.define(:name, :html)

  attr_reader :groups

  def initialize(storage, release)
    @storage = storage
    @release = release

    cache_name = "docs-#{release.tag}.xml.gz".gsub(/[^a-zA-Z0-9._-]/) { "_%02X_" % $&.ord }
    source = storage.gzcache(cache_name) do
      source = storage.download(release.tag, SOURCE_FILE)
      raise SourceNotFound if source.nil?

      STDERR.puts "Converting texinfo source to XML for #{release.tag} ..."
      IO.popen(%w(makeinfo --xml --no-split --output=-), "r+") do |io|
        io.write(source)
        io.close_write
        io.read
      end
    end

    xml = parse_source(source)
    parse_xml(xml)
  end

  # Parse the source in XML.
  #
  # To apply the entities, it downloads the DTD and re-parse the file using a
  # path to a local file.
  private def parse_source(source)
    doc = Nokogiri::XML.parse(source)

    dtd = doc.internal_subset
    doc.internal_subset.remove
    doc.create_internal_subset(
      dtd.name,
      dtd.external_id,
      dtd_path(dtd),
    )

    # We have to re-parse it, so the entities defined in the
    # DTD are substitute.
    Nokogiri::XML::Document.parse(
      doc.to_xml,
      nil,
      nil,
      Nokogiri::XML::ParseOptions::DEFAULT_XSLT
    )
  end

  # Extract groups and items from the XML document.
  private def parse_xml(xml)
    @groups = []
    xml.search(":root > chapter").each do |chapter|
      if chapter.at("sectiontitle").inner_text =~ /\A(.*) (Filters|Sinks|Sources)\Z/
        @groups << parse_group(chapter, $1, $2)
      end
    end
  end

  # Parse a <chapter> in the XML to build a group.
  private def parse_group(elem, media_type, component)
    stylesheet = self.content_stylesheet

    items = elem.search("> section").map do |section|
      name = section.at("sectiontitle").inner_text

      doc = Nokogiri::XML::Document.new

      doc.root = section
      html = stylesheet.transform(doc).to_html

      Item.new(name: name, html: html)
    end

    Group.new(media_type: media_type, component: component, items: items)
  end

  # Return an instance of the XSLT stylesheet used to convert the XML generated
  # by `makeinfo` to the HTML that will be included in the generated pages.
  private def content_stylesheet
    @@stylesheet ||=
      begin
        xslt_source = File.read(File.expand_path("../section_content.xsl", __FILE__))
        Nokogiri::XSLT.parse(xslt_source)
      end
  end

  # Download the DTD from the URL, and returns the path to the file in the local
  # cache.
  private def dtd_path(dtd)
    url = dtd.system_id.sub(/^http:/, "https:")
    file = Storage::STORAGE_DIR.join("#{Digest::SHA2.hexdigest(url)}.dtd")
    if not file.exist?
      response = Faraday.get(url)
      if response.success?
        file.write(response.body)
      else
        STDERR.puts "DTD failed: #{url}"
      end
    end

    file.relative_path_from(Dir.pwd).to_path
  end

end
