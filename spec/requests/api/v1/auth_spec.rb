require "swagger_helper"

RSpec.describe "Api::V1::Auth", type: :request do
  let!(:country_usa) { create(:country, :usa) }
  let!(:user) { create(:user, country: country_usa, email_address: "test@example.com", password: "password123") }
  let!(:admin_user) { create(:user, :admin, country: country_usa, email_address: "admin@example.com", password: "admin123") }

  # Create a valid session for authenticated tests
  let!(:user_session) { user.sessions.create!(ip_address: "127.0.0.1", user_agent: "Test Agent") }
  let(:valid_token) { user_session.token }
  let(:expired_session) do
    session = user.sessions.create!(ip_address: "127.0.0.1", user_agent: "Test Agent")
    session.update_column(:expires_at, 1.day.ago)
    session
  end

  path "/api/v1/auth/login" do
    post "User login" do
      tags "Authentication"
      description "Authenticate user and receive access token"
      consumes "application/json"
      produces "application/json"

      parameter name: :auth, in: :body, description: "User login credentials", schema: {
        type: :object,
        properties: {
          auth: {
            type: :object,
            description: "Authentication credentials object",
            properties: {
              email_address: {
                type: :string,
                format: :email,
                description: "User's registered email address",
                example: "user@example.com",
              },
              password: {
                type: :string,
                minLength: 6,
                description: "User's password (minimum 6 characters)",
                example: "securepassword123",
              },
            },
            required: ["email_address", "password"],
          },
        },
        required: ["auth"],
        example: {
          auth: {
            email_address: "user@example.com",
            password: "securepassword123",
          },
        },
      }

      response "200", "login successful" do
        schema type: :object,
               properties: {
                 status: { type: :string, example: "ok" },
                 data: {
                   type: :object,
                   properties: {
                     user: { "$ref" => "#/components/schemas/User" },
                     session: {
                       type: :object,
                       properties: {
                         token: { type: :string, example: "eyJhbGciOiJIUzI1NiJ9..." },
                         expires_at: { type: :string, format: "date-time", example: "2024-01-08T00:00:00.000Z" },
                       },
                     },
                   },
                 },
                 errors: { type: :array, items: { type: :object } },
                 notes: { type: :array, items: { type: :string }, example: ["Login successful"] },
               },
               examples: {
                 successful_login: {
                   summary: "Successful login with complete profile",
                   value: {
                     status: "ok",
                     data: {
                       user: {
                         id: 1,
                         email: "admin@example.com",
                         first_name: "John",
                         last_name: "Doe",
                         admin: true,
                         profile_completed: true,
                         created_at: "2024-01-01T00:00:00.000Z",
                       },
                       session: {
                         token: "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxLCJleHAiOjE3MDQ2NzIwMDB9...",
                         expires_at: "2024-01-08T00:00:00.000Z",
                       },
                     },
                     errors: [],
                     notes: ["Login successful"],
                   },
                 },
               }

        let(:auth) do
          {
            auth: {
              email_address: user.email_address,
              password: "password123",
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["user"]["email_address"]).to eq(user.email_address)
          expect(data["data"]["session"]["token"]).to be_present
          expect(data["data"]["session"]["expires_at"]).to be_present
          expect(data["notes"]).to include("Login successful")
        end
      end

      response "401", "invalid credentials" do
        schema type: :object,
               properties: {
                 status: { type: :string, example: "error" },
                 data: { type: :object, example: {} },
                 errors: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       error_code: { type: :string, example: "authentication_error" },
                       message: { type: :string, example: "Invalid email or password" },
                       details: { type: :object, example: {} },
                     },
                   },
                 },
                 notes: { type: :array, items: { type: :string } },
               },
               examples: {
                 invalid_credentials: {
                   summary: "Invalid email or password",
                   value: {
                     status: "error",
                     data: {},
                     errors: [{
                       error_code: "authentication_error",
                       message: "Invalid email or password",
                       details: {},
                     }],
                     notes: [],
                   },
                 },
               }
        schema type: :object,
               properties: {
                 status: { type: :string, enum: ["error"] },
                 errors: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       error_code: { type: :string },
                       message: { type: :string },
                       details: { type: :object },
                     },
                   },
                 },
                 data: { type: :object },
                 notes: { type: :array },
               }

        let(:auth) do
          {
            auth: {
              email_address: user.email_address,
              password: "wrong_password",
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authentication_error")
          expect(data["errors"].first["message"]).to eq("Invalid email or password")
        end
      end

      response "422", "incomplete profile" do
        let(:incomplete_user) { create(:user, :incomplete_profile, email_address: "incomplete@example.com", password: "password123") }
        let(:auth) do
          {
            auth: {
              email_address: incomplete_user.email_address,
              password: "password123",
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("validation_error")
          expect(data["errors"].first["details"]["profile_completion_required"]).to be true
        end
      end

      response "401", "missing parameters" do
        let(:auth) do
          {
            auth: {
              email_address: user.email_address,
            # Missing password
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authentication_error")
        end
      end
    end
  end

  path "/api/v1/auth/logout" do
    delete "User logout" do
      tags "Authentication"
      description "Logout user and invalidate current session"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "logout successful" do
        let(:Authorization) { "Bearer #{valid_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["message"]).to eq("Logged out successfully")
          expect(data["notes"]).to include("Logout successful")
        end
      end

      response "401", "unauthorized - no token" do
        let(:Authorization) { nil }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("invalid_token_error")
        end
      end

      response "401", "unauthorized - invalid token" do
        let(:Authorization) { "Bearer invalid_token_error" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("invalid_token_error")
        end
      end

      response "401", "unauthorized - expired token" do
        let(:Authorization) { "Bearer #{expired_session.token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("token_expired_error")
        end
      end
    end
  end

  path "/api/v1/auth/me" do
    get "Get current user" do
      tags "Authentication"
      description "Get current authenticated user information"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "user information retrieved" do
        let(:Authorization) { "Bearer #{valid_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["user"]["email_address"]).to eq(user.email_address)
          expect(data["data"]["session"]["token"]).to eq(valid_token)
        end
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("invalid_token_error")
        end
      end
    end
  end

  path "/api/v1/auth/refresh" do
    post "Refresh token" do
      tags "Authentication"
      description "Refresh the current session token expiration"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "token refreshed" do
        let(:Authorization) { "Bearer #{valid_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["session"]["token"]).to eq(valid_token)
          expect(data["data"]["session"]["expires_at"]).to be_present
          expect(data["notes"]).to include("Token refreshed successfully")
        end
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("invalid_token_error")
        end
      end
    end
  end

  path "/api/v1/auth/logout_all" do
    delete "Logout from all devices" do
      tags "Authentication"
      description "Logout user from all devices by invalidating all sessions"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "logged out from all devices" do
        let(:Authorization) { "Bearer #{valid_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["message"]).to eq("Logged out from all devices")
          expect(data["notes"]).to include("Logged out from all devices")
        end
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("invalid_token_error")
        end
      end
    end
  end
end
