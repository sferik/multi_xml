module MultiXml
  # This module decorates files with the <tt>original_filename</tt>
  # and <tt>content_type</tt> methods.
  module FileLike # :nodoc:
    attr_writer :original_filename, :content_type

    def original_filename
      @original_filename || "untitled"
    end

    def content_type
      @content_type || "application/octet-stream"
    end
  end
end
