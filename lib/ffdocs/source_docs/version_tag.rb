module FFDocs::SourceDocs

  # Extract a stable version from a tag.
  #
  # `-dev` tags are ignored.
  VersionTag = Struct.new(
    :tag,
    :version,
    :major,
    :commit_hash,
    :commit_date,
    :cmp_key,
  ) do
    def self.parse(tag_data)
      tag, commit, date = tag_data.values_at("tag", "commit", "date")

      if tag =~ /\A[vn]?(\d+(?:\.\d+)+)\Z/
        version = $1
        major = version.split(".").take(2).join(".")

        # Compute a key to compare versions.
        #
        # We have to append `.0.0` to ensure that tags without major or minor
        # parts are computed properly.
        parts = "#{version}.0.0".split(".").take(3).map {|p| "%04d" % Integer(p, 10) }
        cmp_key = Integer(parts.join, 10)

        ::FFDocs::SourceDocs::VersionTag.new(
            tag,
            version,
            major,
            commit,
            date,
            cmp_key,
        )
      end
    end

    def <=>(other)
      self.cmp_key <=> other.cmp_key
    end
  end

end
