json.partial! "/api/v1/base"

if @data[:question]
  json.data do
    json.question do
      json.partial! "api/v1/shared/assessment_question", question: @data[:question]
    end
  end
end
