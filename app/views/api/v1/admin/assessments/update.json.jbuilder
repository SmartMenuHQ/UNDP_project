json.status @status
json.errors @errors
json.notes @notes

json.data do
  if @data[:assessment]
    json.assessment do
      json.partial! "api/v1/shared/assessment", assessment: @data[:assessment]
    end
  end
end
