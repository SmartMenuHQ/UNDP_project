json.partial! "/api/v1/base"

if @data[:option]
  json.data do
    json.option do
      json.partial! "api/v1/shared/assessment_question_option", option: @data[:option]
    end

    json.selection_count @data[:selection_count]
    json.selection_percentage @data[:selection_percentage]

    if @data[:question]
      json.question @data[:question]
    end

    if @data[:section]
      json.section @data[:section]
    end

    if @data[:statistics]
      json.statistics @data[:statistics]
    end
  end
end
