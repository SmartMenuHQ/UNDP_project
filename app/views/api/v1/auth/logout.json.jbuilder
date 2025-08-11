json.status @status
json.errors @errors
json.notes @notes

json.data do
  json.message @data[:message] if @data[:message]
end
