require "test_helper"
require "mutant/minitest/coverage"

# Tests for FileLikeOriginalFilenameTest
class FileLikeOriginalFilenameTest < Minitest::Test
  cover "MultiXml*"

  def test_original_filename_returns_custom_value_when_set
    io = StringIO.new("test")
    io.extend(MultiXml::FileLike)
    io.original_filename = "custom.txt"

    assert_equal "custom.txt", io.original_filename
  end

  def test_original_filename_returns_default_when_not_set
    io = StringIO.new("test")
    io.extend(MultiXml::FileLike)

    assert_equal "untitled", io.original_filename
    assert_equal MultiXml::FileLike::DEFAULT_FILENAME, io.original_filename
  end

  def test_original_filename_returns_default_when_set_to_nil
    io = StringIO.new("test")
    io.extend(MultiXml::FileLike)
    io.original_filename = nil

    assert_equal "untitled", io.original_filename
  end

  def test_original_filename_uses_instance_variable_not_method_call
    # The mutant would cause infinite recursion
    io = StringIO.new("test")
    io.extend(MultiXml::FileLike)
    io.original_filename = "test.xml"

    # Should not cause stack overflow
    assert_equal "test.xml", io.original_filename
  end

  def test_original_filename_returns_set_value_not_always_default
    io = StringIO.new("test")
    io.extend(MultiXml::FileLike)
    io.original_filename = "my_file.pdf"

    refute_equal MultiXml::FileLike::DEFAULT_FILENAME, io.original_filename
    assert_equal "my_file.pdf", io.original_filename
  end

  def test_original_filename_with_falsy_but_present_value
    io = StringIO.new("test")
    io.extend(MultiXml::FileLike)
    # Not setting original_filename leaves @original_filename as nil

    refute_nil io.original_filename
    assert_equal "untitled", io.original_filename
  end

  def test_original_filename_does_not_raise
    io = StringIO.new("test")
    io.extend(MultiXml::FileLike)

    assert_equal "untitled", io.original_filename
  end

  def test_original_filename_returns_actual_value_not_nil
    io = StringIO.new("test")
    io.extend(MultiXml::FileLike)

    refute_nil io.original_filename
  end

  def test_original_filename_prefers_instance_variable_over_default
    io = StringIO.new("test")
    io.extend(MultiXml::FileLike)
    io.original_filename = "specific.doc"

    assert_equal "specific.doc", io.original_filename
    refute_equal "untitled", io.original_filename
  end

  def test_original_filename_body_is_needed
    io = StringIO.new("test")
    io.extend(MultiXml::FileLike)

    result = io.original_filename

    refute_nil result
    assert_kind_of String, result
  end
end

# Tests for FileLikeContentTypeTest
class FileLikeContentTypeTest < Minitest::Test
  cover "MultiXml*"

  def test_content_type_returns_custom_value_when_set
    io = StringIO.new("test")
    io.extend(MultiXml::FileLike)
    io.content_type = "text/plain"

    assert_equal "text/plain", io.content_type
  end

  def test_content_type_returns_default_when_not_set
    io = StringIO.new("test")
    io.extend(MultiXml::FileLike)

    assert_equal "application/octet-stream", io.content_type
    assert_equal MultiXml::FileLike::DEFAULT_CONTENT_TYPE, io.content_type
  end

  def test_content_type_returns_default_when_set_to_nil
    io = StringIO.new("test")
    io.extend(MultiXml::FileLike)
    io.content_type = nil

    assert_equal "application/octet-stream", io.content_type
  end

  def test_content_type_uses_instance_variable_not_method_call
    # The mutant would cause infinite recursion
    io = StringIO.new("test")
    io.extend(MultiXml::FileLike)
    io.content_type = "image/png"

    # Should not cause stack overflow
    assert_equal "image/png", io.content_type
  end

  def test_content_type_returns_set_value_not_always_default
    io = StringIO.new("test")
    io.extend(MultiXml::FileLike)
    io.content_type = "application/pdf"

    refute_equal MultiXml::FileLike::DEFAULT_CONTENT_TYPE, io.content_type
    assert_equal "application/pdf", io.content_type
  end

  def test_content_type_with_falsy_but_present_value
    io = StringIO.new("test")
    io.extend(MultiXml::FileLike)
    # Not setting content_type leaves @content_type as nil

    refute_nil io.content_type
    assert_equal "application/octet-stream", io.content_type
  end

  def test_content_type_does_not_raise
    io = StringIO.new("test")
    io.extend(MultiXml::FileLike)

    assert_equal "application/octet-stream", io.content_type
  end

  def test_content_type_returns_actual_value_not_nil
    io = StringIO.new("test")
    io.extend(MultiXml::FileLike)

    refute_nil io.content_type
  end

  def test_content_type_prefers_instance_variable_over_default
    io = StringIO.new("test")
    io.extend(MultiXml::FileLike)
    io.content_type = "text/html"

    assert_equal "text/html", io.content_type
    refute_equal "application/octet-stream", io.content_type
  end

  def test_content_type_body_is_needed
    io = StringIO.new("test")
    io.extend(MultiXml::FileLike)

    result = io.content_type

    refute_nil result
    assert_kind_of String, result
  end
end
