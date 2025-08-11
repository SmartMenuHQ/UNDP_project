require "swagger_helper"

RSpec.describe "Api::V1::Users", type: :request do
  let!(:country_usa) { create(:country, :usa) }
  let!(:country_china) { create(:country, :china) }

  let!(:admin_user) { create(:user, :admin, country: country_usa) }
  let!(:regular_user) { create(:user, country: country_usa) }
  let!(:chinese_user) { create(:user, :chinese, country: country_china) }

  let!(:admin_session) { create(:session, user: admin_user) }
  let!(:user_session) { create(:session, user: regular_user) }
  let!(:chinese_session) { create(:session, user: chinese_user) }

  let(:admin_token) { admin_session.token }
  let(:user_token) { user_session.token }
  let(:chinese_token) { chinese_session.token }

  path "/api/v1/users/{id}" do
    parameter name: :id, in: :path, type: :integer, description: "User ID"

    get "Get user profile (own profile only)" do
      tags "Users"
      description "Retrieve user profile information (business users can only access their own profile)"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "own profile" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:id) { regular_user.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["user"]["id"]).to eq(regular_user.id)
          expect(data["data"]["user"]["email_address"]).to eq(regular_user.email_address)
          expect(data["notes"]).to include("Business profile retrieved successfully")
        end
      end

      response "403", "forbidden - cannot view other user" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:id) { chinese_user.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_error")
        end
      end

      response "404", "user not found" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:id) { 99999 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("not_found_error")
        end
      end

      response "401", "unauthorized - no token" do
        let(:Authorization) { nil }
        let(:id) { regular_user.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("invalid_token_error")
        end
      end
    end

    patch "Update user profile (own profile only)" do
      tags "Users"
      description "Update user profile information (business users can only update their own profile)"
      produces "application/json"
      consumes "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :user, in: :body, description: "User profile data for update", schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            description: "User profile attributes to update",
            properties: {
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
              password: {
                type: :string,
                description: "New password (minimum 8 characters)",
                example: "newsecurepassword123",
                minLength: 8,
              },
            },
          },
        },
        required: ["user"],
        example: {
          user: {
            first_name: "John",
            last_name: "Doe",
            country_id: 1,
            default_language: "en",
          },
        },
      }

      response "200", "user updated" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:id) { regular_user.id }
        let(:user) do
          {
            user: {
              first_name: "Updated",
              last_name: "Name",
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["user"]["first_name"]).to eq("Updated")
          expect(data["data"]["user"]["last_name"]).to eq("Name")
          expect(data["notes"]).to include("Business profile updated successfully")
        end
      end

      response "403", "forbidden - cannot update other user" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:id) { chinese_user.id }
        let(:user) do
          {
            user: {
              first_name: "Updated",
              last_name: "Name",
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_error")
        end
      end

      response "422", "validation failed" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:id) { regular_user.id }
        let(:user) do
          {
            user: {
              first_name: "", # Invalid - required field when profile is completed
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("validation_error")
        end
      end

      response "401", "unauthorized - no token" do
        let(:Authorization) { nil }
        let(:id) { regular_user.id }
        let(:user) do
          {
            user: {
              first_name: "Updated",
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("invalid_token_error")
        end
      end
    end
  end
end
