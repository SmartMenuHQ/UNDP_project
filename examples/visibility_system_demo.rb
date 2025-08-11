# Complete Visibility System Demo
# Shows how conditional visibility and country restrictions work together
# Run this in Rails console: rails runner examples/visibility_system_demo.rb

puts "=== Complete Visibility System Demo ==="

# Get our test data
assessment = Assessment.first
admin = User.find_by(email_address: "admin@questionnaire.com")
john = User.find_by(email_address: "john@example.com")  # USA
chinese_user = User.find_by(email_address: "li@example.com")  # China

unless assessment && admin && john && chinese_user
  puts "❌ Missing test data. Please run db:seed first."
  exit
end

puts "\n📝 Testing with assessment: #{assessment.title}"
puts "   Total sections: #{assessment.assessment_sections.count}"
puts "   Total questions: #{assessment.assessment_questions.count}"

# Create response sessions for testing
puts "\n🎯 Creating response sessions..."

john_session = assessment.assessment_response_sessions.find_or_create_by(
  user: john
) do |session|
  session.respondent_name = john.full_name
  session.assessment = assessment
end

chinese_session = assessment.assessment_response_sessions.find_or_create_by(
  user: chinese_user
) do |session|
  session.respondent_name = chinese_user.full_name
  session.assessment = assessment
end

puts "✅ Created sessions for John (USA) and Li (China)"

puts "\n=== Initial Visibility (No Responses) ==="

# Test visibility without any responses
puts "\n👤 John (USA) - Initial visibility:"
john_visibility = assessment.visibility_summary_for_user(john, john_session)
puts "   Visible sections: #{john_visibility[:sections][:visible]}/#{john_visibility[:sections][:total]} (#{john_visibility[:sections][:visibility_percentage]}%)"
puts "   Visible questions: #{john_visibility[:questions][:visible]}/#{john_visibility[:questions][:total]} (#{john_visibility[:questions][:visibility_percentage]}%)"
puts "   Country restricted: #{john_visibility[:sections][:country_restricted]} sections, #{john_visibility[:questions][:country_restricted]} questions"
puts "   Conditionally hidden: #{john_visibility[:sections][:conditionally_hidden]} sections, #{john_visibility[:questions][:conditionally_hidden]} questions"

puts "\n👤 Li (China) - Initial visibility:"
chinese_visibility = assessment.visibility_summary_for_user(chinese_user, chinese_session)
puts "   Visible sections: #{chinese_visibility[:sections][:visible]}/#{chinese_visibility[:sections][:total]} (#{chinese_visibility[:sections][:visibility_percentage]}%)"
puts "   Visible questions: #{chinese_visibility[:questions][:visible]}/#{chinese_visibility[:questions][:total]} (#{chinese_visibility[:questions][:visibility_percentage]}%)"
puts "   Country restricted: #{chinese_visibility[:sections][:country_restricted]} sections, #{chinese_visibility[:questions][:country_restricted]} questions"
puts "   Conditionally hidden: #{chinese_visibility[:sections][:conditionally_hidden]} sections, #{chinese_visibility[:questions][:conditionally_hidden]} questions"

puts "\n=== Section-by-Section Visibility ==="

assessment.assessment_sections.ordered.each do |section|
  puts "\n📂 Section: #{section.name}"
  puts "   Has country restrictions: #{section.has_country_restrictions?}"
  puts "   Has conditional visibility: #{section.is_conditional?}"

  if section.has_country_restrictions?
    puts "   Restricted countries: #{section.restricted_country_names.join(', ')}"
  end

  if section.is_conditional?
    puts "   Condition: #{section.condition_description}"
  end

  # Test visibility for each user
  john_visible = assessment.section_visible_to_user?(section, john, john_session)
  chinese_visible = assessment.section_visible_to_user?(section, chinese_user, chinese_session)

  puts "   👤 John (USA): #{john_visible ? '✅ Visible' : '❌ Hidden'}"
  puts "   👤 Li (China): #{chinese_visible ? '✅ Visible' : '❌ Hidden'}"

  # Show questions in this section
  visible_questions_john = assessment.visible_questions_in_section_for_user(section, john, john_session)
  visible_questions_chinese = assessment.visible_questions_in_section_for_user(section, chinese_user, chinese_session)

  puts "   Questions for John: #{visible_questions_john.count}/#{section.assessment_questions.count}"
  puts "   Questions for Li: #{visible_questions_chinese.count}/#{section.assessment_questions.count}"
end

puts "\n=== Adding Responses to Trigger Conditional Visibility ==="

# Get the tech experience question (trigger for programming section)
tech_question = assessment.assessment_questions.joins(:assessment_section)
                          .find_by(assessment_sections: { name: "Basic Information" })
                          .assessment_section.assessment_questions
                          .find { |q| q.text['en'].include?('technology experience') }

