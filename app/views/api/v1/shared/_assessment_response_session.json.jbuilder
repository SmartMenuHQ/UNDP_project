json.id assessment_response_session.id
json.respondent_name assessment_response_session.respondent_name
json.state assessment_response_session.state
json.started_at assessment_response_session.started_at
json.completed_at assessment_response_session.completed_at
json.submitted_at assessment_response_session.submitted_at
json.marked_at assessment_response_session.marked_at
json.total_score assessment_response_session.total_score
json.max_possible_score assessment_response_session.max_possible_score
json.grade assessment_response_session.grade
json.feedback assessment_response_session.feedback
json.metadata assessment_response_session.metadata

# Score percentage if available
if assessment_response_session.max_possible_score&.positive?
  json.score_percentage assessment_response_session.score_percentage
else
  json.score_percentage nil
end

# User information
json.user do
  json.partial! "api/v1/shared/user", user: assessment_response_session.user
end

# Assessment information
json.assessment do
  json.id assessment_response_session.assessment.id
  json.title assessment_response_session.assessment.title
end

# Completion statistics if session has responses
if assessment_response_session.assessment_question_responses.any?
  completion_stats = assessment_response_session.completion_stats
  json.completion_stats completion_stats
else
  json.completion_stats nil
end

json.created_at assessment_response_session.created_at
json.updated_at assessment_response_session.updated_at
