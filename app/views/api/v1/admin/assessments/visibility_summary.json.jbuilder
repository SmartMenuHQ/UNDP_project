json.status @status
json.errors @errors
json.notes @notes

json.data do
  json.visibility_summary @data[:visibility_summary]
  json.assessment @data[:assessment]

  if @data[:session]
    json.session do
      json.partial! "api/v1/shared/assessment_response_session", assessment_response_session: @data[:session]
    end
  else
    json.session nil
  end
end
