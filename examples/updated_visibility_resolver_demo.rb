# Updated VisibilityResolver Demo
# Shows the new session-based convenience methods in VisibilityResolver
# Run this in Rails console: rails runner examples/updated_visibility_resolver_demo.rb

puts "=== Updated VisibilityResolver Demo ==="

# Get test data
assessment = Assessment.first
john = User.find_by(email_address: "john@example.com")
chinese_user = User.find_by(email_address: "li@example.com")

unless assessment && john && chinese_user
  puts "❌ Missing test data. Please run db:seed first."
  exit
end

puts "\n📊 Assessment: #{assessment.title}"

# Create sessions
john_session = assessment.assessment_response_sessions.find_or_create_by(user: john) do |session|
  session.respondent_name = john.full_name
end

chinese_session = assessment.assessment_response_sessions.find_or_create_by(user: chinese_user) do |session|
  session.respondent_name = chinese_user.full_name
end

puts "✅ Sessions created with user associations"

puts "\n=== NEW: Session-Based Convenience Methods ==="

puts "\n🔍 Direct Session Methods (No User Parameter Needed):"

# Test new session-based methods on Assessment
puts "\n📂 Assessment.visible_sections_for_session(session):"
john_sections = assessment.visible_sections_for_session(john_session)
chinese_sections = assessment.visible_sections_for_session(chinese_session)
puts "   John: #{john_sections.pluck(:name).join(', ')}"
puts "   Li: #{chinese_sections.pluck(:name).join(', ')}"

puts "\n❓ Assessment.visible_questions_for_session(session):"
john_questions = assessment.visible_questions_for_session(john_session)
chinese_questions = assessment.visible_questions_for_session(chinese_session)
puts "   John: #{john_questions.count} questions"
puts "   Li: #{chinese_questions.count} questions"

puts "\n✅ Assessment.session_can_complete?(session):"
john_can_complete = assessment.session_can_complete?(john_session)
chinese_can_complete = assessment.session_can_complete?(chinese_session)
puts "   John: #{john_can_complete ? 'Yes' : 'No'}"
puts "   Li: #{chinese_can_complete ? 'Yes' : 'No'}"

puts "\n📊 Assessment.completion_stats_for_session(session):"
john_stats = assessment.completion_stats_for_session(john_session)
chinese_stats = assessment.completion_stats_for_session(chinese_session)
puts "   John: #{john_stats[:questions][:answered]}/#{john_stats[:questions][:total]} questions answered"
puts "   Li: #{chinese_stats[:questions][:answered]}/#{chinese_stats[:questions][:total]} questions answered"

puts "\n🧭 Assessment.next_visible_question_for_session(session):"
john_next_q = assessment.next_visible_question_for_session(john_session)
chinese_next_q = assessment.next_visible_question_for_session(chinese_session)
puts "   John: #{john_next_q&.text&.dig('en')&.truncate(40) || 'None'}"
puts "   Li: #{chinese_next_q&.text&.dig('en')&.truncate(40) || 'None'}"

puts "\n📁 Assessment.next_visible_section_for_session(session):"
john_next_s = assessment.next_visible_section_for_session(john_session)
chinese_next_s = assessment.next_visible_section_for_session(chinese_session)
puts "   John: #{john_next_s&.name || 'None'}"
puts "   Li: #{chinese_next_s&.name || 'None'}"

puts "\n📝 Assessment.unanswered_required_questions_for_session(session):"
john_unanswered = assessment.unanswered_required_questions_for_session(john_session)
chinese_unanswered = assessment.unanswered_required_questions_for_session(chinese_session)
puts "   John: #{john_unanswered.count} unanswered"
puts "   Li: #{chinese_unanswered.count} unanswered"

puts "\n🎯 Assessment.first_unanswered_required_question_for_session(session):"
john_first_unanswered = assessment.first_unanswered_required_question_for_session(john_session)
chinese_first_unanswered = assessment.first_unanswered_required_question_for_session(chinese_session)
puts "   John: #{john_first_unanswered&.text&.dig('en')&.truncate(40) || 'All answered'}"
puts "   Li: #{chinese_first_unanswered&.text&.dig('en')&.truncate(40) || 'All answered'}"

puts "\n👁️ Assessment.question_visible_to_session?(question, session):"
first_question = assessment.assessment_questions.first
john_q_visible = assessment.question_visible_to_session?(first_question, john_session)
chinese_q_visible = assessment.question_visible_to_session?(first_question, chinese_session)
puts "   First question visible to John: #{john_q_visible ? 'Yes' : 'No'}"
puts "   First question visible to Li: #{chinese_q_visible ? 'Yes' : 'No'}"

puts "\n📂 Assessment.section_visible_to_session?(section, session):"
first_section = assessment.assessment_sections.first
john_s_visible = assessment.section_visible_to_session?(first_section, john_session)
chinese_s_visible = assessment.section_visible_to_session?(first_section, chinese_session)
puts "   First section visible to John: #{john_s_visible ? 'Yes' : 'No'}"
puts "   First section visible to Li: #{chinese_s_visible ? 'Yes' : 'No'}"

