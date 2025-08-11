json.status @status
json.errors @errors
json.notes @notes

json.data do
  json.deleted_id @data[:deleted_id] if @data[:deleted_id]
end
