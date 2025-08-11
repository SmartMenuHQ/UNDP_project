#!/usr/bin/env ruby

# Sample Assessment Creation Script
# This creates a comprehensive assessment with all question types and marking schemes

puts "🚀 Creating comprehensive sample assessment..."

# Create the main assessment
assessment = Assessment.find_or_create_by(title: 'Comprehensive Skills Assessment') do |a|
  a.description = 'A complete assessment demonstrating all question types with proper marking schemes'
  a.active = true
end

puts "✅ Assessment created: #{assessment.title} (ID: #{assessment.id})"

# Create sections for different categories
sections = [
  { name: 'Multiple Choice Questions' },
  { name: 'Text and Input Questions' },
  { name: 'Interactive Questions' },
  { name: 'Boolean Questions' }
]

created_sections = []
sections.each_with_index do |section_data, index|
  section = assessment.assessment_sections.find_or_create_by(name: section_data[:name]) do |s|
    s.order = index + 1
  end
  created_sections << section
  puts "  📁 Section: #{section.name}"
end

# Question templates with all types and sub-types
question_templates = [
  # Multiple Choice Questions
  {
    section: 0,
    type: 'AssessmentQuestions::MultipleChoice',
    sub_type: 'checkboxes',
    text: 'Which programming languages are object-oriented? (Select all that apply)',
    is_required: true,
    options: [
      { text: 'Java', points: 2, is_correct: true },
      { text: 'Python', points: 2, is_correct: true },
      { text: 'C', points: 0, is_correct: false },
      { text: 'JavaScript', points: 2, is_correct: true },
      { text: 'Assembly', points: 0, is_correct: false }
    ]
  },
  {
    section: 0,
    type: 'AssessmentQuestions::MultipleChoice',
    sub_type: 'dropdown',
    text: 'What is the capital of France?',
    is_required: true,
    options: [
      { text: 'London', points: 0, is_correct: false },
      { text: 'Berlin', points: 0, is_correct: false },
      { text: 'Paris', points: 5, is_correct: true },
      { text: 'Madrid', points: 0, is_correct: false }
    ]
  },
  {
    section: 0,
    type: 'AssessmentQuestions::MultipleChoice',
    sub_type: 'tags',
    text: 'Select the web development technologies:',
    is_required: true,
    options: [
      { text: 'HTML', points: 1, is_correct: true },
      { text: 'CSS', points: 1, is_correct: true },
      { text: 'JavaScript', points: 1, is_correct: true },
      { text: 'Photoshop', points: 0, is_correct: false },
      { text: 'Excel', points: 0, is_correct: false }
    ]
  },

  # Radio Questions
  {
    section: 0,
    type: 'AssessmentQuestions::Radio',
    sub_type: 'horizontal',
    text: 'Which HTTP status code indicates "Not Found"?',
    is_required: true,
    options: [
      { text: '200', points: 0, is_correct: false },
      { text: '404', points: 3, is_correct: true },
      { text: '500', points: 0, is_correct: false },
      { text: '302', points: 0, is_correct: false }
    ]
  },
  {
    section: 0,
    type: 'AssessmentQuestions::Radio',
    sub_type: 'vertical',
    text: 'What does SQL stand for?',
    is_required: true,
    options: [
      { text: 'Structured Query Language', points: 4, is_correct: true },
      { text: 'Simple Query Language', points: 0, is_correct: false },
      { text: 'Standard Query Language', points: 0, is_correct: false },
      { text: 'System Query Language', points: 0, is_correct: false }
    ]
  },

  # Rich Text Questions
  {
    section: 1,
    type: 'AssessmentQuestions::RichText',
    sub_type: 'essay',
    text: 'Explain the concept of object-oriented programming and provide examples of its key principles.',
    is_required: true,
    meta_data: { max_words: 500, min_words: 100 }
  },
  {
    section: 1,
    type: 'AssessmentQuestions::RichText',
    sub_type: 'short_answer',
    text: 'What is the difference between GET and POST HTTP methods?',
    is_required: true,
    meta_data: { max_words: 100, min_words: 20 }
  },
  {
    section: 1,
    type: 'AssessmentQuestions::RichText',
    sub_type: 'paragraph',
    text: 'Describe your experience with database design and optimization.',
    is_required: false,
    meta_data: { max_words: 300, min_words: 50 }
  },

  # Date Questions
  {
    section: 2,
    type: 'AssessmentQuestions::DateType',
    sub_type: 'date_only',
    text: 'When did you start learning programming?',
    is_required: false,
    meta_data: { min_date: '2000-01-01', max_date: Date.current.to_s }
  },
  {
    section: 2,
    type: 'AssessmentQuestions::DateType',
    sub_type: 'datetime',
    text: 'What date and time would be best for a technical interview?',
    is_required: true,
    meta_data: { min_date: Date.current.to_s, max_date: (Date.current + 30.days).to_s }
  },

  # Range Questions
  {
    section: 2,
    type: 'AssessmentQuestions::RangeType',
    sub_type: 'slider',
    text: 'Rate your confidence level in JavaScript (1-10):',
    is_required: true,
    meta_data: { min_value: 1, max_value: 10, step: 1, default_value: 5 }
  },
  {
    section: 2,
    type: 'AssessmentQuestions::RangeType',
    sub_type: 'number_input',
    text: 'How many years of programming experience do you have?',
    is_required: true,
    meta_data: { min_value: 0, max_value: 50, step: 0.5, default_value: 0 }
  },

  # Boolean Questions
  {
    section: 3,
    type: 'AssessmentQuestions::BooleanType',
    sub_type: 'true_false',
    text: 'JavaScript is a compiled language.',
    is_required: true,
    options: [
      { text: 'True', points: 0, is_correct: false },
      { text: 'False', points: 2, is_correct: true }
    ]
  },
  {
    section: 3,
    type: 'AssessmentQuestions::BooleanType',
    sub_type: 'yes_no',
    text: 'Do you have experience with version control systems like Git?',
    is_required: true,
    options: [
      { text: 'Yes', points: 1, is_correct: true },
      { text: 'No', points: 0, is_correct: false }
    ]
  },
  {
    section: 3,
    type: 'AssessmentQuestions::BooleanType',
    sub_type: 'checkbox',
    text: 'I agree to the terms and conditions of this assessment.',
    is_required: true,
    options: [
      { text: 'I agree', points: 0, is_correct: true }
    ]
  }
]

