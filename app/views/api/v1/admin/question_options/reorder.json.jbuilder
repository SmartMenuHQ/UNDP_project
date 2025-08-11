json.partial! "/api/v1/base"

if @data[:options]
  json.data do
    json.options @data[:options] do |option|
      json.partial! "api/v1/shared/assessment_question_option", option: option
    end
    json.reordered_count @data[:reordered_count]
  end
end
