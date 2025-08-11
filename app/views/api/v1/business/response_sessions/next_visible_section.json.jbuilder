json.partial! "/api/v1/base"

json.data do
  json.next_section do
    if @data[:next_section]
      json.partial! "/api/v1/shared/assessment_section", section: @data[:next_section]
    else
      json.null!
    end
  end
  json.visible_questions do
    (@data[:visible_questions] || []).each do |question|
      json.partial! "/api/v1/shared/assessment_question", question: question
    end
  end
  if defined?(@meta) && @meta.present?
    json.meta @meta
  end
end
