json.partial! "/api/v1/base"

if @data[:response_session]
  json.data do
    json.response_session do
      json.id @data[:response_session].id
      json.state @data[:response_session].state
      json.respondent_name @data[:response_session].respondent_name
      json.started_at @data[:response_session].started_at
      json.completed_at @data[:response_session].completed_at
      json.submitted_at @data[:response_session].submitted_at
      json.marked_at @data[:response_session].marked_at
      json.total_score (@data[:response_session].total_score.nil? ? nil : @data[:response_session].total_score.to_f)
      json.max_possible_score (@data[:response_session].max_possible_score.nil? ? nil : @data[:response_session].max_possible_score.to_f)
      json.grade @data[:response_session].grade
      json.feedback @data[:response_session].feedback
      json.metadata @data[:response_session].metadata
      json.assessment do
        json.id @data[:response_session].assessment_id
        json.title @data[:response_session].assessment.title
      end
    end
    if defined?(@meta) && @meta.present?
      json.meta @meta
    end
  end
end