puts "\n=== UPDATED: Session Model Methods ==="

puts "\n🔄 Session methods now use new convenience methods:"

puts "\n📂 session.visible_sections:"
puts "   John: #{john_session.visible_sections.pluck(:name).join(', ')}"
puts "   Li: #{chinese_session.visible_sections.pluck(:name).join(', ')}"

puts "\n❓ session.visible_questions:"
puts "   John: #{john_session.visible_questions.count} questions"
puts "   Li: #{chinese_session.visible_questions.count} questions"

puts "\n✅ session.all_required_visible_questions_answered?:"
puts "   John: #{john_session.all_required_visible_questions_answered? ? 'Yes' : 'No'}"
puts "   Li: #{chinese_session.all_required_visible_questions_answered? ? 'Yes' : 'No'}"

puts "\n📊 session.completion_stats:"
john_session_stats = john_session.completion_stats
chinese_session_stats = chinese_session.completion_stats
puts "   John overall completion: #{john_session_stats[:overall][:can_complete] ? 'Ready' : 'Not ready'}"
puts "   Li overall completion: #{chinese_session_stats[:overall][:can_complete] ? 'Ready' : 'Not ready'}"

puts "\n🧭 session.next_visible_question:"
puts "   John: #{john_session.next_visible_question&.text&.dig('en')&.truncate(40) || 'None'}"
puts "   Li: #{chinese_session.next_visible_question&.text&.dig('en')&.truncate(40) || 'None'}"

puts "\n📁 session.next_visible_section:"
puts "   John: #{john_session.next_visible_section&.name || 'None'}"
puts "   Li: #{chinese_session.next_visible_section&.name || 'None'}"

puts "\n👁️ session.question_visible?(question):"
puts "   First question visible to John: #{john_session.question_visible?(first_question) ? 'Yes' : 'No'}"
puts "   First question visible to Li: #{chinese_session.question_visible?(first_question) ? 'Yes' : 'No'}"

puts "\n📂 session.section_visible?(section):"
puts "   First section visible to John: #{john_session.section_visible?(first_section) ? 'Yes' : 'No'}"
puts "   First section visible to Li: #{chinese_session.section_visible?(first_section) ? 'Yes' : 'No'}"

puts "\n=== Performance Comparison ==="

require 'benchmark'

puts "\n⚡ Testing performance of new session-based methods..."

# Old way (simulated with user parameter)
old_time = Benchmark.measure do
  50.times do
    assessment.visible_questions_for_user(john, john_session)
    assessment.visible_sections_for_user(chinese_user, chinese_session)
    assessment.question_visible_to_user?(first_question, john, john_session)
  end
end

# New way (session-based)
new_time = Benchmark.measure do
  50.times do
    assessment.visible_questions_for_session(john_session)
    assessment.visible_sections_for_session(chinese_session)
    assessment.question_visible_to_session?(first_question, john_session)
  end
end

puts "   Old approach (with user param): #{old_time.real.round(3)}s"
puts "   New approach (session-based): #{new_time.real.round(3)}s"
puts "   Performance improvement: #{((old_time.real - new_time.real) / old_time.real * 100).round(1)}%"

puts "\n=== Code Clarity Comparison ==="

puts "\n📝 Before (verbose):"
puts "   assessment.visible_questions_for_user(session.user, session)"
puts "   assessment.question_visible_to_user?(question, session.user, session)"
puts "   assessment.all_required_visible_questions_completed_for_user?(session.user, session)"

puts "\n✨ After (clean):"
puts "   assessment.visible_questions_for_session(session)"
puts "   assessment.question_visible_to_session?(question, session)"
puts "   assessment.session_can_complete?(session)"

puts "\n🎉 VisibilityResolver Update Complete!"

puts "\n✅ New Session-Based Methods Added:"
puts "   • visible_sections_for_session(session)"
puts "   • visible_questions_for_session(session)"
puts "   • session_can_complete?(session)"
puts "   • completion_stats_for_session(session)"
puts "   • next_visible_question_for_session(session, current = nil)"
puts "   • next_visible_section_for_session(session, current = nil)"
puts "   • previous_visible_question_for_session(session, current)"
puts "   • previous_visible_section_for_session(session, current)"
puts "   • unanswered_required_questions_for_session(session)"
puts "   • first_unanswered_required_question_for_session(session)"
puts "   • question_visible_to_session?(question, session)"
puts "   • section_visible_to_session?(section, session)"
puts "   • visible_questions_in_section_for_session(section, session)"
puts "   • visibility_summary_for_session(session)"

puts "\n🔧 Benefits:"
puts "   • Cleaner API - no need to pass user parameter"
puts "   • Better performance - leverages session.user association"
puts "   • More intuitive - session-centric approach"
puts "   • Backward compatible - old methods still work"
puts "   • Consistent with Rails conventions"

puts "\n🚀 All visibility features updated for the new user association architecture!"
