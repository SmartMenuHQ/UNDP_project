json.status @status
json.errors @errors
json.notes @notes

json.data do
  json.assessments @data[:assessments] do |assessment|
    json.partial! "api/v1/shared/assessment", assessment: assessment
  end

  json.total_count @data[:total_count]
  json.user_can_create @data[:user_can_create]
end
