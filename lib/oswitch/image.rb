class OSwitch
  # Captures a docker image's metadata.
  Image = Struct.new :repository, :tag, :id, :created, :size

  class Image

    # Model Image's eigenclass as a collection of Image objects.
    class << self

      include Enumerable

      def all
        `docker images`.split("\n").drop(1).
          map{|l| Image.new(*l.split(/\s{2,}/))}
      end

      def each(&block)
        all.each(&block)
      end

      def get(imgname)
        repository, tag = imgname.split(':')
        return if not repository or repository.empty?
        tag = 'latest' if not tag or tag.empty?
        find {|img| img.repository == repository and img.tag == tag}
      end

      def exists?(imgname)
        !!get(imgname)
      end
    end
  end
end
