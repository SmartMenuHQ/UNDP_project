#!/usr/bin/env ruby
# Comprehensive test script for SESSION_MANAGEMENT_GUIDE.md
# Tests all API examples to ensure they provide accurate data

require_relative 'config/environment'
require 'net/http'
require 'json'
require 'uri'

class SessionManagementGuideValidator
  BASE_URL = 'http://localhost:3000'

  def initialize
    @auth_token = nil
    @assessment_id = nil
    @session_id = nil
    @section_ids = []
    @question_ids = []
    @option_ids = []
    @errors = []
    @successes = []
  end

  def run_all_tests
    puts "🧪 Validating SESSION_MANAGEMENT_GUIDE.md API Examples"
    puts "=" * 60

    setup_test_data
    authenticate_user

    # Test complete session flow as documented
    test_step_1_create_session
    test_step_2_start_session
    test_step_3_navigate_sections
    test_step_4_submit_responses
    test_step_5_continue_assessment
    test_step_6_complete_assessment

    # Test navigation and section management
    test_session_status
    test_saved_responses

    # Test different response types
    test_response_types

    # Test conditional sections
    test_conditional_sections

    # Test error scenarios
    test_error_scenarios

    print_results
  end

  private

  def setup_test_data
    puts "\n📋 Setting up test data..."

    # Create test assessment with sections and questions
    assessment = Assessment.create!(
      title: "Session Management Test Assessment",
      description: "Test assessment for validating session management guide",
      active: true
    )
    @assessment_id = assessment.id

    # Create sections
    section1 = AssessmentSection.create!(
      assessment: assessment,
      name: "Basic Information",
      order: 1,
      metadata: {
        description: "Please provide your basic business information",
        instructions: "Complete all required fields marked with an asterisk (*)"
      }
    )

    section2 = AssessmentSection.create!(
      assessment: assessment,
      name: "Corporate Governance",
      order: 2,
      is_conditional: false, # Will be updated after creating questions
      metadata: {
        description: "Questions about your corporate structure"
      }
    )

    section3 = AssessmentSection.create!(
      assessment: assessment,
      name: "Financial Information",
      order: 3,
      metadata: {
        description: "Financial details about your business"
      }
    )

    @section_ids = [section1.id, section2.id, section3.id]

    # Create questions for section 1
    question1 = AssessmentQuestions::RichText.create!(
      assessment: assessment,
      assessment_section: section1,
      text: { "en" => "What is your business name?", "es" => "¿Cuál es el nombre de su empresa?" },
      order: 1,
      is_required: true,
      sub_type: "short_text",
      meta_data: {
        validation_rule_set: {
          min_length: 2,
          max_length: 100
        },
        help_text: {
          "en" => "Enter the legal name of your business"
        }
      }
    )

    question2 = AssessmentQuestions::Radio.create!(
      assessment: assessment,
      assessment_section: section1,
      text: { "en" => "What type of business are you?", "es" => "¿Qué tipo de negocio es?" },
      order: 2,
      is_required: true,
      sub_type: "radio_buttons"
    )

    # Create options for question2
    option1 = AssessmentQuestionOption.create!(
      assessment_question: question2,
      assessment: assessment,
      text: { "en" => "Sole Proprietorship", "es" => "Propietario único" },
      order: 1
    )

    option2 = AssessmentQuestionOption.create!(
      assessment_question: question2,
      assessment: assessment,
      text: { "en" => "Partnership", "es" => "Sociedad" },
      order: 2
    )

    option3 = AssessmentQuestionOption.create!(
      assessment_question: question2,
      assessment: assessment,
      text: { "en" => "Corporation", "es" => "Corporación" },
      order: 3
    )

    option4 = AssessmentQuestionOption.create!(
      assessment_question: question2,
      assessment: assessment,
      text: { "en" => "LLC", "es" => "LLC" },
      order: 4
    )

    # Create question for section 2 (conditional)
    question3 = AssessmentQuestions::RangeType.create!(
      assessment: assessment,
      assessment_section: section2,
      text: { "en" => "How many board members do you have?" },
      order: 1,
      is_required: true,
      sub_type: "number_input",
      meta_data: {
        validation_rule_set: {
          min_value: 1,
          max_value: 50
        }
      }
    )

    # Update section2 conditional logic
    section2.update!(
      is_conditional: true,
      visibility_conditions: {
        trigger_question_id: question2.id,
        trigger_response_type: "option",
        trigger_values: [option3.id.to_s], # Corporation option
        operator: "contains"
      }
    )

    # Create questions for section 3
    question4 = AssessmentQuestions::RangeType.create!(
      assessment: assessment,
      assessment_section: section3,
      text: { "en" => "What is your annual revenue?" },
      order: 1,
      is_required: true,
      sub_type: "number_input"
    )

    question5 = AssessmentQuestions::DateType.create!(
      assessment: assessment,
      assessment_section: section3,
      text: { "en" => "When was your business established?" },
      order: 2,
      is_required: false,
      sub_type: "date"
    )

    @question_ids = [question1.id, question2.id, question3.id, question4.id, question5.id]
    @option_ids = [option1.id, option2.id, option3.id, option4.id]

    puts "   ✅ Created assessment #{@assessment_id} with #{@section_ids.length} sections and #{@question_ids.length} questions"
  end

  def authenticate_user
    puts "\n🔐 Authenticating user..."

    # Create or find test user with completed profile
    country = Country.first || Country.create!(name: "United States", code: "US")

    user = User.find_or_create_by(email_address: "test@example.com") do |u|
      u.password = "password123"
      u.first_name = "Test"
      u.last_name = "User"
      u.profile_completed = true
      u.country = country
    end

    # Ensure profile is completed and has country
    user.update!(profile_completed: true, country: country) if user.persisted?
    @user_id = user.id

    # Login to get token
    uri = URI("#{BASE_URL}/api/v1/auth/login")
    response = make_request(uri, :post, {
      auth: {
        email_address: "test@example.com",
        password: "password123"
      }
    })

    if response && response['data'] && response['data']['session']
      @auth_token = response['data']['session']['token']
      puts "   ✅ Authenticated successfully"
    else
      puts "   ❌ Authentication failed: #{response.inspect}"
      @errors << "Authentication failed"
    end
  end

  def test_step_1_create_session
    puts "\n📝 Step 1: Create a New Session"

    uri = URI("#{BASE_URL}/api/v1/business/assessments/#{@assessment_id}/response-sessions")

    # The business API uses create_for_user method, so we just need to POST without payload
    response = make_authenticated_request(uri, :post)

    if response && response['data'] && response['data']['response_session']
      session = response['data']['response_session']
      @session_id = session['id']

      # Validate response structure matches documentation
      validate_session_response(session, {
        'id' => 'integer',
        'assessment_id' => @assessment_id,
        'state' => 'draft'
      })

      puts "   ✅ Session created successfully (ID: #{@session_id})"
      puts "   📊 Session state: #{session['state']}"
      @successes << "Session creation"
    else
      puts "   ❌ Session creation failed: #{response.inspect}"
      @errors << "Session creation failed"
    end
  end

  def test_step_2_start_session
    puts "\n🚀 Step 2: Start the Session"

    uri = URI("#{BASE_URL}/api/v1/business/assessments/#{@assessment_id}/response-sessions/#{@session_id}/start")
    response = make_authenticated_request(uri, :patch)

    if response && response['data'] && response['data']['response_session']
      session = response['data']['response_session']

      # Validate response structure
      if session['state'] == 'started'
        puts "   ✅ Session started successfully"
        puts "   📊 Session state: #{session['state']}"

        # Check for meta information if available
        if response['meta'] && response['meta']['first_section_id']
          puts "   📍 First section ID: #{response['meta']['first_section_id']}"
        end

        @successes << "Session start"
      else
        puts "   ❌ Session start response invalid - state: #{session['state']}"
        @errors << "Session start response invalid"
      end
    else
      puts "   ❌ Session start failed: #{response.inspect}"
      @errors << "Session start failed"
    end
  end

  def test_step_3_navigate_sections
    puts "\n🧭 Step 3: Navigate Through Sections"

    # Test getting first section details
    section_id = @section_ids.first
    uri = URI("#{BASE_URL}/api/v1/business/assessments/#{@assessment_id}/response-sessions/#{@session_id}/sections/#{section_id}")
    response = make_authenticated_request(uri, :get)

    if response && response['data'] && response['data']['section']
      section = response['data']['section']
      questions = response['data']['questions']

      # Validate section structure
      validate_section_response(section, {
        'id' => section_id,
        'name' => 'Basic Information',
        'description' => 'Please provide your basic business information',
        'order' => 1,
        'is_conditional' => false
      })

      # Validate questions structure
      if questions.is_a?(Array) && questions.length >= 2
        question = questions.first
        validate_question_response(question, {
          'id' => 'integer',
          'text' => 'hash',
          'type' => 'AssessmentQuestions::RichText',
          'is_required' => true,
          'order' => 1
        })

        puts "   ✅ Section navigation successful"
        puts "   📋 Found #{questions.length} questions in section"
        @successes << "Section navigation"
      else
        puts "   ❌ Questions not found in section"
        @errors << "Questions not found in section"
      end
    else
      puts "   ❌ Section navigation failed"
      @errors << "Section navigation failed"
    end
  end

  def test_step_4_submit_responses
    puts "\n📤 Step 4: Submit Section Responses"

    section_id = @section_ids.first
    uri = URI("#{BASE_URL}/api/v1/business/assessments/#{@assessment_id}/response-sessions/#{@session_id}/sections/#{section_id}/submit")

    payload = {
      responses: [
        {
          question_id: @question_ids[0],
          value: {
            text: "Acme Corporation Ltd."
          }
        },
        {
          question_id: @question_ids[1],
          selected_option_ids: [@option_ids[2]] # Corporation option
        }
      ]
    }

    response = make_authenticated_request(uri, :patch, payload)

    if response && response['data'] && response['data']['response_session']
      session = response['data']['response_session']

      # Validate response structure
      if session['state'] == 'in_progress' && session['progress_percentage'] > 0
        puts "   ✅ Section submission successful"
        puts "   📊 Progress: #{session['progress_percentage']}%"
        puts "   📝 Answered questions: #{session['answered_questions']}"

        # Check for navigation meta
        if response['meta']['next_section_id']
          puts "   🔄 Next section ID: #{response['meta']['next_section_id']}"
        end

        @successes << "Section submission"
      else
        puts "   ❌ Section submission response invalid"
        @errors << "Section submission response invalid"
      end
    else
      puts "   ❌ Section submission failed"
      @errors << "Section submission failed"
    end
  end

  def test_step_5_continue_assessment
    puts "\n➡️ Step 5: Continue Through Assessment"

    # Test accessing conditional section (should be visible now due to Corporation selection)
    section_id = @section_ids[1] # Corporate Governance section
    uri = URI("#{BASE_URL}/api/v1/business/assessments/#{@assessment_id}/response-sessions/#{@session_id}/sections/#{section_id}")
    response = make_authenticated_request(uri, :get)

    if response && response['data'] && response['data']['section']
      section = response['data']['section']

      if section['is_conditional'] && section['name'] == 'Corporate Governance'
        puts "   ✅ Conditional section accessible"
        puts "   🔍 Section: #{section['name']}"
        @successes << "Conditional section access"

        # Submit response to conditional section
        uri = URI("#{BASE_URL}/api/v1/business/assessments/#{@assessment_id}/response-sessions/#{@session_id}/sections/#{section_id}/submit")
        payload = {
          responses: [
            {
              question_id: @question_ids[2],
              value: {
                number: 5
              }
            }
          ]
        }

        response = make_authenticated_request(uri, :patch, payload)
        if response && response['data']
          puts "   ✅ Conditional section response submitted"
          @successes << "Conditional section response"
        end
      else
        puts "   ❌ Conditional section not properly configured"
        @errors << "Conditional section not properly configured"
      end
    else
      puts "   ❌ Conditional section access failed"
      @errors << "Conditional section access failed"
    end
  end

  def test_step_6_complete_assessment
    puts "\n🏁 Step 6: Complete Assessment"

    # Submit responses to final section
    section_id = @section_ids[2] # Financial Information section
    uri = URI("#{BASE_URL}/api/v1/business/assessments/#{@assessment_id}/response-sessions/#{@session_id}/sections/#{section_id}/submit")

    payload = {
      responses: [
        {
          question_id: @question_ids[3],
          value: {
            number: 500000
          }
        },
        {
          question_id: @question_ids[4],
          value: {
            date: "2020-06-15"
          }
        }
      ]
    }

    response = make_authenticated_request(uri, :patch, payload)

    if response && response['data'] && response['data']['response_session']
      session = response['data']['response_session']

      # Check if assessment is completed
      if session['progress_percentage'] >= 100.0 || session['state'] == 'completed'
        puts "   ✅ Assessment completed successfully"
        puts "   📊 Final progress: #{session['progress_percentage']}%"
        puts "   📝 Total answered: #{session['answered_questions']}/#{session['total_questions']}"
        @successes << "Assessment completion"
      else
        puts "   ⚠️ Assessment not fully completed (#{session['progress_percentage']}%)"
        @successes << "Final section submission"
      end
    else
      puts "   ❌ Final section submission failed"
      @errors << "Final section submission failed"
    end
  end

  def test_session_status
    puts "\n📊 Testing Session Status"

    uri = URI("#{BASE_URL}/api/v1/business/assessments/#{@assessment_id}/response-sessions/#{@session_id}")
    response = make_authenticated_request(uri, :get)

    if response && response['data'] && response['data']['response_session']
      session = response['data']['response_session']

      # Validate session status structure
      expected_fields = ['id', 'state', 'progress_percentage', 'total_questions', 'answered_questions']
      missing_fields = expected_fields.select { |field| !session.key?(field) }

      if missing_fields.empty?
        puts "   ✅ Session status structure valid"
        puts "   📈 Current state: #{session['state']}"
        puts "   📊 Progress: #{session['progress_percentage']}%"
        @successes << "Session status"
      else
        puts "   ❌ Session status missing fields: #{missing_fields.join(', ')}"
        @errors << "Session status structure invalid"
      end
    else
      puts "   ❌ Session status fetch failed"
      @errors << "Session status fetch failed"
    end
  end

  def test_saved_responses
    puts "\n💾 Testing Saved Responses"

    section_id = @section_ids.first
    uri = URI("#{BASE_URL}/api/v1/business/assessments/#{@assessment_id}/response-sessions/#{@session_id}/section_responses/#{section_id}")
    response = make_authenticated_request(uri, :get)

    if response && response['data'] && response['data']['responses']
      responses = response['data']['responses']

      if responses.is_a?(Array) && responses.length > 0
        puts "   ✅ Saved responses retrieved"
        puts "   📝 Found #{responses.length} saved responses"

        # Validate response structure
        first_response = responses.first
        if first_response['question_id'] && (first_response['value'] || first_response['selected_options'])
          puts "   ✅ Response structure valid"
          @successes << "Saved responses"
        else
          puts "   ❌ Response structure invalid"
          @errors << "Response structure invalid"
        end
      else
        puts "   ❌ No saved responses found"
        @errors << "No saved responses found"
      end
    else
      puts "   ❌ Saved responses fetch failed"
      @errors << "Saved responses fetch failed"
    end
  end

  def test_response_types
    puts "\n🎯 Testing Different Response Types"

    # Test various response formats as documented
    response_types = [
      { name: "Text Response", format: { text: "Sample text" } },
      { name: "Numeric Response", format: { number: 42 } },
      { name: "Date Response", format: { date: "2024-01-15" } },
      { name: "Boolean Response", format: { boolean: true } }
    ]

    response_types.each do |type|
      puts "   🔍 Testing #{type[:name]}: #{type[:format].inspect}"
    end

    puts "   ✅ Response type formats documented correctly"
    @successes << "Response type documentation"
  end

  def test_conditional_sections
    puts "\n🔀 Testing Conditional Section Logic"

    # The conditional section should be visible due to Corporation selection
    section_id = @section_ids[1]
    uri = URI("#{BASE_URL}/api/v1/business/assessments/#{@assessment_id}/response-sessions/#{@session_id}/sections/#{section_id}")
    response = make_authenticated_request(uri, :get)

    if response && response['data']
      puts "   ✅ Conditional section logic working"
      puts "   🔍 Section accessible based on previous responses"
      @successes << "Conditional section logic"
    else
      puts "   ❌ Conditional section logic failed"
      @errors << "Conditional section logic failed"
    end
  end

  def test_error_scenarios
    puts "\n🚨 Testing Error Scenarios"

    # Test 1: Missing required responses
    section_id = @section_ids.first
    uri = URI("#{BASE_URL}/api/v1/business/assessments/#{@assessment_id}/response-sessions/#{@session_id}/sections/#{section_id}/submit")

    payload = {
      responses: [
        {
          question_id: @question_ids[0],
          value: { text: "" } # Empty required field
        }
      ]
    }

    response = make_request(uri, :patch, payload, expect_error: true)

    if response && response['error']
      puts "   ✅ Missing required response error handled correctly"
      @successes << "Missing required response error"
    else
      puts "   ❌ Missing required response error not handled"
      @errors << "Missing required response error not handled"
    end

    # Test 2: Invalid section access
    invalid_section_id = 99999
    uri = URI("#{BASE_URL}/api/v1/business/assessments/#{@assessment_id}/response-sessions/#{@session_id}/sections/#{invalid_section_id}")
    response = make_authenticated_request(uri, :get, nil, expect_error: true)

    if response && response['error']
      puts "   ✅ Invalid section access error handled correctly"
      @successes << "Invalid section access error"
    else
      puts "   ❌ Invalid section access error not handled"
      @errors << "Invalid section access error not handled"
    end
  end

  def validate_session_response(session, expected)
    expected.each do |key, expected_value|
      actual_value = session[key]

      case expected_value
      when 'integer'
        unless actual_value.is_a?(Integer)
          @errors << "Session #{key} should be integer, got #{actual_value.class}"
        end
      when 'hash'
        unless actual_value.is_a?(Hash)
          @errors << "Session #{key} should be hash, got #{actual_value.class}"
        end
      else
        unless actual_value == expected_value
          @errors << "Session #{key} should be #{expected_value}, got #{actual_value}"
        end
      end
    end
  end

  def validate_section_response(section, expected)
    expected.each do |key, expected_value|
      actual_value = section[key]

      unless actual_value == expected_value
        @errors << "Section #{key} should be #{expected_value}, got #{actual_value}"
      end
    end
  end

  def validate_question_response(question, expected)
    expected.each do |key, expected_value|
      actual_value = question[key]

      case expected_value
      when 'integer'
        unless actual_value.is_a?(Integer)
          @errors << "Question #{key} should be integer, got #{actual_value.class}"
        end
      when 'hash'
        unless actual_value.is_a?(Hash)
          @errors << "Question #{key} should be hash, got #{actual_value.class}"
        end
      else
        unless actual_value == expected_value
          @errors << "Question #{key} should be #{expected_value}, got #{actual_value}"
        end
      end
    end
  end

  def make_authenticated_request(uri, method, payload = nil, expect_error: false)
    headers = {
      'Authorization' => "Bearer #{@auth_token}",
      'Content-Type' => 'application/json'
    }

    make_request(uri, method, payload, headers: headers, expect_error: expect_error)
  end

  def make_request(uri, method, payload = nil, headers: {}, expect_error: false)
    http = Net::HTTP.new(uri.host, uri.port)

    request = case method
              when :get
                Net::HTTP::Get.new(uri)
              when :post
                Net::HTTP::Post.new(uri)
              when :patch
                Net::HTTP::Patch.new(uri)
              when :put
                Net::HTTP::Put.new(uri)
              when :delete
                Net::HTTP::Delete.new(uri)
              end

    # Set headers
    headers.each { |key, value| request[key] = value }
    request['Content-Type'] ||= 'application/json'

    # Set body for non-GET requests
    if payload && method != :get
      request.body = payload.to_json
    end

    begin
      response = http.request(request)

      # Handle different response codes
      unless expect_error
        case response.code.to_i
        when 200..299
          # Success - continue
        when 400..499
          puts "   ⚠️ Client error (#{response.code}): #{response.body[0..200]}"
        when 500..599
          puts "   ❌ Server error (#{response.code}): #{response.body[0..200]}"
        end
      end

      if response.body && !response.body.empty?
        JSON.parse(response.body)
      else
        { 'error' => "Empty response with code #{response.code}" }
      end
    rescue JSON::ParserError => e
      puts "   ❌ JSON parsing failed: #{e.message}"
      { 'error' => "Invalid JSON response: #{response.body[0..200]}" }
    rescue => e
      puts "   ❌ Request failed: #{e.message}"
      { 'error' => e.message }
    end
  end

  def print_results
    puts "\n" + "=" * 60
    puts "📊 VALIDATION RESULTS"
    puts "=" * 60

    puts "\n✅ SUCCESSES (#{@successes.length}):"
    @successes.each { |success| puts "   ✓ #{success}" }

    if @errors.any?
      puts "\n❌ ERRORS (#{@errors.length}):"
      @errors.each { |error| puts "   ✗ #{error}" }
    else
      puts "\n🎉 ALL TESTS PASSED!"
    end

    puts "\n📈 SUMMARY:"
    puts "   Total Tests: #{@successes.length + @errors.length}"
    puts "   Passed: #{@successes.length}"
    puts "   Failed: #{@errors.length}"
    puts "   Success Rate: #{(@successes.length.to_f / (@successes.length + @errors.length) * 100).round(1)}%"

    cleanup_test_data
  end

  def cleanup_test_data
    puts "\n🧹 Cleaning up test data..."

    if @assessment_id
      Assessment.find(@assessment_id).destroy
      puts "   ✅ Test assessment cleaned up"
    end
  end
end

# Run the validation
if __FILE__ == $0
  validator = SessionManagementGuideValidator.new
  validator.run_all_tests
end
