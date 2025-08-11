json.partial! "/api/v1/base"

if @data[:question]
  json.data do
    json.question do
      json.partial! "api/v1/shared/assessment_question", question: @data[:question]
    end

    json.options_count @data[:options_count]

    if @data[:section]
      json.section @data[:section]
    end

    if @data[:assessment]
      json.assessment @data[:assessment]
    end

    if @data[:statistics]
      json.statistics @data[:statistics]
    end
  end
end
