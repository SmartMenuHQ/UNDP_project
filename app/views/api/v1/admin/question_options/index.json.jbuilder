json.partial! "/api/v1/base"

if @data[:options]
  json.data do
    json.options @data[:options] do |option|
      json.partial! "api/v1/shared/assessment_question_option", option: option
    end
    json.total_count @data[:total_count]

    if @data[:question]
      json.question @data[:question]
    end

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
