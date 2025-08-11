json.partial! "/api/v1/base"

if @data[:questions]
  json.data do
    json.questions @data[:questions] do |question|
      json.partial! "api/v1/shared/assessment_question", question: question
    end
    json.total_count @data[:total_count]

    if @data[:section]
      json.section @data[:section]
    end

    if @data[:assessment]
      json.assessment @data[:assessment]
    end

    if @data[:pagination]
      json.pagination @data[:pagination]
    end

    if @data[:available_question_types]
      json.available_question_types @data[:available_question_types]
    end
  end
end
