# Test script to demonstrate the questionnaire structure and validation

# Create an assessment
assessment = Assessment.create!(
  title: "Sample Assessment",
  description: "A test assessment to demonstrate the structure"
)

# Create a section
section = assessment.assessment_sections.create!(
  name: "General Questions",
  order: 1
)

# Test Multiple Choice Question with options
puts "Testing Multiple Choice Question..."
multiple_choice = AssessmentQuestions::MultipleChoice.create!(
  text: "What is your favorite color?",
  assessment: assessment,
  assessment_section: section,
  order: 1,
  option_attributes: [
    { text: "Red", order: 1, assessment: assessment },
    { text: "Blue", order: 2, assessment: assessment },
    { text: "Green", order: 3, assessment: assessment }
  ]
)

puts "Multiple Choice Question created with #{multiple_choice.option.count} options"

# Test Radio Question with options
puts "\nTesting Radio Question..."
radio = AssessmentQuestions::Radio.create!(
  text: "What is your gender?",
  assessment: assessment,
  assessment_section: section,
  order: 2,
  option_attributes: [
    { text: "Male", order: 1, assessment: assessment },
    { text: "Female", order: 2, assessment: assessment },
    { text: "Other", order: 3, assessment: assessment }
  ]
)

puts "Radio Question created with #{radio.option.count} options"

# Test Boolean Question (should auto-create true/false options)
puts "\nTesting Boolean Question..."
boolean = AssessmentQuestions::BooleanType.create!(
  text: "Do you agree with the terms?",
  assessment: assessment,
  assessment_section: section,
  order: 3
)

puts "Boolean Question created with #{boolean.option.count} options"
boolean.option.each do |opt|
  puts "  - #{opt.text} (order: #{opt.order})"
end

# Test validation - try to create a multiple choice with only one option
puts "\nTesting validation (should fail)..."
begin
  invalid_question = AssessmentQuestions::MultipleChoice.create!(
    text: "Invalid question?",
    assessment: assessment,
    assessment_section: section,
    order: 4,
    option_attributes: [
      { text: "Only one option", order: 1, assessment: assessment }
    ]
  )
rescue ActiveRecord::RecordInvalid => e
  puts "Validation worked! Error: #{e.message}"
end

puts "\nAll tests completed!"
