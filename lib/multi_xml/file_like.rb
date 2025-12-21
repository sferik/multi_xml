module MultiXml
  # Mixin that provides file-like metadata to StringIO objects.
  # Used when parsing base64-encoded file content from XML.
  module FileLike
    DEFAULT_FILENAME = "untitled".freeze
    DEFAULT_CONTENT_TYPE = "application/octet-stream".freeze

    attr_writer :original_filename, :content_type

    def original_filename
      @original_filename || DEFAULT_FILENAME
    end

    def content_type
      @content_type || DEFAULT_CONTENT_TYPE
    end
  end
end
