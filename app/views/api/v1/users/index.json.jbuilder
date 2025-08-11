json.partial! "api/v1/base"

if @data[:users]
  json.data do
    json.users @data[:users] do |user|
      json.partial! "api/v1/shared/user", user: user
    end
    json.total_count @data[:total_count]
    json.admin_count @data[:admin_count]
    json.regular_user_count @data[:regular_user_count]
  end
end
