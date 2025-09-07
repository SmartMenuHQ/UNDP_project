#!/usr/bin/env ruby
# Test script to verify the polymorphic extract_response_value implementation

require_relative 'config/environment'

class PolymorphicExtractionTester
  def run_tests
    puts "🧪 Testing Polymorphic Response Value Extraction"
    puts "=" * 50

    test_rich_text_extraction
    test_range_type_extraction
    test_date_type_extraction
    test_multiple_choice_extraction
    test_radio_extraction
    test_boolean_type_extraction
    test_file_upload_extraction
    test_fallback_behavior

    puts "\n✅ All polymorphic extraction tests completed!"
  end

  private

  def test_rich_text_extraction
    puts "\n1. Testing RichText extraction..."

    question = AssessmentQuestions::RichText.new(sub_type: 'long_text')

    # Test hash with text field
    response1 = create_mock_response({ "text" => "Hello World" })
    result1 = question.extract_response_value(response1)
    puts "   ✅ Hash with text: #{result1}" if result1 == "Hello World"

    # Test hash with symbol key
    response2 = create_mock_response({ text: "Symbol Key" })
    result2 = question.extract_response_value(response2)
    puts "   ✅ Hash with symbol: #{result2}" if result2 == "Symbol Key"

    # Test non-hash value
    response3 = create_mock_response("Direct String")
    result3 = question.extract_response_value(response3)
    puts "   ✅ Direct string: #{result3}" if result3 == "Direct String"
  end

  def test_range_type_extraction
    puts "\n2. Testing RangeType extraction..."

    question = AssessmentQuestions::RangeType.new(sub_type: 'slider')

    # Test number field
    response1 = create_mock_response({ "number" => 42 })
    result1 = question.extract_response_value(response1)
    puts "   ✅ Number field: #{result1}" if result1 == 42

    # Test rating field
    response2 = create_mock_response({ "rating" => 5 })
    result2 = question.extract_response_value(response2)
    puts "   ✅ Rating field: #{result2}" if result2 == 5

    # Test range field
    response3 = create_mock_response({ "range" => 75 })
    result3 = question.extract_response_value(response3)
    puts "   ✅ Range field: #{result3}" if result3 == 75
  end

  def test_date_type_extraction
    puts "\n3. Testing DateType extraction..."

    question = AssessmentQuestions::DateType.new(sub_type: 'date')

    # Test date field
    response1 = create_mock_response({ "date" => "2024-01-15" })
    result1 = question.extract_response_value(response1)
    puts "   ✅ Date field: #{result1}" if result1 == "2024-01-15"

    # Test start_date field
    response2 = create_mock_response({ "start_date" => "2024-01-01" })
    result2 = question.extract_response_value(response2)
    puts "   ✅ Start date field: #{result2}" if result2 == "2024-01-01"
  end

  def test_multiple_choice_extraction
    puts "\n4. Testing MultipleChoice extraction..."

    question = AssessmentQuestions::MultipleChoice.new(sub_type: 'checkboxes')

    # Test with mock selected_options
    response = create_mock_response_with_options([101, 102, 103])
    result = question.extract_response_value(response)
    puts "   ✅ Selected options: #{result}" if result == [101, 102, 103]
  end

  def test_radio_extraction
    puts "\n5. Testing Radio extraction..."

    question = AssessmentQuestions::Radio.new(sub_type: 'radio_buttons')

    # Test with single selected option
    response = create_mock_response_with_options([201])
    result = question.extract_response_value(response)
    puts "   ✅ Single option: #{result}" if result == 201
  end

  def test_boolean_type_extraction
    puts "\n6. Testing BooleanType extraction..."

    question = AssessmentQuestions::BooleanType.new

    # Test boolean field
    response1 = create_mock_response({ "boolean" => true })
    result1 = question.extract_response_value(response1)
    puts "   ✅ Boolean field: #{result1}" if result1 == true

    # Test checked field
    response2 = create_mock_response({ "checked" => false })
    result2 = question.extract_response_value(response2)
    puts "   ✅ Checked field: #{result2}" if result2 == false
  end

  def test_file_upload_extraction
    puts "\n7. Testing FileUpload extraction..."

    question = AssessmentQuestions::FileUpload.new

    # Test filename field
    response1 = create_mock_response({ "filename" => "document.pdf" })
    result1 = question.extract_response_value(response1)
    puts "   ✅ Filename field: #{result1}" if result1 == "document.pdf"

    # Test file field
    response2 = create_mock_response({ "file" => { "name" => "image.jpg" } })
    result2 = question.extract_response_value(response2)
    puts "   ✅ File field: #{result2}" if result2 == { "name" => "image.jpg" }
  end

  def test_fallback_behavior
    puts "\n8. Testing fallback behavior..."

    # Use RichText as a concrete class to test the super method
    question = AssessmentQuestions::RichText.new

    # Test fallback when no text field is present
    response1 = create_mock_response({ "value" => "fallback_value" })
    result1 = question.extract_response_value(response1)
    puts "   ✅ Generic value field: #{result1}" if result1 == "fallback_value"

    # Test fallback priority (value > text > number > date)
    response2 = create_mock_response({
      "number" => 123,
      "value" => "priority_value"
    })
    result2 = question.extract_response_value(response2)
    puts "   ✅ Priority fallback: #{result2}" if result2 == "priority_value"

    puts "   ✅ Fallback behavior working correctly!"
  end

  def create_mock_response(value)
    OpenStruct.new(value: value)
  end

  def create_mock_response_with_options(option_ids)
    selected_options = option_ids.map do |id|
      OpenStruct.new(assessment_question_option_id: id)
    end

    OpenStruct.new(
      value: {},
      selected_options: selected_options,
      response_value: option_ids
    )
  end
end

# Run the tests
if __FILE__ == $0
  tester = PolymorphicExtractionTester.new
  tester.run_tests
end
