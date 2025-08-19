# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Starting database seeding..."

# Seed Countries
puts "\n🌍 Seeding countries..."
Country.seed_common_countries
puts "✅ Created #{Country.count} countries"

# Create admin user
puts "\n👤 Creating admin user..."
admin_email = "admin@questionnaire.com"
admin = User.find_or_create_by(email_address: admin_email) do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
  user.admin = true
  user.first_name = "Admin"
  user.last_name = "User"
  user.country = Country.find_by(code: "USA")
  user.default_language = "en"
  user.profile_completed = true
end

if admin.persisted?
  puts "✅ Admin user created: #{admin.email_address}"
  puts "   Password: password123"
else
  puts "❌ Failed to create admin user: #{admin.errors.full_messages.join(', ')}"
end

# Create specific UNDP user
puts "\n👤 Creating UNDP user..."
undp_user = User.find_or_create_by(email_address: "dan4allu93@undp.com") do |user|
  user.password = "P@55menow!!"
  user.password_confirmation = "P@55menow!!"
  user.admin = true
  user.first_name = "Dan"
  user.last_name = "Morgan"
  user.country = Country.find_by(code: "USA")
  user.default_language = "en"
  user.profile_completed = true
end

if undp_user.persisted?
  puts "✅ UNDP user created: #{undp_user.email_address}"
  puts "   Password: P@55menow!!"
else
  puts "❌ Failed to create UNDP user: #{undp_user.errors.full_messages.join(', ')}"
end

# Create some regular users
puts "\n👥 Creating regular users..."
regular_users_data = [
  {
    email: "john@example.com",
    first_name: "John",
    last_name: "Doe",
    country_code: "USA",
    language: "en"
  },
  {
    email: "maria@example.com",
    first_name: "Maria",
    last_name: "Garcia",
    country_code: "ESP",
    language: "es"
  },
  {
    email: "pierre@example.com",
    first_name: "Pierre",
    last_name: "Dubois",
    country_code: "FRA",
    language: "fr"
  },
  {
    email: "yuki@example.com",
    first_name: "Yuki",
    last_name: "Tanaka",
    country_code: "JPN",
    language: "ja"
  }
]

regular_users_data.each do |user_data|
  country = Country.find_by(code: user_data[:country_code])
  next unless country

  user = User.find_or_create_by(email_address: user_data[:email]) do |u|
    u.password = "password123"
    u.password_confirmation = "password123"
    u.admin = false
    u.first_name = user_data[:first_name]
    u.last_name = user_data[:last_name]
    u.country = country
    u.default_language = user_data[:language]
    u.profile_completed = true
    u.invited_by = admin
    u.invited_at = 1.week.ago
    u.invitation_accepted_at = 1.day.ago
  end

  if user.persisted?
    puts "✅ Created user: #{user.display_name} (#{user.country.name})"
  end
end

# Clean up existing assessment data if any
puts "\n🧹 Cleaning up existing assessment data..."
AssessmentQuestionMarkingRule.destroy_all
AssessmentMarkingScheme.destroy_all
AssessmentResponseScore.destroy_all
AssessmentResponseSession.destroy_all
AssessmentQuestionResponse.destroy_all
SelectedOption.destroy_all
AssessmentQuestionOption.destroy_all
AssessmentQuestion.destroy_all
AssessmentSection.destroy_all
Assessment.destroy_all

# Create sample assessment with country restrictions
puts "\n📝 Creating sample assessment..."
assessment = Assessment.create!(
  title: "Global Technology Survey",
  description: "A comprehensive survey about technology usage and preferences across different regions.",
  active: true
)

# Section 1: Basic Information (available worldwide)
basic_section = assessment.assessment_sections.create!(
  name: "Basic Information",
  order: 1
)

# Question 1: Age (available worldwide)
age_question = basic_section.assessment_questions.create!(
  assessment: assessment,
  text: { en: "What is your age?", es: "¿Cuál es tu edad?", fr: "Quel est votre âge?", ja: "年齢は何歳ですか？" },
  type: "AssessmentQuestions::RangeType",
  order: 1,
  is_required: true,
  meta_data: { min: 13, max: 100, step: 1 }
)

# Question 2: Tech Experience (available worldwide)
tech_exp_question = basic_section.assessment_questions.build(
  assessment: assessment,
  text: { en: "How would you rate your technology experience?", es: "¿Cómo calificarías tu experiencia tecnológica?", fr: "Comment évalueriez-vous votre expérience technologique?", ja: "技術経験をどのように評価しますか？" },
  type: "AssessmentQuestions::Radio",
  order: 2,
  is_required: true
)

