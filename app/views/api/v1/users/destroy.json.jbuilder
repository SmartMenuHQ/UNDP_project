json.partial! "api/v1/base"

if @data[:deleted_id]
  json.data do
    json.deleted_id @data[:deleted_id]
  end
end
