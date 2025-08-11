json.partial! "api/v1/base"

if @data[:user]
  json.data do
    json.user do
      json.partial! "api/v1/shared/user", user: @data[:user]
    end

    if @data[:invitation_status]
      json.invitation_status do
        json.invited_by do
          json.partial! "api/v1/shared/user", user: @data[:invitation_status][:invited_by]
        end
        json.invited_at @data[:invitation_status][:invited_at]
        json.invitation_accepted_at @data[:invitation_status][:invitation_accepted_at]
      end
    end

    if @data[:statistics]
      json.statistics do
        json.sessions_count @data[:statistics][:sessions_count]
        json.active_sessions_count @data[:statistics][:active_sessions_count]
        json.response_sessions_count @data[:statistics][:response_sessions_count]
      end
    end
  end
end