# Create questions
created_questions = []
question_templates.each_with_index do |template, index|
  section = created_sections[template[:section]]

  question = section.assessment_questions.create!(
    type: template[:type],
    sub_type: template[:sub_type],
    text: template[:text],
    is_required: template[:is_required],
    order: index + 1,
    assessment_id: assessment.id,
    meta_data: template[:meta_data] || {}
  )

  # Create options for questions that need them
  if template[:options]
    template[:options].each_with_index do |option_data, opt_index|
      question.option.create!(
        text: option_data[:text],
        order: opt_index + 1,
        points: option_data[:points],
        is_correct_answer: option_data[:is_correct]
      )
    end
  end

  created_questions << question
  puts "    ❓ Question: #{template[:text][0..50]}... (#{template[:type].split('::').last}/#{template[:sub_type]})"
end

# Create comprehensive marking scheme
marking_scheme = assessment.assessment_marking_schemes.create!(
  name: 'Comprehensive Marking Scheme',
  description: 'Complete marking scheme covering all question types with detailed criteria',
  total_possible_score: 50,
  is_active: true,
  settings: {
    'passing_score' => 70,
    'grade_boundaries' => {
      'A+' => 95,
      'A' => 90,
      'A-' => 85,
      'B+' => 80,
      'B' => 75,
      'B-' => 70,
      'C+' => 65,
      'C' => 60,
      'C-' => 55,
      'D' => 50,
      'F' => 0
    },
    'feedback_templates' => {
      'A+' => 'Outstanding performance, %{name}! You scored %{score}/%{max_score} (%{percentage}%). Excellent mastery of all concepts.',
      'A' => 'Excellent work, %{name}! You scored %{score}/%{max_score} (%{percentage}%). Strong understanding demonstrated.',
      'A-' => 'Very good performance, %{name}! You scored %{score}/%{max_score} (%{percentage}%). Well done overall.',
      'B+' => 'Good work, %{name}! You scored %{score}/%{max_score} (%{percentage}%). Solid understanding shown.',
      'B' => 'Good job, %{name}! You scored %{score}/%{max_score} (%{percentage}%). Good grasp of the material.',
      'B-' => 'Satisfactory performance, %{name}. You scored %{score}/%{max_score} (%{percentage}%). Room for improvement.',
      'C+' => 'Fair performance, %{name}. You scored %{score}/%{max_score} (%{percentage}%). Consider reviewing key concepts.',
      'C' => 'Acceptable work, %{name}. You scored %{score}/%{max_score} (%{percentage}%). Additional study recommended.',
      'C-' => 'Below average, %{name}. You scored %{score}/%{max_score} (%{percentage}%). Please review the material.',
      'D' => 'Poor performance, %{name}. You scored %{score}/%{max_score} (%{percentage}%). Significant improvement needed.',
      'F' => 'Unsatisfactory, %{name}. You scored %{score}/%{max_score} (%{percentage}%). Please retake after studying.'
    }
  }
)

puts "✅ Marking scheme created: #{marking_scheme.name}"

