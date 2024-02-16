module FFDocs::SourceDocs

  module SaxonbCmd

    CACHED = []

    CANDIDATES = %w(saxonb saxonb-xslt)

    def self.get_path
      if CACHED.empty?
        CANDIDATES.each do |candidate|
          child =
            begin
              IO.popen([candidate, "-?"], "r", in: "/dev/null", err: [:child, :out])
            rescue Errno::ENOENT
              next
            end

          resp = child.read
          Process.waitpid(child.pid)
          if $?.success? and resp.start_with?("Saxon 9")
            CACHED << candidate
            break
          end
        end
      end

      CACHED.first or raise("Saxonb 9 not found")
    end

  end

end
