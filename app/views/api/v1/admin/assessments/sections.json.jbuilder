json.status @status
json.errors @errors
json.notes @notes

json.data do
  json.sections @data[:sections] do |section|
    json.partial! "api/v1/shared/assessment_section", section: section
  end

  json.total_count @data[:total_count]
  json.assessment @data[:assessment]
end
