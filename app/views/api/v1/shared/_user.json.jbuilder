json.id user.id
json.email_address user.email_address
json.first_name user.first_name
json.last_name user.last_name
json.full_name user.full_name
json.display_name user.display_name
json.admin user.admin?
json.profile_completed user.profile_completed?
json.default_language user.default_language

if user.country
  json.country do
    json.partial! "api/v1/shared/country", country: user.country
  end
else
  json.country nil
end

json.created_at user.created_at if user.respond_to?(:created_at)
json.updated_at user.updated_at if user.respond_to?(:updated_at)
