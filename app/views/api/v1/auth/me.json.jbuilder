json.status @status
json.errors @errors
json.notes @notes

json.data do
  if @data[:user]
    json.user do
      json.partial! "api/v1/shared/user", user: @data[:user]
    end
  end

  if @data[:session]
    json.session @data[:session]
  end
end