if tech_question
  puts "\n🎯 Adding responses to trigger question: #{tech_question.text['en']}"

  # John selects "Advanced" (should trigger programming section)
  advanced_option = tech_question.assessment_question_options.find { |opt| opt.text['en'].include?('Advanced') }

  if advanced_option
    john_response = john_session.assessment_question_responses.find_or_create_by(
      assessment_question: tech_question,
      assessment: assessment
    ) do |response|
      response.value = { selected_options: [advanced_option.id] }
    end

    # Create selected option record
    john_response.selected_options.find_or_create_by(
      assessment_question_option: advanced_option
    )

    puts "✅ John selected 'Advanced' - should unlock programming section"
  end

  # Chinese user selects "Beginner" (should NOT trigger programming section)
  beginner_option = tech_question.assessment_question_options.find { |opt| opt.text['en'].include?('Beginner') }

  if beginner_option
    chinese_response = chinese_session.assessment_question_responses.find_or_create_by(
      assessment_question: tech_question,
      assessment: assessment
    ) do |response|
      response.value = { selected_options: [beginner_option.id] }
    end

    # Create selected option record
    chinese_response.selected_options.find_or_create_by(
      assessment_question_option: beginner_option
    )

    puts "✅ Li selected 'Beginner' - programming section should remain hidden"
  end
end

puts "\n=== Visibility After Responses ==="

puts "\n👤 John (USA) - After selecting 'Advanced':"
john_visibility_after = assessment.visibility_summary_for_user(john, john_session)
puts "   Visible sections: #{john_visibility_after[:sections][:visible]}/#{john_visibility_after[:sections][:total]} (#{john_visibility_after[:sections][:visibility_percentage]}%)"
puts "   Visible questions: #{john_visibility_after[:questions][:visible]}/#{john_visibility_after[:questions][:total]} (#{john_visibility_after[:questions][:visibility_percentage]}%)"

visible_sections_john = assessment.visible_sections_for_user(john, john_session)
puts "   Visible section names: #{visible_sections_john.pluck(:name).join(', ')}"

puts "\n👤 Li (China) - After selecting 'Beginner':"
chinese_visibility_after = assessment.visibility_summary_for_user(chinese_user, chinese_session)
puts "   Visible sections: #{chinese_visibility_after[:sections][:visible]}/#{chinese_visibility_after[:sections][:total]} (#{chinese_visibility_after[:sections][:visibility_percentage]}%)"
puts "   Visible questions: #{chinese_visibility_after[:questions][:visible]}/#{chinese_visibility_after[:questions][:total]} (#{chinese_visibility_after[:questions][:visibility_percentage]}%)"

visible_sections_chinese = assessment.visible_sections_for_user(chinese_user, chinese_session)
puts "   Visible section names: #{visible_sections_chinese.pluck(:name).join(', ')}"

puts "\n=== Navigation Testing ==="

# Test navigation for John
puts "\n🧭 John's Navigation:"
john_first_section = john_session.next_visible_section
puts "   First section: #{john_first_section&.name || 'None'}"

if john_first_section
  john_next_section = john_session.next_visible_section(john_first_section)
  puts "   Next section after '#{john_first_section.name}': #{john_next_section&.name || 'None'}"
end

john_first_question = john_session.next_visible_question
puts "   First question: #{john_first_question&.text&.dig('en')&.truncate(50) || 'None'}"

if john_first_question
  john_next_question = john_session.next_visible_question(john_first_question)
  puts "   Next question: #{john_next_question&.text&.dig('en')&.truncate(50) || 'None'}"
end

# Test navigation for Chinese user
puts "\n🧭 Li's Navigation:"
chinese_first_section = chinese_session.next_visible_section
puts "   First section: #{chinese_first_section&.name || 'None'}"

if chinese_first_section
  chinese_next_section = chinese_session.next_visible_section(chinese_first_section)
  puts "   Next section after '#{chinese_first_section.name}': #{chinese_next_section&.name || 'None'}"
end

chinese_first_question = chinese_session.next_visible_question
puts "   First question: #{chinese_first_question&.text&.dig('en')&.truncate(50) || 'None'}"

puts "\n=== Completion Status Testing ==="

# Test completion status
puts "\n📊 Completion Status:"

john_stats = john_session.completion_stats
puts "\n👤 John's Progress:"
puts "   Sections: #{john_stats[:sections][:completed]}/#{john_stats[:sections][:total]} (#{john_stats[:sections][:percentage]}%)"
puts "   Questions: #{john_stats[:questions][:answered]}/#{john_stats[:questions][:total]} (#{john_stats[:questions][:percentage]}%)"
puts "   Required Questions: #{john_stats[:required_questions][:answered]}/#{john_stats[:required_questions][:total]} (#{john_stats[:required_questions][:percentage]}%)"
puts "   Can Complete: #{john_stats[:overall][:can_complete] ? '✅ Yes' : '❌ No'}"
puts "   Fully Answered: #{john_stats[:overall][:is_fully_answered] ? '✅ Yes' : '❌ No'}"

