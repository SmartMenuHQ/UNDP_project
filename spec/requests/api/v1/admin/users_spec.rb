require "swagger_helper"

RSpec.describe "Api::V1::Admin::Users", type: :request do
  let!(:country_usa) { create(:country, :usa) }
  let!(:country_china) { create(:country, :china) }

  let!(:admin_user) { create(:user, :admin, country: country_usa) }
  let!(:regular_user) { create(:user, country: country_usa) }
  let!(:chinese_user) { create(:user, :chinese, country: country_china) }

  # Create sessions for authentication
  let!(:admin_session) { admin_user.sessions.create!(ip_address: "127.0.0.1", user_agent: "Test Agent") }
  let!(:user_session) { regular_user.sessions.create!(ip_address: "127.0.0.1", user_agent: "Test Agent") }
  let!(:chinese_session) { chinese_user.sessions.create!(ip_address: "127.0.0.1", user_agent: "Test Agent") }

  let(:admin_token) { admin_session.token }
  let(:user_token) { user_session.token }
  let(:chinese_token) { chinese_session.token }

  path "/api/v1/admin/users" do
    get "List all users" do
      tags "Users"
      description "Retrieve all users with optional filtering and pagination (admin only)"
      produces "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :page, in: :query, type: :integer, required: false, description: "Page number for pagination (default: 1)", example: 1
      parameter name: :per_page, in: :query, type: :integer, required: false, description: "Items per page (default: 25, max: 100)", example: 25
      parameter name: :admin, in: :query, type: :boolean, required: false, description: "Filter by admin status", example: false
      parameter name: :country_id, in: :query, type: :integer, required: false, description: "Filter by country ID", example: 1
      parameter name: :search, in: :query, type: :string, required: false, description: "Search by name or email", example: "john"
      parameter name: :sort_by, in: :query, type: :string, required: false, description: "Sort field (created_at, email_address, last_name)", example: "created_at"
      parameter name: :sort_order, in: :query, type: :string, required: false, description: "Sort direction (asc, desc)", enum: ["asc", "desc"], example: "desc"

      response "200", "users found" do
        let(:Authorization) { "Bearer #{admin_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["users"]).to be_an(Array)
          expect(data["data"]["total_count"]).to be_a(Integer)
          expect(data["data"]["admin_count"]).to be_a(Integer)
          expect(data["data"]["business_count"]).to be_a(Integer)
          expect(data["notes"]).to include("Users retrieved successfully")
        end
      end

      response "403", "forbidden - not admin" do
        let(:Authorization) { "Bearer #{user_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_error")
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
    end

    post "Create a new user" do
      tags "Users"
      description "Create a new user (admin only)"
      produces "application/json"
      consumes "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :user, in: :body, description: "User data for creation", schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            description: "User attributes",
            properties: {
              email_address: {
                type: :string,
                format: :email,
                description: "User's email address (must be unique)",
                example: "newuser@example.com",
                maxLength: 255,
              },
              password: {
                type: :string,
                description: "User's password (minimum 8 characters)",
                example: "securepassword123",
                minLength: 8,
              },
              first_name: {
                type: :string,
                description: "User's first name",
                example: "John",
                maxLength: 50,
              },
              last_name: {
                type: :string,
                description: "User's last name",
                example: "Doe",
                maxLength: 50,
              },
              country_id: {
                type: :integer,
                description: "ID of user's country (must exist)",
                example: 1,
              },
              default_language: {
                type: :string,
                description: "User's preferred language",
                enum: %w[en es fr it ja],
                example: "en",
              },
              admin: {
                type: :boolean,
                description: "Whether to grant admin privileges",
                example: false,
              },
            },
            required: %w[email_address password first_name last_name country_id],
          },
        },
        required: ["user"],
        example: {
          user: {
            email_address: "newuser@example.com",
            password: "securepassword123",
            first_name: "John",
            last_name: "Doe",
            country_id: 1,
            default_language: "en",
            admin: false,
          },
        },
      }

      response "200", "user created" do
        schema type: :object,
               properties: {
                 status: { type: :string, example: "ok" },
                 data: {
                   type: :object,
                   properties: {
                     user: { "$ref" => "#/components/schemas/User" },
                   },
                 },
                 errors: { type: :array, items: { type: :object } },
                 notes: { type: :array, items: { type: :string }, example: ["User created successfully"] },
               },
               examples: {
                 user_created: {
                   summary: "New user created successfully",
                   value: {
                     status: "ok",
                     data: {
                       user: {
                         id: 2,
                         email: "newuser@example.com",
                         first_name: "Jane",
                         last_name: "Smith",
                         admin: false,
                         profile_completed: false,
                         invited_by_id: 1,
                         invited_at: "2024-01-01T00:00:00.000Z",
                         created_at: "2024-01-01T00:00:00.000Z",
                       },
                     },
                     errors: [],
                     notes: ["User created successfully"],
                   },
                 },
               }
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:user) do
          {
            user: {
              email_address: "newuser@example.com",
              password: "password123",
              first_name: "John",
              last_name: "Doe",
              country_id: country_usa.id,
              default_language: "en",
              admin: false,
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["user"]["email_address"]).to eq("newuser@example.com")
          expect(data["data"]["user"]["admin"]).to eq(false)
          expect(data["notes"]).to include("User created successfully")
        end
      end

      response "422", "validation failed" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:user) do
          {
            user: {
              email_address: "",
              password: "short",
              first_name: "",
              last_name: "",
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("validation_error")
        end
      end

      response "403", "forbidden - not admin" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:user) do
          {
            user: {
              email_address: "newuser@example.com",
              password: "password123",
              first_name: "John",
              last_name: "Doe",
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_error")
        end
      end
    end
  end

  path "/api/v1/admin/users/{id}" do
    parameter name: :id, in: :path, type: :integer, description: "User ID"

    get "Show a user" do
      tags "Users"
      description "Retrieve a specific user"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "user found" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:id) { regular_user.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["user"]["id"]).to eq(regular_user.id)
          expect(data["data"]["user"]["email_address"]).to eq(regular_user.email_address)
          expect(data["notes"]).to include("User retrieved successfully")
        end
      end

      response "200", "admin viewing any user" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:id) { regular_user.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["user"]["id"]).to eq(regular_user.id)
        end
      end

      response "403", "forbidden - cannot view other user" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:id) { admin_user.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_error")
        end
      end

      response "404", "user not found" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:id) { 99999 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("not_found_error")
        end
      end
    end

    patch "Update a user" do
      tags "Users"
      description "Update a user"
      produces "application/json"
      consumes "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              first_name: { type: :string, example: "Jane" },
              last_name: { type: :string, example: "Smith" },
              country_id: { type: :integer, example: 1 },
              default_language: { type: :string, example: "es" },
              password: { type: :string, example: "newpassword123" },
            },
          },
        },
        required: ["user"],
      }

      response "200", "user updated" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:id) { regular_user.id }
        let(:user) do
          {
            user: {
              first_name: "Jane",
              last_name: "Smith",
              default_language: "es",
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["user"]["first_name"]).to eq("Jane")
          expect(data["data"]["user"]["last_name"]).to eq("Smith")
          expect(data["notes"]).to include("User updated successfully")
        end
      end

      response "403", "forbidden - cannot update other user" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:id) { admin_user.id }
        let(:user) do
          {
            user: {
              first_name: "Hacker",
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_error")
        end
      end
    end

    delete "Delete a user" do
      tags "Users"
      description "Delete a user (admin only)"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "user deleted" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let!(:user_to_delete) { create(:user, country: country_usa) }
        let(:id) { user_to_delete.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["deleted_id"]).to eq(user_to_delete.id)
          expect(data["notes"]).to include("User deleted successfully")
        end
      end

      response "403", "cannot delete own account" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:id) { admin_user.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_failed")
        end
      end

      response "403", "forbidden - not admin" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:id) { chinese_user.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_error")
        end
      end
    end
  end

  path "/api/v1/admin/users/invite" do
    post "Invite a new user" do
      tags "Users"
      description "Send an invitation to a new user (admin only)"
      produces "application/json"
      consumes "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              email_address: { type: :string, example: "invited@example.com" },
              first_name: { type: :string, example: "Invited" },
              last_name: { type: :string, example: "User" },
              country_id: { type: :integer, example: 1 },
              default_language: { type: :string, example: "en" },
              admin: { type: :boolean, example: false },
              send_email: { type: :boolean, example: true },
            },
            required: %w[email_address first_name last_name],
          },
        },
        required: ["user"],
      }

      response "200", "invitation sent" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:user) do
          {
            user: {
              email_address: "invited@example.com",
              password: "password123",
              first_name: "Invited",
              last_name: "User",
              country_id: country_usa.id,
              default_language: "en",
              admin: false,
              send_email: true,
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["user"]["email_address"]).to eq("invited@example.com")
          expect(data["data"]["invitation_sent"]).to eq(true)
          expect(data["notes"]).to include("User invitation sent successfully")
        end
      end

      response "403", "forbidden - not admin" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:user) do
          {
            user: {
              email_address: "invited@example.com",
              first_name: "Invited",
              last_name: "User",
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_error")
        end
      end
    end
  end

  path "/api/v1/admin/users/{id}/make_admin" do
    parameter name: :id, in: :path, type: :integer, description: "User ID"

    patch "Promote user to admin" do
      tags "Users"
      description "Give admin privileges to a user (admin only)"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "user promoted to admin" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:id) { regular_user.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["user"]["admin"]).to eq(true)
          expect(data["notes"]).to include("User promoted to admin successfully")
        end
      end

      response "403", "forbidden - not admin" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:id) { chinese_user.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_error")
        end
      end
    end
  end

  path "/api/v1/admin/users/{id}/remove_admin" do
    parameter name: :id, in: :path, type: :integer, description: "User ID"

    patch "Remove admin privileges" do
      tags "Users"
      description "Remove admin privileges from a user (admin only)"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "admin privileges removed" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let!(:another_admin) { create(:user, :admin, country: country_usa) }
        let(:id) { another_admin.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["user"]["admin"]).to eq(false)
          expect(data["notes"]).to include("Admin privileges removed successfully")
        end
      end

      response "403", "cannot remove own admin privileges" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:id) { admin_user.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_failed")
        end
      end

      response "403", "forbidden - not admin" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:id) { admin_user.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_error")
        end
      end
    end
  end
end
