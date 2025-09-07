#!/usr/bin/env ruby
# Test script to validate the corrected examples from the documentation

require 'net/http'
require 'json'
require 'uri'

class CorrectedExamplesValidator
  BASE_URL = 'http://localhost:3000'

  def initialize
    @admin_token = nil
    @assessment_id = 85
    @marking_scheme_id = nil
  end

  def run_validation
    puts "🔧 VALIDATING CORRECTED DOCUMENTATION EXAMPLES"
    puts "=" * 60

    login_admin
    create_test_scheme
    test_corrected_rule_examples

    puts "\n✅ Validation completed!"
  end

  private

  def login_admin
    puts "\n1. Admin Login..."

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
      puts "   ✅ Login successful"
    else
      puts "   ❌ Login failed: #{response.code}"
      exit 1
    end
  end

  def create_test_scheme
    puts "\n2. Creating Test Scheme..."

    uri = URI("#{BASE_URL}/api/v1/admin/assessments/#{@assessment_id}/marking-schemes")

    payload = {
      marking_scheme: {
        name: "Corrected Examples Test Scheme",
        description: "Testing corrected documentation examples",
        total_possible_score: 100.0
      }
    }

    response = make_authenticated_request(uri, :post, payload)

    if response.code == '200'
      data = JSON.parse(response.body)
      @marking_scheme_id = data['data']['marking_scheme']['id']
      puts "   ✅ Test scheme created (ID: #{@marking_scheme_id})"
    else
      puts "   ❌ Failed to create scheme: #{response.code}"
      exit 1
    end
  end

  def test_corrected_rule_examples
    puts "\n3. Testing Corrected Rule Examples..."

    # Get actual questions from the assessment
    require_relative 'config/environment'
    assessment = Assessment.find(@assessment_id)
    questions = []

    assessment.assessment_sections.each do |section|
      section.assessment_questions.each do |question|
        questions << {
          id: question.id,
          type: question.type,
          text: question.text
        }
      end
    end

    puts "   📝 Found #{questions.length} questions to test with"

    # Test each question type with appropriate rule
    questions.each do |question|
      test_question_with_appropriate_rule(question)
    end
  end

  def test_question_with_appropriate_rule(question)
    puts "\n   🧪 Testing #{question[:type]} (ID: #{question[:id]})"

    # Get available rule types for this question
    uri = URI("#{BASE_URL}/api/v1/admin/assessments/#{@assessment_id}/marking-schemes/#{@marking_scheme_id}/rules/rule_types?question_id=#{question[:id]}")
    response = make_authenticated_request(uri, :get)

    if response.code == '200'
      data = JSON.parse(response.body)
      available_types = data['data']['rule_types'].map { |rt| rt['key'] }
      default_type = data['data']['default']

      puts "      📝 Available types: #{available_types.join(', ')}"
      puts "      📝 Default type: #{default_type}"

      # Test creating a rule with the default type
      test_create_rule_with_type(question[:id], default_type, question[:type])

    else
      puts "      ❌ Failed to get rule types: #{response.code}"
    end
  end

  def test_create_rule_with_type(question_id, rule_type, question_type)
    puts "      🔧 Creating #{rule_type} rule..."

    uri = URI("#{BASE_URL}/api/v1/admin/assessments/#{@assessment_id}/marking-schemes/#{@marking_scheme_id}/rules")

    # Create appropriate criteria based on rule type
    criteria = case rule_type
               when 'option_based'
                 { partial_credit: true }
               when 'range_based'
                 { min: 1, max: 100, tolerance: 5 }
               when 'tolerance_based'
                 { expected_value: 50, tolerance: 10 }
               when 'exact_match'
                 { expected_values: ["test"], case_sensitive: false }
               when 'keyword_based'
                 { keywords: ["test", "example"], scoring_method: "proportional" }
               else
                 {}
               end

    payload = {
      marking_rule: {
        assessment_question_id: question_id,
        rule_type: rule_type,
        points: 10.0,
        criteria: criteria,
        is_active: true
      }
    }

    response = make_authenticated_request(uri, :post, payload)

    if response.code == '200'
      data = JSON.parse(response.body)
      rule_id = data['data']['marking_rule']['id']
      puts "      ✅ Rule created successfully (ID: #{rule_id})"

      # Validate the response structure
      rule = data['data']['marking_rule']
      validate_rule_response(rule, rule_type, criteria)

    else
      puts "      ❌ Failed to create rule: #{response.code}"
      puts "      📝 Response: #{response.body}"
    end
  end

  def validate_rule_response(rule, expected_type, expected_criteria)
    issues = []

    issues << "Missing rule_type" unless rule['rule_type']
    issues << "Wrong rule_type: expected #{expected_type}, got #{rule['rule_type']}" if rule['rule_type'] != expected_type
    issues << "Missing points" unless rule['points']
    issues << "Missing criteria" unless rule['criteria']
    issues << "Missing is_active" unless rule.key?('is_active')

    if issues.empty?
      puts "      ✅ Rule response validation passed"
    else
      puts "      ⚠️  Rule response issues: #{issues.join(', ')}"
    end
  end

  def make_request(uri, method, body = nil)
    http = Net::HTTP.new(uri.host, uri.port)

    request = case method
              when :get then Net::HTTP::Get.new(uri)
              when :post then Net::HTTP::Post.new(uri)
              when :patch then Net::HTTP::Patch.new(uri)
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
              end

    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{@admin_token}"
    request.body = body.to_json if body

    http.request(request)
  end
end

# Run the validation
if __FILE__ == $0
  validator = CorrectedExamplesValidator.new
  validator.run_validation
end
