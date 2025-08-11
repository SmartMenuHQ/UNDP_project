json.status @status
json.errors @errors
json.notes @notes

json.data do
  json.assessment do
    json.partial! "api/v1/shared/assessment", assessment: @data[:assessment]
  end

  json.user_permissions @data[:user_permissions]

  if @data[:user_session]
    json.user_session do
      json.partial! "api/v1/shared/assessment_response_session", assessment_response_session: @data[:user_session]
    end
  else
    json.user_session nil
  end

  if @data[:visibility_summary]
    json.visibility_summary @data[:visibility_summary]
  else
    json.visibility_summary nil
  end
end
