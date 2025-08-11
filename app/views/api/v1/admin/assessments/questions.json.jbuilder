json.status @status
json.errors @errors
json.notes @notes

json.data do
  json.questions @data[:questions] do |question|
    json.partial! "api/v1/shared/assessment_question", assessment_question: question
  end

  json.total_count @data[:total_count]
  json.assessment @data[:assessment]
end
