namespace :file_upload do
  desc 'Test file upload configuration features with validations'
  task test_configuration: :environment do
    puts "=== File Upload Configuration Test (with store_accessor and validations) ==="
    puts

    # Create a test assessment and section
    assessment = Assessment.create!(
      title: "Test Assessment",
      description: "Test assessment for file upload configuration"
    )

    section = AssessmentSection.create!(
      title: "Test Section",
      assessment: assessment,
      order: 1
    )

    # Create a file upload question
    file_question = AssessmentQuestions::FileUpload.create!(
      text: "Please upload a file",
      assessment: assessment,
      assessment_section: section,
      order: 1
    )

    puts "1. Default Configuration (after_initialize callback)"
    puts "   Allowed data types: #{file_question.allowed_data_types}"
    puts "   Max file size: #{file_question.max_file_size_human}"
    puts "   Allowed extensions: #{file_question.allowed_extensions}"
    puts "   Is valid: #{file_question.valid?}"
    puts

    puts "2. Testing Validation - Valid Configuration"
    file_question.allowed_data_types = ['image/jpeg', 'image/png']
    file_question.max_file_size = 5.megabytes
    puts "   Setting: allowed_data_types = ['image/jpeg', 'image/png'], max_file_size = 5MB"
    puts "   Is valid: #{file_question.valid?}"
    puts "   Errors: #{file_question.errors.full_messages}" unless file_question.valid?
    file_question.save!
    puts "   Saved successfully"
    puts

    puts "3. Testing Validation - Invalid allowed_data_types (empty array)"
    file_question.allowed_data_types = []
    puts "   Setting: allowed_data_types = []"
    puts "   Is valid: #{file_question.valid?}"
    puts "   Errors: #{file_question.errors.full_messages.join(', ')}" unless file_question.valid?
    puts

    puts "4. Testing Validation - Invalid allowed_data_types (invalid MIME type)"
    file_question.allowed_data_types = ['invalid-type', 'image/jpeg']
    puts "   Setting: allowed_data_types = ['invalid-type', 'image/jpeg']"
    puts "   Is valid: #{file_question.valid?}"
    puts "   Errors: #{file_question.errors.full_messages.join(', ')}" unless file_question.valid?
    puts

    puts "5. Testing Validation - Invalid max_file_size (too small)"
    file_question.allowed_data_types = ['image/jpeg']
    file_question.max_file_size = 500 # 500 bytes, less than 1KB
    puts "   Setting: max_file_size = 500 bytes"
    puts "   Is valid: #{file_question.valid?}"
    puts "   Errors: #{file_question.errors.full_messages.join(', ')}" unless file_question.valid?
    puts

    puts "6. Testing Validation - Invalid max_file_size (too large)"
    file_question.max_file_size = 200.megabytes
    puts "   Setting: max_file_size = 200MB"
    puts "   Is valid: #{file_question.valid?}"
    puts "   Errors: #{file_question.errors.full_messages.join(', ')}" unless file_question.valid?
    puts

    puts "7. Testing Validation - Invalid max_file_size (negative)"
    file_question.max_file_size = -1
    puts "   Setting: max_file_size = -1"
    puts "   Is valid: #{file_question.valid?}"
    puts "   Errors: #{file_question.errors.full_messages.join(', ')}" unless file_question.valid?
    puts

    # Reset to valid configuration
    file_question.allowed_data_types = ['image/jpeg', 'application/pdf']
    file_question.max_file_size = 2.megabytes
    file_question.save!

    puts "8. Testing Setter Type Coercion"
    puts "   Before: allowed_data_types = #{file_question.allowed_data_types}"
    file_question.allowed_data_types = 'image/png'  # String instead of Array
    puts "   After setting string: allowed_data_types = #{file_question.allowed_data_types}"
    puts "   Is valid: #{file_question.valid?}"
    puts

    puts "9. Testing File Validation (Mock Files)"
    puts

    # Mock file class for testing
    class MockFile
      attr_accessor :content_type, :size

      def initialize(content_type, size)
        @content_type = content_type
        @size = size
      end

      def blank?
        false
      end
    end

    # Test valid file
    valid_file = MockFile.new('image/jpeg', 1.megabyte)
    puts "   Valid JPEG file (1MB):"
    puts "   - Type valid: #{file_question.validate_file_type(valid_file)}"
    puts "   - Size valid: #{file_question.validate_file_size(valid_file)}"
    validation_errors = file_question.validate_uploaded_file(valid_file)
    puts "   - Validation errors: #{validation_errors.empty? ? 'None' : validation_errors.join(', ')}"
    puts

    # Test invalid file type
    invalid_type_file = MockFile.new('text/plain', 500.kilobytes)
    puts "   Invalid file type (text/plain, 500KB):"
    puts "   - Type valid: #{file_question.validate_file_type(invalid_type_file)}"
    puts "   - Size valid: #{file_question.validate_file_size(invalid_type_file)}"
    validation_errors = file_question.validate_uploaded_file(invalid_type_file)
    puts "   - Validation errors: #{validation_errors.empty? ? 'None' : validation_errors.join(', ')}"
    puts

    # Test invalid file size
    invalid_size_file = MockFile.new('image/jpeg', 5.megabytes)
    puts "   Invalid file size (JPEG, 5MB):"
    puts "   - Type valid: #{file_question.validate_file_type(invalid_size_file)}"
    puts "   - Size valid: #{file_question.validate_file_size(invalid_size_file)}"
    validation_errors = file_question.validate_uploaded_file(invalid_size_file)
    puts "   - Validation errors: #{validation_errors.empty? ? 'None' : validation_errors.join(', ')}"
    puts

    puts "10. Testing Configuration Presets"
    puts "    Configuring for images only..."
    file_question.configure_for_images_only
    puts "    Allowed data types: #{file_question.allowed_data_types}"
    puts "    Max file size: #{file_question.max_file_size_human}"
    puts "    Is valid: #{file_question.valid?}"
    puts

    puts "    Configuring for documents only..."
    file_question.configure_for_documents_only
    puts "    Allowed data types: #{file_question.allowed_data_types}"
    puts "    Max file size: #{file_question.max_file_size_human}"
    puts "    Is valid: #{file_question.valid?}"
    puts

    puts "11. Store Accessor Data Storage"
    puts "    Current meta_data: #{file_question.meta_data}"
    puts "    Direct access to allowed_data_types: #{file_question.allowed_data_types}"
    puts "    Direct access to max_file_size: #{file_question.max_file_size}"
    puts

    puts "12. Testing Model Creation with Invalid Data"
    puts "    Attempting to create with invalid data..."
    begin
      invalid_question = AssessmentQuestions::FileUpload.create!(
        text: "Invalid file upload question",
        assessment: assessment,
        assessment_section: section,
        order: 2,
        allowed_data_types: [],  # Invalid: empty array
        max_file_size: -1        # Invalid: negative size
      )
      puts "    ERROR: Should have failed validation!"
    rescue ActiveRecord::RecordInvalid => e
      puts "    Successfully caught validation error: #{e.message}"
    end
    puts

    puts "=== Test Complete ==="

    # Clean up
    assessment.destroy if assessment.persisted?
  end

  desc 'Test file upload validations separately'
  task test_validations: :environment do
    puts "=== File Upload Validations Test ==="
    puts

    # Create a test assessment and section
    assessment = Assessment.create!(
      title: "Test Assessment",
      description: "Test assessment for file upload validation"
    )

    section = AssessmentSection.create!(
      title: "Test Section",
      assessment: assessment,
      order: 1
    )

    puts "1. Testing presence validations"
    file_question = AssessmentQuestions::FileUpload.new(
      text: "Test file upload",
      assessment: assessment,
      assessment_section: section,
      order: 1
    )

    # Test with nil values
    file_question.allowed_data_types = nil
    file_question.max_file_size = nil
    puts "   With nil values - Valid: #{file_question.valid?}"
    puts "   Errors: #{file_question.errors.full_messages.join(', ')}" unless file_question.valid?
    puts

    puts "2. Testing MIME type format validation"
    validation_test_cases = [
      { types: ['image/jpeg', 'text/plain'], expected: true, desc: "Valid MIME types" },
      { types: ['invalid-type'], expected: false, desc: "Invalid MIME type (no slash)" },
      { types: ['image/jpeg', 'invalid'], expected: false, desc: "Mixed valid and invalid" },
      { types: [''], expected: false, desc: "Empty string" },
      { types: [nil], expected: false, desc: "Nil value in array" }
    ]

    validation_test_cases.each do |test_case|
      file_question.allowed_data_types = test_case[:types]
      file_question.max_file_size = 5.megabytes
      is_valid = file_question.valid?
      puts "   #{test_case[:desc]}: #{is_valid == test_case[:expected] ? 'PASS' : 'FAIL'}"
      puts "     Input: #{test_case[:types]}"
      puts "     Expected: #{test_case[:expected]}, Got: #{is_valid}"
      puts "     Errors: #{file_question.errors.full_messages.join(', ')}" unless is_valid
      puts
    end

    puts "3. Testing file size validation"
    size_test_cases = [
      { size: 1.kilobyte, expected: true, desc: "1KB (minimum valid)" },
      { size: 5.megabytes, expected: true, desc: "5MB (normal size)" },
      { size: 100.megabytes, expected: true, desc: "100MB (maximum valid)" },
      { size: 500, expected: false, desc: "500 bytes (too small)" },
      { size: 200.megabytes, expected: false, desc: "200MB (too large)" },
      { size: -1, expected: false, desc: "Negative size" },
      { size: 0, expected: false, desc: "Zero size" }
    ]

    size_test_cases.each do |test_case|
      file_question.allowed_data_types = ['image/jpeg']
      file_question.max_file_size = test_case[:size]
      is_valid = file_question.valid?
      puts "   #{test_case[:desc]}: #{is_valid == test_case[:expected] ? 'PASS' : 'FAIL'}"
      puts "     Input: #{test_case[:size]}"
      puts "     Expected: #{test_case[:expected]}, Got: #{is_valid}"
      puts "     Errors: #{file_question.errors.full_messages.join(', ')}" unless is_valid
      puts
    end

    puts "=== Validation Test Complete ==="

    # Clean up
    assessment.destroy if assessment.persisted?
  end

  desc 'Show file upload usage examples'
  task usage_examples: :environment do
    puts "=== File Upload Configuration Usage Examples ==="
    puts

    puts "1. Basic Configuration with store_accessor:"
    puts "   file_question = AssessmentQuestions::FileUpload.create!(...)"
    puts "   file_question.allowed_data_types = ['image/jpeg', 'image/png']"
    puts "   file_question.max_file_size = 5.megabytes"
    puts "   file_question.save!"
    puts

    puts "2. Using Presets:"
    puts "   file_question.configure_for_images_only    # Images only, 5MB max"
    puts "   file_question.configure_for_documents_only # Documents only, 20MB max"
    puts "   file_question.configure_for_all_types      # All types, 10MB max"
    puts

    puts "3. Validation Examples:"
    puts "   file_question.valid?                       # Check if configuration is valid"
    puts "   file_question.errors.full_messages         # Get validation errors"
    puts

    puts "4. File Upload Validation in Controllers:"
    puts "   if uploaded_file.present?"
    puts "     errors = file_question.validate_uploaded_file(uploaded_file)"
    puts "     if errors.any?"
    puts "       flash[:error] = errors.join(', ')"
    puts "       redirect_back(fallback_location: root_path)"
    puts "       return"
    puts "     end"
    puts "   end"
    puts

    puts "5. Display Information:"
    puts "   Max file size: #{AssessmentQuestions::FileUpload.new.max_file_size_human}"
    puts "   Allowed extensions: #{AssessmentQuestions::FileUpload.new.allowed_extensions}"
    puts

    puts "6. Available File Types:"
    AssessmentQuestions::FileUpload.common_file_types.each do |category, types|
      puts "   #{category.capitalize}: #{types.join(', ')}"
    end
    puts

    puts "7. Store Accessor Benefits:"
    puts "   - Direct attribute access (no manual JSON parsing)"
    puts "   - Built-in validations"
    puts "   - Type coercion in setters"
    puts "   - Seamless integration with Rails forms"
    puts
  end
end
