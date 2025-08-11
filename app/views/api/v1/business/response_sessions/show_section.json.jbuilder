json.partial! "/api/v1/base"

json.data do
  json.section do
    json.partial! "/api/v1/shared/assessment_section", section: @data[:section]
    json.questions do
      json.array! Array(@data[:questions]) do |question|
        json.partial! "/api/v1/shared/assessment_question", question: question
      end
    end
  end
end
