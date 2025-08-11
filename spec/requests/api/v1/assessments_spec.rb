require "swagger_helper"

RSpec.describe "Api::V1::Assessments", type: :request do
  # Test data setup
  let!(:country_usa) { create(:country, :usa) }
  let!(:country_china) { create(:country, :china) }
  let!(:admin_user) { create(:user, :admin, country: country_usa) }
  let!(:regular_user) { create(:user, country: country_usa) }
  let!(:chinese_user) { create(:user, country: country_china) }

  let!(:public_assessment) { create(:assessment, title: "Public Assessment") }
  let!(:restricted_assessment) { create(:assessment, :with_country_restrictions, title: "Restricted Assessment") }

  # Create sessions and tokens for authentication
  let!(:admin_session) { admin_user.sessions.create!(ip_address: "127.0.0.1", user_agent: "Test Agent") }
  let!(:user_session) { regular_user.sessions.create!(ip_address: "127.0.0.1", user_agent: "Test Agent") }
  let!(:chinese_session) { chinese_user.sessions.create!(ip_address: "127.0.0.1", user_agent: "Test Agent") }

  let(:admin_token) { admin_session.token }
  let(:user_token) { user_session.token }
  let(:chinese_token) { chinese_session.token }

  path "/api/v1/assessments" do
    get "List all assessments" do
      tags "Assessments"
      description "Retrieve all assessments accessible to the current user with optional filtering"
      produces "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :page, in: :query, type: :integer, required: false, description: "Page number for pagination (default: 1)", example: 1
      parameter name: :per_page, in: :query, type: :integer, required: false, description: "Items per page (default: 25, max: 100)", example: 25
      parameter name: :search, in: :query, type: :string, required: false, description: "Search by title or description", example: "survey"
      parameter name: :sort_by, in: :query, type: :string, required: false, description: "Sort field (title, created_at)", example: "created_at"
      parameter name: :sort_order, in: :query, type: :string, required: false, description: "Sort direction", enum: ["asc", "desc"], example: "desc"

      response "200", "assessments found" do
        let(:Authorization) { "Bearer #{admin_token}" }

        schema type: :object,
               properties: {
                 status: { type: :string, enum: ["ok", "error", "redirect"] },
                 data: {
                   type: :object,
                   properties: {
                     assessments: {
                       type: :array,
                       items: { "$ref" => "#/components/schemas/Assessment" },
                     },
                     total_count: { type: :integer },
                   },
                 },
                 errors: { type: :array, items: { type: :string } },
                 notes: { type: :array, items: { type: :string } },
               }

        let(:Authorization) { "Bearer #{admin_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["assessments"]).to be_an(Array)
          expect(data["data"]["total_count"]).to be >= 1
          expect(data["notes"]).to include("Assessments retrieved successfully")
        end
      end

      response "401", "unauthorized - no token" do
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
                       message: { type: :string, example: "Authentication required" },
                       details: { type: :object, example: {} },
                     },
                   },
                 },
                 notes: { type: :array, items: { type: :string } },
               },
               examples: {
                 authentication_error: {
                   summary: "No authentication token provided",
                   value: {
                     status: "error",
                     data: {},
                     errors: [{
                       error_code: "authentication_error",
                       message: "Authentication required",
                       details: {},
                     }],
                     notes: [],
                   },
                 },
               }
        let(:Authorization) { nil }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("invalid_token_error")
        end
      end

      response "401", "unauthorized - invalid token" do
        let(:Authorization) { "Bearer invalid_token" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("invalid_token_error")
        end
      end
    end
  end
end
