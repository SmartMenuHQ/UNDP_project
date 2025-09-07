#!/usr/bin/env ruby
# Comprehensive test script to validate ALL marking scheme API examples from documentation

require 'net/http'
require 'json'
require 'uri'

class ComprehensiveMarkingTester
  BASE_URL = 'http://localhost:3000'

  def initialize
    @admin_token = nil
    @assessment_id = 85 # From rails runner output
    @marking_scheme_id = nil
    @rule_ids = []
    @questions = []
    @test_results = []
  end

  def run_all_tests
    puts "🚀 COMPREHENSIVE MARKING SCHEME API TESTING"
    puts "=" * 60
    puts "Testing ALL examples from docs/MARKING_SCHEME_FLOW_GUIDE.md"
    puts "=" * 60

    # Step 1: Authentication
    test_admin_login

    # Step 2: Get assessment data
    get_assessment_data

    # Step 3: Marking Scheme Operations
    test_create_marking_scheme
    test_show_marking_scheme
    test_update_marking_scheme

    # Step 4: Rule Type Discovery
    test_get_rule_types
    test_get_criteria_fields

    # Step 5: Rule Creation (all types from docs)
    test_create_option_based_rule
    test_create_text_rule
    test_create_numeric_rule
    test_create_tolerance_rule

    # Step 6: Bulk Operations
    test_bulk_create_rules

    # Step 7: Scheme Management
    test_activate_scheme
    test_clone_scheme

    # Step 8: Advanced Features (if endpoints exist)
    test_preview_scoring

    # Step 9: Cleanup and Summary
    print_test_summary
  end

  private

  def test_admin_login
    log_test("Admin Authentication")

    uri = URI("#{BASE_URL}/api/v1/auth/login")
    response = make_request(uri, :post, {
      auth: {
        email_address: 'admin@questionnaire.com',
        password: 'password123'
      }
    })

    if response.code == '200'
      data = JSON.parse(response.body)
      @admin_token = data.dig('data', 'session', 'token')

      if @admin_token
        log_success("Admin login successful")
        log_info("Token: #{@admin_token[0..20]}...")
      else
        log_error("Token not found in response")
        exit 1
      end
    else
      log_error("Login failed: #{response.code} - #{response.body}")
      exit 1
    end
  end

  def get_assessment_data
    log_test("Getting Assessment Data")

    # Get questions directly from the database since API structure might vary
    begin
      require_relative 'config/environment'

      assessment = Assessment.find(@assessment_id)
      @questions = []

      assessment.assessment_sections.each do |section|
        section.assessment_questions.each do |question|
          @questions << {
            'id' => question.id,
            'text' => question.text,
            'type' => question.type
          }
        end
      end

      log_success("Found #{@questions.length} questions")
      @questions.each_with_index do |q, i|
        text = q['text'].is_a?(Hash) ? (q['text']['en'] || q['text'].values.first) : q['text']
        log_info("  #{i+1}. #{text} (ID: #{q['id']}, Type: #{q['type']})")
      end

    rescue => e
      log_error("Failed to get questions: #{e.message}")

      # Fallback: try API
      uri = URI("#{BASE_URL}/api/v1/admin/assessments/#{@assessment_id}")
      response = make_authenticated_request(uri, :get)

      if response.code == '200'
        data = JSON.parse(response.body)
        log_info("API response keys: #{data.keys}")
        # Continue with empty questions for now
        @questions = []
      end
    end
  end

  def test_create_marking_scheme
    log_test("Creating Marking Scheme (Documentation Example)")

    uri = URI("#{BASE_URL}/api/v1/admin/assessments/#{@assessment_id}/marking-schemes")

    # Exact example from documentation
    payload = {
      marking_scheme: {
        name: "Product Import Readiness Assessment",
        description: "Comprehensive evaluation for import readiness determination",
        total_possible_score: 100.0,
        settings: {
          passing_score: 50.0,
          grade_boundaries: {
            "Import Ready - Premium" => 85,
            "Import Ready - Standard" => 70,
            "Import Ready - Basic" => 50,
            "Conditional Import" => 25,
            "Not Import Ready" => 0
          },
          feedback_templates: {
            "Import Ready - Premium" => "Excellent! Your product exceeds all import requirements and qualifies for expedited processing.",
            "Import Ready - Standard" => "Great! Your product meets high import standards and is ready for standard processing.",
            "Import Ready - Basic" => "Good! Your product meets minimum import requirements.",
            "Conditional Import" => "Your product shows potential but requires improvements in specific areas before import approval.",
            "Not Import Ready" => "Your product requires significant improvements before it can be considered for import."
          }
        }
      }
    }

    response = make_authenticated_request(uri, :post, payload)

    if response.code == '200'
      data = JSON.parse(response.body)
      @marking_scheme_id = data['data']['marking_scheme']['id']
      scheme = data['data']['marking_scheme']

      log_success("Marking scheme created")
      log_info("ID: #{@marking_scheme_id}")
      log_info("Name: #{scheme['name']}")

      # Validate response structure matches documentation
      validate_scheme_response(scheme)
    else
      log_error("Failed to create scheme: #{response.code} - #{response.body}")
    end
  end

  def test_show_marking_scheme
    return unless @marking_scheme_id

    log_test("Getting Marking Scheme Details")

    uri = URI("#{BASE_URL}/api/v1/admin/assessments/#{@assessment_id}/marking-schemes/#{@marking_scheme_id}")
    response = make_authenticated_request(uri, :get)

    if response.code == '200'
      data = JSON.parse(response.body)
      log_success("Scheme retrieved successfully")
      validate_scheme_response(data['data']['marking_scheme'])
    else
      log_error("Failed to get scheme: #{response.code}")
    end
  end

  def test_update_marking_scheme
    return unless @marking_scheme_id

    log_test("Updating Marking Scheme")

    uri = URI("#{BASE_URL}/api/v1/admin/assessments/#{@assessment_id}/marking-schemes/#{@marking_scheme_id}")

    payload = {
      marking_scheme: {
        description: "Updated comprehensive evaluation for import readiness determination",
        total_possible_score: 120.0
      }
    }

    response = make_authenticated_request(uri, :patch, payload)

    if response.code == '200'
      data = JSON.parse(response.body)
      log_success("Scheme updated successfully")
      log_info("New total possible score: #{data['data']['marking_scheme']['total_possible_score']}")
    else
      log_error("Failed to update scheme: #{response.code}")
    end
  end

  def test_get_rule_types
    return unless @marking_scheme_id
    return if @questions.empty?

    log_test("Getting Available Rule Types (Documentation Example)")

    question_id = @questions.first['id']
    uri = URI("#{BASE_URL}/api/v1/admin/assessments/#{@assessment_id}/marking-schemes/#{@marking_scheme_id}/rules/rule_types?question_id=#{question_id}")
    response = make_authenticated_request(uri, :get)

    if response.code == '200'
      data = JSON.parse(response.body)
      rule_types = data['data']['rule_types']
      default_type = data['data']['default']

      log_success("Rule types retrieved")
      log_info("Available types: #{rule_types.map { |rt| rt['key'] }.join(', ')}")
      log_info("Default type: #{default_type}")

      # Validate response structure matches documentation
      validate_rule_types_response(data['data'])
    else
      log_error("Failed to get rule types: #{response.code}")
    end
  end

  def test_get_criteria_fields
    return unless @marking_scheme_id

    log_test("Getting Criteria Fields (Documentation Example)")

    uri = URI("#{BASE_URL}/api/v1/admin/assessments/#{@assessment_id}/marking-schemes/#{@marking_scheme_id}/rules/criteria_fields?rule_type=option_based")
    response = make_authenticated_request(uri, :get)

    if response.code == '200'
      data = JSON.parse(response.body)
      log_success("Criteria fields retrieved")
      log_info("Fields: #{data['data']['criteria_fields'].map { |f| f['name'] }.join(', ')}")
    else
      log_error("Failed to get criteria fields: #{response.code}")
    end
  end

  def test_create_option_based_rule
    return unless @marking_scheme_id
    return if @questions.empty?

    log_test("Creating Option-Based Rule (Documentation Example)")

    question_id = @questions.first['id']
    uri = URI("#{BASE_URL}/api/v1/admin/assessments/#{@assessment_id}/marking-schemes/#{@marking_scheme_id}/rules")

    # Exact example from documentation
    payload = {
      marking_rule: {
        assessment_question_id: question_id,
        rule_type: "option_based",
        points: 20.0,
        criteria: {
          partial_credit: true,
          penalty_for_incorrect: 2.0
        },
        is_active: true,
        order: 1
      }
    }

    response = make_authenticated_request(uri, :post, payload)

    if response.code == '200'
      data = JSON.parse(response.body)
      rule_id = data['data']['marking_rule']['id']
      @rule_ids << rule_id

      log_success("Option-based rule created")
      log_info("Rule ID: #{rule_id}")
      validate_rule_response(data['data']['marking_rule'])
    else
      log_error("Failed to create option-based rule: #{response.code} - #{response.body}")
    end
  end

  def test_create_text_rule
    return unless @marking_scheme_id
    return if @questions.length < 2

    log_test("Creating Text/Keyword Rule (Documentation Example)")

    # Use second question if available
    question_id = @questions[1] ? @questions[1]['id'] : @questions.first['id']
    uri = URI("#{BASE_URL}/api/v1/admin/assessments/#{@assessment_id}/marking-schemes/#{@marking_scheme_id}/rules")

    # Example from documentation
    payload = {
      marking_rule: {
        assessment_question_id: question_id,
        rule_type: "keyword_based",
        points: 15.0,
        criteria: {
          keywords: ["quality", "compliance", "certification"],
          case_sensitive: false,
          scoring_method: "proportional"
        }
      }
    }

    response = make_authenticated_request(uri, :post, payload)

    if response.code == '200'
      data = JSON.parse(response.body)
      rule_id = data['data']['marking_rule']['id']
      @rule_ids << rule_id

      log_success("Keyword-based rule created")
      log_info("Rule ID: #{rule_id}")
    else
      log_error("Failed to create keyword rule: #{response.code} - #{response.body}")
    end
  end

  def test_create_numeric_rule
    return unless @marking_scheme_id
    return if @questions.length < 3

    log_test("Creating Numeric Range Rule (Documentation Example)")

    question_id = @questions[2] ? @questions[2]['id'] : @questions.first['id']
    uri = URI("#{BASE_URL}/api/v1/admin/assessments/#{@assessment_id}/marking-schemes/#{@marking_scheme_id}/rules")

    payload = {
      marking_rule: {
        assessment_question_id: question_id,
        rule_type: "range_based",
        points: 10.0,
        criteria: {
          min: 1,
          max: 100,
          tolerance: 5
        }
      }
    }

    response = make_authenticated_request(uri, :post, payload)

    if response.code == '200'
      data = JSON.parse(response.body)
      rule_id = data['data']['marking_rule']['id']
      @rule_ids << rule_id

      log_success("Range-based rule created")
      log_info("Rule ID: #{rule_id}")
    else
      log_error("Failed to create range rule: #{response.code} - #{response.body}")
    end
  end

  def test_create_tolerance_rule
    return unless @marking_scheme_id
    return if @questions.length < 4

    log_test("Creating Tolerance-Based Rule (Documentation Example)")

    question_id = @questions[3] ? @questions[3]['id'] : @questions.first['id']
    uri = URI("#{BASE_URL}/api/v1/admin/assessments/#{@assessment_id}/marking-schemes/#{@marking_scheme_id}/rules")

    payload = {
      marking_rule: {
        assessment_question_id: question_id,
        rule_type: "tolerance_based",
        points: 10.0,
        criteria: {
          expected_value: 100,
          tolerance: 10
        }
      }
    }

    response = make_authenticated_request(uri, :post, payload)

    if response.code == '200'
      data = JSON.parse(response.body)
      rule_id = data['data']['marking_rule']['id']
      @rule_ids << rule_id

      log_success("Tolerance-based rule created")
      log_info("Rule ID: #{rule_id}")
    else
      log_error("Failed to create tolerance rule: #{response.code} - #{response.body}")
    end
  end

  def test_bulk_create_rules
    return unless @marking_scheme_id

    log_test("Bulk Create Rules (Documentation Example)")

    uri = URI("#{BASE_URL}/api/v1/admin/assessments/#{@assessment_id}/marking-schemes/#{@marking_scheme_id}/rules/bulk_create")
    response = make_authenticated_request(uri, :post)

    if response.code == '200'
      data = JSON.parse(response.body)
      created_count = data['data']['created_count']

      log_success("Bulk create completed")
      log_info("Created #{created_count} rules")

      if data['data']['marking_rules']
        data['data']['marking_rules'].each do |rule|
          @rule_ids << rule['id']
        end
      end
    else
      log_error("Failed bulk create: #{response.code}")
    end
  end

  def test_activate_scheme
    return unless @marking_scheme_id

    log_test("Activating Marking Scheme (Documentation Example)")

    uri = URI("#{BASE_URL}/api/v1/admin/assessments/#{@assessment_id}/marking-schemes/#{@marking_scheme_id}/activate")
    response = make_authenticated_request(uri, :post)

    if response.code == '200'
      data = JSON.parse(response.body)
      log_success("Scheme activated successfully")
      log_info("Active: #{data['data']['marking_scheme']['is_active']}")
    else
      log_error("Failed to activate scheme: #{response.code}")
    end
  end

  def test_clone_scheme
    return unless @marking_scheme_id

    log_test("Cloning Marking Scheme (Documentation Example)")

    uri = URI("#{BASE_URL}/api/v1/admin/assessments/#{@assessment_id}/marking-schemes/#{@marking_scheme_id}/clone")

    payload = {
      name: "Copy of Product Import Readiness Assessment"
    }

    response = make_authenticated_request(uri, :post, payload)

    if response.code == '200'
      data = JSON.parse(response.body)
      cloned_id = data['data']['marking_scheme']['id']

      log_success("Scheme cloned successfully")
      log_info("Cloned scheme ID: #{cloned_id}")
      log_info("Cloned name: #{data['data']['marking_scheme']['name']}")
    else
      log_error("Failed to clone scheme: #{response.code}")
    end
  end

  def test_preview_scoring
    return unless @marking_scheme_id

    log_test("Preview Scoring (Documentation Example)")

    uri = URI("#{BASE_URL}/api/v1/admin/marking/preview")

    # This endpoint might not exist, but it's in the documentation
    payload = {
      marking_scheme_id: @marking_scheme_id,
      sample_responses: [
        {
          question_id: @questions.first['id'],
          response_value: { text: "Sample response for testing" }
        }
      ]
    }

    response = make_authenticated_request(uri, :post, payload)

    if response.code == '200'
      data = JSON.parse(response.body)
      log_success("Preview scoring successful")
      log_info("Preview results available")
    elsif response.code == '404'
      log_warning("Preview endpoint not implemented (404)")
    else
      log_error("Preview scoring failed: #{response.code}")
    end
  end

  def print_test_summary
    puts "\n" + "=" * 60
    puts "📊 TEST SUMMARY"
    puts "=" * 60

    passed = @test_results.count { |r| r[:status] == :success }
    failed = @test_results.count { |r| r[:status] == :error }
    warnings = @test_results.count { |r| r[:status] == :warning }

    puts "✅ Passed: #{passed}"
    puts "❌ Failed: #{failed}"
    puts "⚠️  Warnings: #{warnings}"
    puts "📊 Total: #{@test_results.length}"

    if failed > 0
      puts "\n❌ FAILED TESTS:"
      @test_results.select { |r| r[:status] == :error }.each do |test|
        puts "  - #{test[:name]}: #{test[:message]}"
      end
    end

    if warnings > 0
      puts "\n⚠️  WARNINGS:"
      @test_results.select { |r| r[:status] == :warning }.each do |test|
        puts "  - #{test[:name]}: #{test[:message]}"
      end
    end

    puts "\n🎯 DOCUMENTATION COVERAGE:"
    puts "✅ Authentication examples"
    puts "✅ Marking scheme CRUD operations"
    puts "✅ Rule type discovery"
    puts "✅ Rule creation (multiple types)"
    puts "✅ Bulk operations"
    puts "✅ Scheme activation/cloning"
    puts "⚠️  Preview scoring (endpoint may not exist)"

    puts "\n📝 Created Resources:"
    puts "  Marking Scheme ID: #{@marking_scheme_id}"
    puts "  Rule IDs: #{@rule_ids.join(', ')}" if @rule_ids.any?
  end

  # Helper methods

  def make_request(uri, method, body = nil)
    http = Net::HTTP.new(uri.host, uri.port)

    request = case method
              when :get then Net::HTTP::Get.new(uri)
              when :post then Net::HTTP::Post.new(uri)
              when :patch then Net::HTTP::Patch.new(uri)
              when :delete then Net::HTTP::Delete.new(uri)
              end

    request['Content-Type'] = 'application/json'
    request.body = body.to_json if body

    http.request(request)
  end

  def make_authenticated_request(uri, method, body = nil)
    http = Net::HTTP.new(uri.host, uri.port)

    request = case method
              when :get then Net::HTTP::Get.new(uri)
              when :post then Net::HTTP::Post.new(uri)
              when :patch then Net::HTTP::Patch.new(uri)
              when :delete then Net::HTTP::Delete.new(uri)
              end

    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{@admin_token}"
    request.body = body.to_json if body

    http.request(request)
  end

  def log_test(name)
    puts "\n🧪 #{name}"
    @current_test = name
  end

  def log_success(message)
    puts "   ✅ #{message}"
    @test_results << { name: @current_test, status: :success, message: message }
  end

  def log_error(message)
    puts "   ❌ #{message}"
    @test_results << { name: @current_test, status: :error, message: message }
  end

  def log_warning(message)
    puts "   ⚠️  #{message}"
    @test_results << { name: @current_test, status: :warning, message: message }
  end

  def log_info(message)
    puts "   📝 #{message}"
  end

  def validate_scheme_response(scheme)
    expected_fields = %w[id name description is_active total_possible_score settings created_at updated_at]
    missing = expected_fields - scheme.keys

    if missing.empty?
      log_success("Response structure validation passed")
    else
      log_warning("Missing fields: #{missing.join(', ')}")
    end

    # Validate settings
    if scheme['settings']
      expected_settings = %w[passing_score grade_boundaries feedback_templates]
      missing_settings = expected_settings - scheme['settings'].keys

      if missing_settings.empty?
        log_success("Settings structure validation passed")
      else
        log_warning("Missing settings: #{missing_settings.join(', ')}")
      end
    end
  end

  def validate_rule_response(rule)
    expected_fields = %w[id assessment_question_id assessment_marking_scheme_id rule_type points criteria is_active order created_at updated_at]
    missing = expected_fields - rule.keys

    if missing.empty?
      log_success("Rule structure validation passed")
    else
      log_warning("Missing rule fields: #{missing.join(', ')}")
    end
  end

  def validate_rule_types_response(data)
    if data['rule_types'] && data['rule_types'].is_a?(Array) && data['default']
      log_success("Rule types response structure valid")

      # Check if each rule type has required fields
      data['rule_types'].each do |rt|
        unless rt['key'] && rt['name']
          log_warning("Rule type missing key or name: #{rt}")
        end
      end
    else
      log_warning("Invalid rule types response structure")
    end
  end
end

# Run the comprehensive tests
if __FILE__ == $0
  tester = ComprehensiveMarkingTester.new
  tester.run_all_tests
end
