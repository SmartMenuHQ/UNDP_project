json.id assessment.id
json.title assessment.title
json.description assessment.description
json.active assessment.active?
json.has_country_restrictions assessment.has_country_restrictions?

if assessment.has_country_restrictions?
  json.restricted_countries assessment.restricted_country_names
else
  json.restricted_countries []
end

json.sections_count assessment.assessment_sections.count
json.questions_count assessment.assessment_questions.count

json.created_at assessment.created_at
json.updated_at assessment.updated_at
