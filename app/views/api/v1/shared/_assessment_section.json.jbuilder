json.id section.id
json.name section.name
json.order section.order
json.metadata section.metadata || {}

# Conditional visibility
json.is_conditional section.is_conditional?
if section.is_conditional?
  json.visibility_conditions section.visibility_conditions || {}
  json.condition_description section.condition_description if section.respond_to?(:condition_description)
end

# Country restrictions
json.has_country_restrictions section.has_country_restrictions?
if section.has_country_restrictions?
  json.restricted_countries section.restricted_countries || []
  json.restricted_country_names section.restricted_country_names if section.respond_to?(:restricted_country_names)
end

# Question counts
json.questions_count section.assessment_questions.count

# Include questions
json.questions section.assessment_questions.ordered do |question|
  json.partial! "api/v1/shared/assessment_question", question: question
end

# Timestamps
if section.respond_to?(:created_at)
  json.created_at section.created_at
  json.updated_at section.updated_at
end
