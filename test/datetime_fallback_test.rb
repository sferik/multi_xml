require "test_helper"

# Tests DateTime parsing fallback behavior
class DateTimeFallbackTest < Minitest::Test
  cover "MultiXML*"

  def test_parse_datetime_falls_back_to_datetime_for_iso_week_format
    converter = MultiXML::PARSE_DATETIME
    result = converter.call("2020-W01")

    assert_kind_of Time, result
    assert_equal Time.utc(2019, 12, 30), result
  end

  def test_parse_datetime_falls_back_to_iso_week_when_datetime_parse_breaks
    converter = MultiXML::PARSE_DATETIME

    DateTime.stub(:parse, ->(*) { raise NoMethodError, "jruby date bug" }) do
      result = converter.call("2020-W01")

      assert_kind_of Time, result
      assert_equal Time.utc(2019, 12, 30), result
    end
  end

  def test_parse_datetime_falls_back_to_datetime_parse_when_time_parse_fails
    converter = MultiXML::PARSE_DATETIME
    datetime = DateTime.new(2020, 1, 2, 3, 4, 5, "+00:00")

    Time.stub(:parse, ->(*) { raise ArgumentError, "time parse failed" }) do
      DateTime.stub(:parse, ->(*) { datetime }) do
        assert_equal Time.utc(2020, 1, 2, 3, 4, 5), converter.call("2020-01-02T03:04:05Z")
      end
    end
  end

  def test_parse_datetime_falls_back_to_iso_week_with_explicit_day
    converter = MultiXML::PARSE_DATETIME

    DateTime.stub(:parse, ->(*) { raise NoMethodError, "jruby date bug" }) do
      assert_equal Time.utc(2019, 12, 31), converter.call("2020-W01-2")
    end
  end

  def test_parse_datetime_raises_argument_error_for_invalid_iso_week_fallback
    converter = MultiXML::PARSE_DATETIME

    DateTime.stub(:parse, ->(*) { raise NoMethodError, "jruby date bug" }) do
      error = assert_raises(ArgumentError) { converter.call("not-a-date") }

      assert_equal "invalid date", error.message
    end
  end

  def test_parse_iso_week_datetime_raises_argument_error_with_message_for_invalid_input
    error = assert_raises(ArgumentError) { MultiXML.send(:parse_iso_week_datetime, "not-a-date") }

    assert_equal "invalid date", error.message
  end
end
