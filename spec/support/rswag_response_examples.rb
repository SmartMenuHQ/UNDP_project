# frozen_string_literal: true

# Attach real response bodies as Swagger examples for documented request specs
RSpec.configure do |config|
  config.after(type: :request) do |example|
    # Only add examples when rswag is generating docs and the example defines a response
    if example.metadata[:operation] && example.metadata[:response]
      begin
        # Only proceed if `response` is a real ActionDispatch::TestResponse
        if defined?(response) && response.respond_to?(:body) && response.respond_to?(:code)
          body = response.body
          json = body.present? ? JSON.parse(body, symbolize_names: true) : nil
          if json
            example.metadata[:response][:content] ||= {}
            example.metadata[:response][:content]["application/json"] ||= {}
            example.metadata[:response][:content]["application/json"][:example] = json
          end
        end
      rescue JSON::ParserError
        # Ignore non-JSON responses
      end
    end
  end
end
