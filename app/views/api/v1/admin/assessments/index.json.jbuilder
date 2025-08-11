json.partial! "/api/v1/base"

if @data[:assessments]
  json.data do
    json.assessments @data[:assessments] do |assessment|
      json.partial! "api/v1/shared/assessment", assessment: assessment
    end
    json.total_count @data[:total_count]
    json.active_count @data[:active_count]
    json.inactive_count @data[:inactive_count]
  end
end
