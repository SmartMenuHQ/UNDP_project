json.id marking_scheme.id
json.name marking_scheme.name
json.description marking_scheme.description
json.is_active marking_scheme.is_active
json.total_possible_score marking_scheme.total_possible_score.to_f

json.settings do
  json.passing_score (marking_scheme.passing_score.nil? ? nil : marking_scheme.passing_score.to_f)
  json.grade_boundaries marking_scheme.grade_boundaries
  json.feedback_templates marking_scheme.feedback_templates
end

json.assessment do
  json.id marking_scheme.assessment_id
end

json.created_at marking_scheme.created_at
json.updated_at marking_scheme.updated_at
