json.partial! "/api/v1/base"

json.data do
  json.section do
    json.partial! "/api/v1/shared/assessment_section", section: @data[:section]
  end
  json.responses do
    (@data[:responses] || []).each do |resp|
      json.child! do
        json.id resp.id
        json.value resp.value
        json.metadata resp.metadata
        json.question do
          json.id resp.assessment_question_id
        end
      end
    end
  end
end
