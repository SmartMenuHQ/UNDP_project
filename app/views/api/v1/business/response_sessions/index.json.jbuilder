json.partial! "/api/v1/base"

if @data[:response_sessions]
  json.data do
    json.response_sessions @data[:response_sessions] do |s|
      json.id s.id
      json.state s.state
      json.respondent_name s.respondent_name
      json.started_at s.started_at
      json.completed_at s.completed_at
      json.assessment do
        json.id s.assessment_id
        json.title s.assessment.title
      end
    end
  end
end