tech_exp_options = [
  { text: { en: "Beginner", es: "Principiante", fr: "Débutant", ja: "初心者" }, order: 1, is_correct_answer: false, points: 1 },
  { text: { en: "Intermediate", es: "Intermedio", fr: "Intermédiaire", ja: "中級者" }, order: 2, is_correct_answer: true, points: 2 },
  { text: { en: "Advanced", es: "Avanzado", fr: "Avancé", ja: "上級者" }, order: 3, is_correct_answer: true, points: 3 },
  { text: { en: "Expert", es: "Experto", fr: "Expert", ja: "専門家" }, order: 4, is_correct_answer: true, points: 4 }
]

tech_exp_options.each do |option_data|
  tech_exp_question.assessment_question_options.build(
    assessment: assessment,
    **option_data
  )
end

tech_exp_question.save!

# Section 2: Regional Technology (restricted in China)
regional_section = assessment.assessment_sections.create!(
  name: "Regional Technology Preferences",
  order: 2
)

# Add country restriction to this section (blocked in China)
regional_section.add_country_restriction("CHN")
regional_section.save!

# Question 3: Social Media Usage (restricted in China)
social_media_question = regional_section.assessment_questions.build(
  assessment: assessment,
  text: { en: "Which social media platforms do you use regularly?", es: "¿Qué plataformas de redes sociales usas regularmente?", fr: "Quelles plateformes de médias sociaux utilisez-vous régulièrement?", ja: "定期的に使用するソーシャルメディアプラットフォームはどれですか？" },
  type: "AssessmentQuestions::MultipleChoice",
  order: 1,
  is_required: false
)

social_media_options = [
  { text: { en: "Facebook", es: "Facebook", fr: "Facebook", ja: "Facebook" }, order: 1, is_correct_answer: false, points: 0 },
  { text: { en: "Twitter/X", es: "Twitter/X", fr: "Twitter/X", ja: "Twitter/X" }, order: 2, is_correct_answer: false, points: 0 },
  { text: { en: "Instagram", es: "Instagram", fr: "Instagram", ja: "Instagram" }, order: 3, is_correct_answer: false, points: 0 },
  { text: { en: "LinkedIn", es: "LinkedIn", fr: "LinkedIn", ja: "LinkedIn" }, order: 4, is_correct_answer: false, points: 0 },
  { text: { en: "TikTok", es: "TikTok", fr: "TikTok", ja: "TikTok" }, order: 5, is_correct_answer: false, points: 0 },
  { text: { en: "None of the above", es: "Ninguna de las anteriores", fr: "Aucune des réponses ci-dessus", ja: "上記のいずれでもない" }, order: 6, is_correct_answer: false, points: 0 }
]

social_media_options.each do |option_data|
  social_media_question.assessment_question_options.build(
    assessment: assessment,
    **option_data
  )
end

social_media_question.save!

# Add country restriction to this question
social_media_question.add_country_restriction("CHN")
social_media_question.save!

# Section 3: Programming Experience (available worldwide)
programming_section = assessment.assessment_sections.create!(
  name: "Programming Experience",
  order: 3
)

# Question 4: Programming Languages (available worldwide)
programming_question = programming_section.assessment_questions.build(
  assessment: assessment,
  text: { en: "Which programming languages are you familiar with?", es: "¿Con qué lenguajes de programación estás familiarizado?", fr: "Avec quels langages de programmation êtes-vous familier?", ja: "どのプログラミング言語に精通していますか？" },
  type: "AssessmentQuestions::MultipleChoice",
  order: 1,
  is_required: false
)

programming_options = [
  { text: { en: "JavaScript", es: "JavaScript", fr: "JavaScript", ja: "JavaScript" }, order: 1, is_correct_answer: true, points: 2 },
  { text: { en: "Python", es: "Python", fr: "Python", ja: "Python" }, order: 2, is_correct_answer: true, points: 3 },
  { text: { en: "Java", es: "Java", fr: "Java", ja: "Java" }, order: 3, is_correct_answer: true, points: 3 },
  { text: { en: "C++", es: "C++", fr: "C++", ja: "C++" }, order: 4, is_correct_answer: true, points: 4 },
  { text: { en: "Ruby", es: "Ruby", fr: "Ruby", ja: "Ruby" }, order: 5, is_correct_answer: true, points: 3 },
  { text: { en: "Go", es: "Go", fr: "Go", ja: "Go" }, order: 6, is_correct_answer: true, points: 4 },
  { text: { en: "Rust", es: "Rust", fr: "Rust", ja: "Rust" }, order: 7, is_correct_answer: true, points: 5 },
  { text: { en: "None", es: "Ninguno", fr: "Aucun", ja: "なし" }, order: 8, is_correct_answer: false, points: 0 }
]

