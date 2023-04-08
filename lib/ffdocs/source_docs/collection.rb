# frozen_string_literal: true

require "nokogiri"
require "digest/sha2"

require_relative "html_adapter"

module FFDocs::SourceDocs

  PATCHES_DIR = Pathname.new(File.expand_path("../patches", __FILE__))

  class SourceNotFound < StandardError; end

  Group = Struct.new(
    :release,
    :media_type,
    :component,
    :items,
    keyword_init: true
  )

  Item = Struct.new(
    :group,
    :name,
    :first_version,
    :html,
    :description,
    keyword_init: true,
  )

  class Collection

    SOURCE_FILE =  "doc/filters.texi"

    attr_reader :storage, :groups, :anchors

    def initialize(storage, release)
      @html_adapter = HTMLAdapter.new
      @storage = storage
      @release = release

      @groups = []
      @anchors = {}

      cache_name = "docs-#{release.tag}.xml.gz".gsub(/[^a-zA-Z0-9._-]/) { "_%02X_" % $&.ord }
      source = storage.gzcache(cache_name) do
        source = storage.download(release.tag, SOURCE_FILE)
        raise SourceNotFound if source.nil?

        # Apply local patches, if any.
        patch = PATCHES_DIR.join("#{release.version}.patch")
        if patch.exist?
          tmpfile = Tempfile.new("ffdocs-source")
          tmpfile.write(source)
          tmpfile.close

          diff = patch.read

          command = %w(patch --batch --output=- --input=-)
          command << tmpfile.path

          IO.popen(command, "r+") do |io|
            io.write(diff)
            io.close_write
            source = io.read
          end
        end

        STDERR.puts "Converting texinfo source to XML for #{release.tag} ..."
        IO.popen(%w(makeinfo --xml --no-split --output=-), "r+") do |io|
          io.write(source)
          io.close_write
          io.read
        end
      end

      xml = parse_source(source)
      parse_xml(release, xml)
    end

    # Parse the source in XML.
    #
    # To apply the entities, it downloads the DTD and re-parse the file using a
    # path to a local file.
    private def parse_source(source)
      doc = Nokogiri::XML.parse(source)

      if dtd = doc.internal_subset
        doc.internal_subset.remove
        doc.create_internal_subset(
          dtd.name,
          dtd.external_id,
          dtd_path(dtd),
        )
      end

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
    private def parse_xml(release, xml)
      # Adjust <anchor> references.
      xml.search("anchor").each do |anchor|
        name = anchor["name"]
        label = anchor.inner_text

        elem = anchor
        while elem = elem.next_element
          break if elem.name != "anchor"
        end

        # If <anchor> is at the end, and the name is different to the content,
        # try to apply the reference to the next element of the parent.
        if elem.nil? && name != label
          elem = anchor.parent
          while elem.next_element.nil?
            elem = elem.parent
          end

          elem = elem.next_element
        end

        if elem
          elem.set_attribute("ref-name", name)
        end
      end

      # Split sections and collect items for each component/media-type group.
      xml.search(":root > chapter").each do |chapter|
        if chapter.at("sectiontitle").inner_text =~ /\A(.*) (Filters|Sinks|Sources)\Z/
          @groups << parse_group(release, chapter, $1, $2)
        end
      end
    end

    # Parse a <chapter> in the XML to build a group.
    private def parse_group(release, elem, media_type, component)
      stylesheet = self.content_stylesheet

      group = Group.new(release: release, media_type: media_type, component: component)

      group.items = elem.search("> section").
        select {|section| section.at("sectiontitle").inner_text != "Examples" }.
        flat_map \
      do |section|
        sectiontitle = section.at("sectiontitle").inner_text.split(",")

        doc = Nokogiri::XML::Document.new
        doc.root = section

        html = stylesheet.transform(doc).to_html
        html_data = @html_adapter.process(html)

        # Use the first sentence of the section as the description.
        #
        # If the <section> contains multiple filters, it may use different
        # paragraphs to describe each one. To detect those cases, we search
        # a <para> containing a <code> with the filter name.
        base_desc = [ section.at("para").inner_text.split(".", 2).first, "." ].join

        sectiontitle.map(&:strip).map do |name|
          desc = base_desc

          if sectiontitle.size > 1
            elem = section.search("para > code").find {|elem| elem.inner_text == name }
            if elem
              desc = [ elem.parent.inner_text.split(".", 2).first, "." ].join
            end
          end

          item = Item.new(
            group: group,
            name: name,
            html: html_data.html,
            description: desc
          )

          # Store references found in this item
          html_data.anchors.each do |anchor|
            @anchors[anchor] = item
          end

          item
        end
      end

      group
    end

    # Return an instance of the XSLT stylesheet used to convert the XML generated
    # by `makeinfo` to the HTML that will be included in the generated pages.
    memoize private def content_stylesheet
      xslt_source = File.read(File.expand_path("../section_content.xsl", __FILE__))
      Nokogiri::XSLT.parse(xslt_source, {})
    end

    # Download the DTD from the URL, and returns the path to the file in the local
    # cache.
    private def dtd_path(dtd)
      url = dtd.system_id.sub(/^http:/, "https:")
      file = FFDocs::Storage::STORAGE_DIR.join("#{Digest::SHA2.hexdigest(url)}.dtd")
      if not file.exist?
        response = Typhoeus.get(url)
        if response.success?
          file.write(response.body)
        else
          STDERR.puts "DTD failed: #{url}"
        end
      end

      file.relative_path_from(Dir.pwd).to_path
    end

  end

end
