json.partial! "api/v1/base"

if @data[:user]
  json.data do
    json.user do
      json.partial! "api/v1/shared/user", user: @data[:user]
    end
  end
end