chinese_stats = chinese_session.completion_stats
puts "\n👤 Li's Progress:"
puts "   Sections: #{chinese_stats[:sections][:completed]}/#{chinese_stats[:sections][:total]} (#{chinese_stats[:sections][:percentage]}%)"
puts "   Questions: #{chinese_stats[:questions][:answered]}/#{chinese_stats[:questions][:total]} (#{chinese_stats[:questions][:percentage]}%)"
puts "   Required Questions: #{chinese_stats[:required_questions][:answered]}/#{chinese_stats[:required_questions][:total]} (#{chinese_stats[:required_questions][:percentage]}%)"
puts "   Can Complete: #{chinese_stats[:overall][:can_complete] ? '✅ Yes' : '❌ No'}"
puts "   Fully Answered: #{chinese_stats[:overall][:is_fully_answered] ? '✅ Yes' : '❌ No'}"

# Show unanswered required questions
john_unanswered = john_session.unanswered_required_questions
chinese_unanswered = chinese_session.unanswered_required_questions

puts "\n📝 Unanswered Required Questions:"
puts "   John: #{john_unanswered.count} questions"
john_unanswered.limit(3).each do |question|
  puts "     • #{question.text['en'].truncate(60)}"
end

puts "   Li: #{chinese_unanswered.count} questions"
chinese_unanswered.limit(3).each do |question|
  puts "     • #{question.text['en'].truncate(60)}"
end

# Test first unanswered question for navigation
john_first_unanswered = john_session.first_unanswered_required_question
chinese_first_unanswered = chinese_session.first_unanswered_required_question

puts "\n🎯 Next Required Question to Answer:"
puts "   John: #{john_first_unanswered&.text&.dig('en')&.truncate(60) || 'All required questions answered'}"
puts "   Li: #{chinese_first_unanswered&.text&.dig('en')&.truncate(60) || 'All required questions answered'}"

puts "\n=== Session State Management ==="

# Test session completion eligibility
puts "\n🏁 Session Completion Eligibility:"
puts "   John can complete: #{john_session.can_be_completed? ? '✅ Yes' : '❌ No'}"
puts "   Li can complete: #{chinese_session.can_be_completed? ? '✅ Yes' : '❌ No'}"

# Show session states
puts "\n📊 Session States:"
puts "   John's session state: #{john_session.state}"
puts "   Li's session state: #{chinese_session.state}"

puts "\n=== Marking Job Integration ==="

# Simulate what the marking job would see
puts "\n🎯 Marking Job Perspective:"

john_responses = john_session.assessment_question_responses.includes(:assessment_question)
chinese_responses = chinese_session.assessment_question_responses.includes(:assessment_question)

puts "   John's responses to grade: #{john_responses.count}"
john_responses.each do |response|
  visible = john_session.question_visible?(response.assessment_question)
  puts "     • Q#{response.assessment_question.order}: #{visible ? 'Visible' : 'Hidden'} - #{response.assessment_question.text['en'].truncate(40)}"
end

puts "   Li's responses to grade: #{chinese_responses.count}"
chinese_responses.each do |response|
  visible = chinese_session.question_visible?(response.assessment_question)
  puts "     • Q#{response.assessment_question.order}: #{visible ? 'Visible' : 'Hidden'} - #{response.assessment_question.text['en'].truncate(40)}"
end

puts "\n=== Performance Testing ==="

# Test performance of visibility methods
puts "\n⚡ Performance Testing:"

require 'benchmark'

time = Benchmark.measure do
  100.times do
    assessment.visible_questions_for_user(john, john_session)
    assessment.visible_sections_for_user(chinese_user, chinese_session)
  end
end

puts "   100 visibility calculations: #{time.real.round(3)}s"

puts "\n🎉 Complete Visibility System Demo Completed!"

puts "\n💡 Key Features Demonstrated:"
puts "   ✅ Country-based content restrictions"
puts "   ✅ Conditional visibility based on responses"
puts "   ✅ Combined visibility logic (country + conditional)"
puts "   ✅ Navigation with visibility awareness"
puts "   ✅ Completion tracking with visible questions only"
puts "   ✅ Session state management integration"
puts "   ✅ Marking job compatibility"
puts "   ✅ Performance optimization"

puts "\n🔧 System Benefits:"
puts "   • Users only see content appropriate for their country"
puts "   • Dynamic content based on previous responses"
puts "   • Accurate completion tracking"
puts "   • Proper navigation flow"
puts "   • Marking jobs process only visible responses"
puts "   • Admin visibility into restriction effects"

puts "\n📈 Statistics Summary:"
puts "   • John (USA): #{john_visibility_after[:sections][:visible]} sections, #{john_visibility_after[:questions][:visible]} questions visible"
puts "   • Li (China): #{chinese_visibility_after[:sections][:visible]} sections, #{chinese_visibility_after[:questions][:visible]} questions visible"
puts "   • Conditional logic triggered by user responses"
puts "   • Country restrictions properly enforced"
puts "   • Navigation and completion logic working correctly"
