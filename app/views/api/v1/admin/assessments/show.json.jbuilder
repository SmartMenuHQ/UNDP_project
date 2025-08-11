json.partial! "/api/v1/base"

if @data[:assessment]
  json.data do
    json.assessment do
      json.partial! "api/v1/shared/assessment", assessment: @data[:assessment]
    end
    json.sections_count @data[:sections_count]
    json.questions_count @data[:questions_count]

    if @data[:statistics]
      json.statistics @data[:statistics]
    end
  end
end
