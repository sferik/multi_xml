require "test_helper"

# Tests DateTime parsing fallback behavior
class DateTimeFallbackTest < Minitest::Test
  cover "MultiXml*"

  def test_parse_datetime_falls_back_to_datetime_for_iso_week_format
    converter = MultiXml::PARSE_DATETIME
    result = converter.call("2020-W01")

    assert_kind_of Time, result
    assert_equal Time.utc(2019, 12, 30), result
  end
end
