module FFDocs::View

  class VersionMatrixRenderer
    attr_reader :website

    def initialize(website)
      @website = website
      @output = website.path_for(:version_matrix)
    end

    def render
      ctx = VersionMatrixContext.new(self, @output)
      main_body = website.version_matrix_template.render(ctx)

      html = website.with_layout(
        main_body,
        path: @output,
        page_title: "FFmpeg Filters - Matrix",
        main_class: "version-matrix",
      )

      @output.write(html)
    end
  end

  VersionMatrixContext = Struct.new(:renderer, :path) do
    include ::FFDocs::View::WebsiteHelpers

    def website
      renderer.website
    end

    TableItem = Struct.new(:name, :versions, :link_url)

    def items_list
      items = {}
      path_parent = path.parent

      renderer.website.releases.sort_by(&:release).reverse.each do |release|
        major_version = release.release.major
        release.source.groups.each do |group|
          group.items.each do |item|
            slot = items[item.name]
            if slot.nil?
              items[item.name] = slot = TableItem.new(
                item.name,
                Set.new,
                renderer.website.path_for(item).relative_path_from(path_parent),
              )
            end

            slot.versions << major_version
          end
        end
      end

      items.values.sort_by(&:name)
    end
  end

end
