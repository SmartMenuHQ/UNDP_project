json.id marking_rule.id
json.rule_type marking_rule.rule_type
json.points marking_rule.points.to_f
json.is_active marking_rule.is_active
json.order marking_rule.order
json.criteria marking_rule.criteria

json.assessment_question do
  json.id marking_rule.assessment_question_id
  json.type marking_rule.assessment_question.type
  json.sub_type marking_rule.assessment_question.sub_type
end

json.marking_scheme do
  json.id marking_rule.assessment_marking_scheme_id
end

json.created_at marking_rule.created_at
json.updated_at marking_rule.updated_at
