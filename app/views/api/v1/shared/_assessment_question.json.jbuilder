json.id question.id
json.text question.localized_text || ""
json.type question.type
json.question_type question.type
json.question_type_name question.type.demodulize.humanize if question.type
json.sub_type question.sub_type
json.order question.order
json.is_required question.is_required?
json.active question.active?
json.meta_data question.meta_data || {}

# Conditional visibility
json.is_conditional question.is_conditional?
if question.is_conditional?
  json.trigger_question_id question.trigger_question_id
  json.trigger_response_type question.trigger_response_type
  json.trigger_values question.trigger_values
  json.operator question.operator
  json.logic_operator question.logic_operator if question.respond_to?(:logic_operator)
  json.condition_description question.condition_description if question.respond_to?(:condition_description)
end

# Country restrictions
json.has_country_restrictions question.has_country_restrictions?
if question.has_country_restrictions?
  json.restricted_countries question.restricted_countries || []
  json.restricted_country_names question.restricted_country_names if question.respond_to?(:restricted_country_names)
end

# Include options for questions that have them
if question.respond_to?(:assessment_question_options) && question.assessment_question_options.any?
  json.options question.assessment_question_options.order(:order) do |option|
    json.partial! "api/v1/shared/assessment_question_option", option: option
  end
else
  json.options []
end

# Section information
if question.assessment_section
  json.section do
    json.id question.assessment_section.id
    json.name question.assessment_section.name
  end
end

# Timestamps
if question.respond_to?(:created_at)
  json.created_at question.created_at
  json.updated_at question.updated_at
end
