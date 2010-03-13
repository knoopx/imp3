require 'helper'

class TestNormalization < Test::Unit::TestCase
  def test_normalization
    fixtures = {
            "the fall of troy" => "fall-troy",
            "The Fall of Troy" => "fall-troy",
            "Daïtro" => "daitro",
            "té" => "te"
    }

    fixtures.each do |string, expected|
      assert_equal expected, string.normalized_without_words
    end
  end
end
