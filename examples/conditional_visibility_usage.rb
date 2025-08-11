# Example usage of Conditional Visibility System
# Run this in Rails console: rails runner examples/conditional_visibility_usage.rb

puts "=== Conditional Visibility System Demo ==="

# Find or create an assessment
assessment = Assessment.first
unless assessment
  puts "No assessment found. Please create an assessment first."
  exit
end

puts "Using assessment: #{assessment.title}"

# Initialize the service
visibility_service = ConditionalVisibilityService.new(assessment)

# Get the first few questions for demonstration
questions = assessment.assessment_questions.ordered.limit(5)
sections = assessment.assessment_sections.ordered.limit(3)

if questions.count < 3
  puts "Need at least 3 questions for this demo. Please add more questions to your assessment."
  exit
end

puts "\n=== Setting up conditional visibility ==="

# Example 1: Question visibility based on multiple choice selection
# "Show question 3 if user selects option A or B in question 1"
trigger_question = questions.first
target_question = questions.third

if trigger_question.assessment_question_options.any?
  option_ids = trigger_question.assessment_question_options.limit(2).pluck(:id)

  begin
    visibility_service.create_option_condition(
      target_question,
      trigger_question.id,
      option_ids,
      'contains'
    )
    puts "✓ Set up option-based condition: '#{target_question.text[0..50]}...' visible when '#{trigger_question.text[0..50]}...' includes specific options"
  rescue => e
    puts "✗ Failed to create option condition: #{e.message}"
  end
end

# Example 2: Section visibility based on text response
# "Show section 2 if user answers 'yes' to question 2"
if questions.count >= 2 && sections.count >= 2
  trigger_question = questions.second
  target_section = sections.second

  begin
    visibility_service.create_value_condition(
      target_section,
      trigger_question.id,
      ['yes', 'Yes', 'YES'],
      'contains'
    )
    puts "✓ Set up value-based condition: Section '#{target_section.name}' visible when '#{trigger_question.text[0..50]}...' contains 'yes'"
  rescue => e
    puts "✗ Failed to create value condition: #{e.message}"
  end
end

# Example 3: Question visibility based on numeric range
# "Show question 4 if user enters a value between 18 and 65 in question 2"
if questions.count >= 4
  trigger_question = questions.second
  target_question = questions.fourth

  begin
    visibility_service.create_range_condition(
      target_question,
      trigger_question.id,
      18,
      65
    )
    puts "✓ Set up range-based condition: '#{target_question.text[0..50]}...' visible when '#{trigger_question.text[0..50]}...' is between 18 and 65"
  rescue => e
    puts "✗ Failed to create range condition: #{e.message}"
  end
end

puts "\n=== Conditional Summary ==="
summary = visibility_service.conditional_summary
puts "Conditional questions: #{summary[:conditional_questions]}/#{summary[:total_questions]}"
puts "Conditional sections: #{summary[:conditional_sections]}/#{summary[:total_sections]}"

puts "\nConditions:"
summary[:conditions].each do |condition|
  puts "  - #{condition[:type].capitalize}: #{condition[:target]} - #{condition[:description]}"
end

puts "\n=== Testing with a Response Session ==="

# Create a test response session
session = assessment.assessment_response_sessions.create!(
  participant_name: "Test User",
  participant_email: "test@example.com"
)

puts "Created test session: #{session.id}"

# Test initial visibility (no responses yet)
puts "\nInitial visibility (no responses):"
test_result = visibility_service.test_visibility_for_session(session)
puts "  Visible sections: #{test_result[:visible_sections].map(&:last).join(', ')}"
puts "  Visible questions: #{test_result[:visible_questions].count} questions"
puts "  Hidden sections: #{test_result[:hidden_sections].map(&:last).join(', ')}"
puts "  Hidden questions: #{test_result[:hidden_questions].count} questions"

# Add some responses to trigger visibility changes
puts "\nAdding responses to trigger conditions..."

# Response to trigger question for option-based condition
if trigger_question.assessment_question_options.any?
  option = trigger_question.assessment_question_options.first
  response = session.assessment_question_responses.create!(
    assessment: assessment,
    assessment_question: trigger_question,
    value: { selected_options: [option.id] }
  )

  # Create selected option record
  response.selected_options.create!(
    assessment_question_option: option
  )

  puts "  ✓ Added response to trigger question (selected option: #{option.text})"
end

# Response to trigger question for value-based condition
if questions.count >= 2
  session.assessment_question_responses.create!(
    assessment: assessment,
    assessment_question: questions.second,
    value: { text: "yes" }
  )
  puts "  ✓ Added 'yes' response to second question"
end

# Test visibility after responses
puts "\nVisibility after responses:"
test_result = visibility_service.test_visibility_for_session(session)
puts "  Visible sections: #{test_result[:visible_sections].map(&:last).join(', ')}"
puts "  Visible questions: #{test_result[:visible_questions].count} questions"
puts "  Hidden sections: #{test_result[:hidden_sections].map(&:last).join(', ')}"
puts "  Hidden questions: #{test_result[:hidden_questions].count} questions"

# Test session methods
puts "\nTesting session visibility methods:"
puts "  session.visible_questions.count: #{session.visible_questions.count}"
puts "  session.visible_sections.count: #{session.visible_sections.count}"

sections.each do |section|
  percentage = session.section_completion_percentage(section)
  puts "  Section '#{section.name}' completion: #{percentage}%"
end

puts "\n=== Dependency Graph ==="
graph = visibility_service.dependency_graph
puts "Nodes: #{graph[:nodes].count} (#{graph[:nodes].count { |n| n[:type] == 'question' }} questions, #{graph[:nodes].count { |n| n[:type] == 'section' }} sections)"
puts "Edges: #{graph[:edges].count} dependencies"

graph[:edges].each do |edge|
  from_node = graph[:nodes].find { |n| n[:id] == edge[:from] }
  to_node = graph[:nodes].find { |n| n[:id] == edge[:to] }
  puts "  #{from_node[:label][0..30]}... → #{to_node[:label][0..30]}... (#{edge[:label]})"
end

puts "\n=== Validation ==="
integrity_errors = visibility_service.validate_conditional_integrity(session)
if integrity_errors.any?
  puts "Integrity errors found:"
  integrity_errors.each { |error| puts "  ✗ #{error}" }
else
  puts "✓ No integrity errors found"
end

puts "\n=== Cleanup ==="
# Clean up the test session
session.destroy
puts "✓ Cleaned up test session"

# Optionally remove conditions (uncomment to clean up)
# assessment.assessment_questions.conditional.each(&:remove_conditions)
# assessment.assessment_sections.conditional.each(&:remove_conditions)
# puts "✓ Removed all conditional visibility settings"

puts "\n=== Demo Complete ==="
puts "The conditional visibility system is now set up and ready to use!"
puts "You can use the ConditionalVisibilityService to manage conditions in your controllers."
