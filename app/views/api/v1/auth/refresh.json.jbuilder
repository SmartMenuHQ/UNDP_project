json.status @status
json.errors @errors
json.notes @notes

json.data do
  json.session @data[:session] if @data[:session]
end