programming_options.each do |option_data|
  programming_question.assessment_question_options.build(
    assessment: assessment,
    **option_data
  )
end

programming_question.save!

# Add conditional visibility: show programming section only if user selected "Intermediate" or higher tech experience
programming_section.add_option_condition(
  tech_exp_question.id,
  tech_exp_question.assessment_question_options.where("(text->'en')::text ILIKE ANY (ARRAY['%Intermediate%', '%Advanced%', '%Expert%'])").pluck(:id),
  'contains'
)
programming_section.save!

# Create a marking scheme
puts "\n🎯 Creating marking scheme..."
marking_scheme = assessment.assessment_marking_schemes.create!(
  name: "Standard Scoring",
  description: "Standard scoring scheme for the technology survey",
  total_possible_score: 100,
  is_active: true,
  settings: {
    passing_score: 60,
    grade_boundaries: {
      'A' => 90,
      'B' => 80,
      'C' => 70,
      'D' => 60,
      'F' => 0
    },
    feedback_templates: {
      'A' => 'Excellent technology knowledge, %{name}! Score: %{score}/%{max_score} (%{percentage}%)',
      'B' => 'Good technology understanding, %{name}. Score: %{score}/%{max_score} (%{percentage}%)',
      'C' => 'Fair technology knowledge, %{name}. Score: %{score}/%{max_score} (%{percentage}%)',
      'D' => 'Basic technology understanding, %{name}. Score: %{score}/%{max_score} (%{percentage}%)',
      'F' => 'Consider learning more about technology, %{name}. Score: %{score}/%{max_score} (%{percentage}%)'
    }
  }
)

# Create marking rules
[age_question, tech_exp_question, social_media_question, programming_question].each_with_index do |question, index|
  rule_type = case question.type
  when "AssessmentQuestions::RangeType"
    "range_based"
  when "AssessmentQuestions::Radio", "AssessmentQuestions::MultipleChoice"
    "option_based"
  else
    "exact_match"
  end

  criteria = case rule_type
  when "range_based"
    { min: 18, max: 65, tolerance: 0 }
  when "option_based"
    { partial_scoring: true, negative_scoring: false, minimum_score: 0 }
  else
    {}
  end

  marking_scheme.assessment_question_marking_rules.create!(
    assessment_question: question,
    rule_type: rule_type,
    points: question.type == "AssessmentQuestions::RangeType" ? 5 : 10,
    criteria: criteria,
    order: index + 1,
    is_active: true
  )
end

puts "✅ Created assessment: #{assessment.title}"
puts "   - #{assessment.assessment_sections.count} sections"
puts "   - #{assessment.assessment_questions.count} questions"
puts "   - #{AssessmentQuestionOption.count} options"
puts "   - 1 marking scheme with #{marking_scheme.assessment_question_marking_rules.count} rules"

# Show country restrictions
restricted_sections = AssessmentSection.with_country_restrictions.count
restricted_questions = AssessmentQuestion.with_country_restrictions.count
puts "   - #{restricted_sections} sections with country restrictions"
puts "   - #{restricted_questions} questions with country restrictions"

puts "\n🎉 Database seeding completed successfully!"
puts "\n📋 Summary:"
puts "   • #{Country.count} countries available"
puts "   • #{User.admins.count} admin user(s)"
puts "   • #{User.regular_users.count} regular user(s)"
puts "   • #{Assessment.count} assessment(s)"
puts "   • #{AssessmentSection.count} section(s)"
puts "   • #{AssessmentQuestion.count} question(s)"
puts "   • #{AssessmentMarkingScheme.count} marking scheme(s)"

puts "\n🔑 Login credentials:"
puts "   Admin: #{admin.email_address} / password123"
puts "   Users: john@example.com, maria@example.com, pierre@example.com, yuki@example.com / password123"

puts "\n🌍 Country restrictions demo:"
puts "   • Users from China (CHN) will not see the 'Regional Technology Preferences' section"
puts "   • The 'Social Media Usage' question is also blocked for Chinese users"
puts "   • Programming section only shows for users with Intermediate+ tech experience"