# Create marking rules for each question
marking_rules_data = [
  # Multiple choice questions - option based
  { rule_type: 'option_based', points: 6, criteria: { 'correct_options_required' => true, 'partial_credit' => true } },
  { rule_type: 'option_based', points: 5, criteria: { 'correct_options_required' => true, 'partial_credit' => false } },
  { rule_type: 'option_based', points: 3, criteria: { 'correct_options_required' => true, 'partial_credit' => true } },
  { rule_type: 'option_based', points: 3, criteria: { 'correct_options_required' => true, 'partial_credit' => false } },
  { rule_type: 'option_based', points: 4, criteria: { 'correct_options_required' => true, 'partial_credit' => false } },

  # Rich text questions - content analysis
  { rule_type: 'content_analysis', points: 8, criteria: { 'min_word_count' => 100, 'max_word_count' => 500, 'keywords' => ['object-oriented', 'encapsulation', 'inheritance', 'polymorphism'] } },
  { rule_type: 'content_analysis', points: 4, criteria: { 'min_word_count' => 20, 'max_word_count' => 100, 'keywords' => ['GET', 'POST', 'HTTP'] } },
  { rule_type: 'content_analysis', points: 3, criteria: { 'min_word_count' => 50, 'max_word_count' => 300, 'keywords' => ['database', 'design', 'optimization'] } },

  # Date questions - range based
  { rule_type: 'range_based', points: 2, criteria: { 'min_date' => '2000-01-01', 'max_date' => Date.current.to_s } },
  { rule_type: 'range_based', points: 2, criteria: { 'min_date' => Date.current.to_s, 'max_date' => (Date.current + 30.days).to_s } },

  # Range questions - range based
  { rule_type: 'range_based', points: 2, criteria: { 'min_value' => 1, 'max_value' => 10, 'target_range' => [5, 10] } },
  { rule_type: 'range_based', points: 3, criteria: { 'min_value' => 0, 'max_value' => 50, 'points_per_year' => 0.2 } },

  # Boolean questions - option based
  { rule_type: 'option_based', points: 2, criteria: { 'correct_options_required' => true } },
  { rule_type: 'option_based', points: 1, criteria: { 'correct_options_required' => true } },
  { rule_type: 'option_based', points: 0, criteria: { 'correct_options_required' => true } }
]

created_questions.each_with_index do |question, index|
  rule_data = marking_rules_data[index]

  marking_rule = marking_scheme.assessment_question_marking_rules.create!(
    assessment_question: question,
    rule_type: rule_data[:rule_type],
    points: rule_data[:points],
    order: index + 1,
    is_active: true,
    criteria: rule_data[:criteria]
  )

  puts "    📏 Marking rule: #{rule_data[:rule_type]} (#{rule_data[:points]} points)"
end

# Create sample response sessions
sample_respondents = [
  { name: 'Alice Johnson', email: 'alice@example.com', state: 'draft' },
  { name: 'Bob Smith', email: 'bob@example.com', state: 'started' },
  { name: 'Carol Davis', email: 'carol@example.com', state: 'completed' },
  { name: 'David Wilson', email: 'david@example.com', state: 'submitted' },
  { name: 'Eva Brown', email: 'eva@example.com', state: 'marked' }
]

sample_respondents.each do |respondent_data|
  session = assessment.assessment_response_sessions.create!(
    respondent_name: respondent_data[:name],
    respondent_email: respondent_data[:email],
    state: respondent_data[:state],
    metadata: {
      'browser_info' => 'Chrome on macOS',
      'ip_address' => '192.168.1.100',
      'session_data' => 'Sample test session'
    }
  )

  # Add some timestamps based on state
  case respondent_data[:state]
  when 'started'
    session.update!(started_at: 1.hour.ago)
  when 'completed'
    session.update!(started_at: 2.hours.ago, completed_at: 1.hour.ago)
  when 'submitted'
    session.update!(started_at: 3.hours.ago, completed_at: 2.hours.ago, submitted_at: 1.hour.ago)
  when 'marked'
    session.update!(
      started_at: 4.hours.ago,
      completed_at: 3.hours.ago,
      submitted_at: 2.hours.ago,
      marked_at: 1.hour.ago,
      total_score: 35,
      max_possible_score: 50,
      grade: 'B',
      feedback: 'Good work! You demonstrated solid understanding of most concepts.'
    )
  end

  puts "  👤 Sample respondent: #{respondent_data[:name]} (#{respondent_data[:state]})"
end

puts "\n🎉 Sample assessment creation completed!"
puts "\n📊 Summary:"
puts "  • Assessment: #{assessment.title}"
puts "  • Sections: #{created_sections.count}"
puts "  • Questions: #{created_questions.count} (covering all question types)"
puts "  • Marking Rules: #{marking_rules_data.count}"
puts "  • Sample Sessions: #{sample_respondents.count}"

puts "\n🌐 Access URLs:"
puts "  • Assessment List: http://localhost:3000/assessments"
puts "  • Assessment Details: http://localhost:3000/assessments/#{assessment.id}"
puts "  • Marking Schemes: http://localhost:3000/assessments/#{assessment.id}/marking_schemes"
puts "  • Response Sessions: http://localhost:3000/assessments/#{assessment.id}/response_sessions"
puts "  • Analytics: http://localhost:3000/assessments/#{assessment.id}/response_sessions/analytics"

puts "\n✨ The assessment includes:"
puts "  • Multiple Choice (checkboxes, dropdown, tags)"
puts "  • Radio buttons (horizontal, vertical)"
puts "  • Rich Text (essay, short answer, paragraph)"
puts "  • Date inputs (date only, datetime)"
puts "  • Range inputs (slider, number input)"
puts "  • Boolean questions (true/false, yes/no, checkbox)"
puts "  • Comprehensive marking scheme with all rule types"
puts "  • Sample response sessions in various states"
