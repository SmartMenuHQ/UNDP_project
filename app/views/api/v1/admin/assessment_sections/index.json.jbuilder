json.partial! "/api/v1/base"

if @data[:sections]
  json.data do
    json.sections @data[:sections] do |section|
      json.partial! "api/v1/shared/assessment_section", section: section
    end
    json.total_count @data[:total_count]

    if @data[:assessment]
      json.assessment @data[:assessment]
    end

    if @data[:pagination]
      json.pagination @data[:pagination]
    end
  end
end
