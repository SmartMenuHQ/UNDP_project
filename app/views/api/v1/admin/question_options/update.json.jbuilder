json.partial! "/api/v1/base"

if @data[:option]
  json.data do
    json.option do
      json.partial! "api/v1/shared/assessment_question_option", option: @data[:option]
    end
  end
end
