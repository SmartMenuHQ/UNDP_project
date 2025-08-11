require "swagger_helper"

RSpec.describe "Api::V1::Admin::Assessments", type: :request do
  let!(:country_usa) { create(:country, :usa) }
  let!(:country_china) { create(:country, :china) }

  let!(:admin_user) { create(:user, :admin, country: country_usa) }
  let!(:regular_user) { create(:user, country: country_usa) }

  let!(:admin_session) { create(:session, user: admin_user) }
  let!(:user_session) { create(:session, user: regular_user) }

  let(:admin_token) { admin_session.token }
  let(:user_token) { user_session.token }

  let!(:public_assessment) { create(:assessment, title: "Public Assessment") }
  let!(:restricted_assessment) { create(:assessment, :with_country_restrictions, title: "Restricted Assessment") }

  path "/api/v1/admin/assessments" do
    get "List all assessments (admin)" do
      tags "Admin - Assessments"
      description "Retrieve all assessments with admin statistics and optional filtering (admin only)"
      produces "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :page, in: :query, type: :integer, required: false, description: "Page number for pagination (default: 1)", example: 1
      parameter name: :per_page, in: :query, type: :integer, required: false, description: "Items per page (default: 25, max: 100)", example: 25
      parameter name: :active, in: :query, type: :boolean, required: false, description: "Filter by active status", example: true
      parameter name: :has_country_restrictions, in: :query, type: :boolean, required: false, description: "Filter by country restrictions", example: false
      parameter name: :search, in: :query, type: :string, required: false, description: "Search by title or description", example: "survey"
      parameter name: :sort_by, in: :query, type: :string, required: false, description: "Sort field (title, created_at, updated_at)", example: "created_at"
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
                     active_count: { type: :integer },
                     inactive_count: { type: :integer },
                   },
                 },
                 errors: { type: :array, items: { type: :string } },
                 notes: { type: :array, items: { type: :string } },
               }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["assessments"]).to be_an(Array)
          expect(data["data"]["total_count"]).to be_a(Integer)
          expect(data["data"]["active_count"]).to be_a(Integer)
          expect(data["data"]["inactive_count"]).to be_a(Integer)
          expect(data["notes"]).to include("Assessments retrieved successfully")
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

    post "Create a new assessment (admin)" do
      tags "Admin - Assessments"
      description "Create a new assessment (admin only)"
      produces "application/json"
      consumes "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :assessment, in: :body, description: "Assessment data for creation", schema: {
        type: :object,
        properties: {
          assessment: {
            type: :object,
            description: "Assessment attributes",
            properties: {
              title: {
                type: :string,
                description: "Assessment title (must be unique)",
                example: "Customer Satisfaction Survey",
                maxLength: 200,
              },
              description: {
                type: :string,
                description: "Detailed description of the assessment purpose and content",
                example: "A comprehensive survey to measure customer satisfaction levels across different service areas",
              },
              active: {
                type: :boolean,
                description: "Whether the assessment should be active and available to users",
                example: true,
              },
              has_country_restrictions: {
                type: :boolean,
                description: "Whether to enable country-based access restrictions",
                example: false,
              },
              restricted_countries: {
                type: :array,
                items: {
                  type: :string,
                  pattern: "^[A-Z]{3}$",
                },
                description: "Array of ISO 3166-1 alpha-3 country codes to restrict access from (only used if has_country_restrictions is true)",
                example: ["CHN", "RUS"],
              },
            },
            required: %w[title description],
          },
        },
        required: ["assessment"],
        example: {
          assessment: {
            title: "Customer Satisfaction Survey",
            description: "A comprehensive survey to measure customer satisfaction levels",
            active: true,
            has_country_restrictions: false,
            restricted_countries: [],
          },
        },
      }

      response "200", "assessment created" do
        schema type: :object,
               properties: {
                 status: { type: :string, example: "ok" },
                 data: {
                   type: :object,
                   properties: {
                     assessment: { "$ref" => "#/components/schemas/Assessment" },
                     sections_count: { type: :integer, example: 0 },
                     questions_count: { type: :integer, example: 0 },
                   },
                 },
                 errors: { type: :array, items: { type: :object } },
                 notes: { type: :array, items: { type: :string }, example: ["Assessment created successfully"] },
               }
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:assessment) do
          {
            assessment: {
              title: "New Assessment",
              description: "A new assessment for testing",
              active: true,
              has_country_restrictions: false,
              restricted_countries: [],
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["assessment"]["title"]).to eq("New Assessment")
          expect(data["data"]["assessment"]["description"]).to eq("A new assessment for testing")
          expect(data["notes"]).to include("Assessment created successfully")
        end
      end

      response "422", "validation failed" do
        schema type: :object,
               properties: {
                 status: { type: :string, example: "error" },
                 data: { type: :object, example: {} },
                 errors: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       error_code: { type: :string, example: "validation_error" },
                       message: { type: :string, example: "Name can't be blank" },
                       details: { type: :object, example: { "field" => "name" } },
                     },
                   },
                 },
                 notes: { type: :array, items: { type: :string } },
               }
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:assessment) do
          {
            assessment: {
              title: "",
              description: "",
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
        let(:assessment) do
          {
            assessment: {
              title: "New Assessment",
              description: "A new assessment",
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

  path "/api/v1/admin/assessments/{id}" do
    parameter name: :id, in: :path, type: :integer, description: "Assessment ID"

    get "Get assessment details (admin)" do
      tags "Admin - Assessments"
      description "Retrieve details of a specific assessment with statistics (admin only)"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "assessment found" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:id) { public_assessment.id }

        schema type: :object,
               properties: {
                 status: { type: :string, enum: ["ok", "error", "redirect"] },
                 data: {
                   type: :object,
                   properties: {
                     assessment: { "$ref" => "#/components/schemas/Assessment" },
                     sections_count: { type: :integer },
                     questions_count: { type: :integer },
                     statistics: {
                       type: :object,
                       properties: {
                         response_sessions_count: { type: :integer },
                         completed_sessions_count: { type: :integer },
                         average_score: { type: :number, nullable: true },
                       },
                     },
                   },
                 },
                 errors: { type: :array, items: { type: :string } },
                 notes: { type: :array, items: { type: :string } },
               }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["assessment"]["id"]).to eq(public_assessment.id)
          expect(data["data"]["sections_count"]).to be_a(Integer)
          expect(data["data"]["questions_count"]).to be_a(Integer)
          expect(data["data"]["statistics"]).to be_a(Hash)
          expect(data["notes"]).to include("Assessment retrieved successfully")
        end
      end

      response "404", "assessment not found" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:id) { 99999 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("not_found_error")
        end
      end

      response "403", "forbidden - not admin" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:id) { public_assessment.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_error")
        end
      end
    end

    patch "Update assessment (admin)" do
      tags "Admin - Assessments"
      description "Update an assessment (admin only)"
      produces "application/json"
      consumes "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :assessment, in: :body, schema: {
        type: :object,
        properties: {
          assessment: {
            type: :object,
            properties: {
              title: { type: :string },
              description: { type: :string },
              active: { type: :boolean },
              has_country_restrictions: { type: :boolean },
              restricted_countries: {
                type: :array,
                items: { type: :string },
              },
            },
          },
        },
        required: ["assessment"],
      }

      response "200", "assessment updated" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:id) { public_assessment.id }
        let(:assessment) do
          {
            assessment: {
              title: "Updated Assessment",
              description: "Updated description",
              active: false,
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["assessment"]["title"]).to eq("Updated Assessment")
          expect(data["data"]["assessment"]["active"]).to be false
          expect(data["notes"]).to include("Assessment updated successfully")
        end
      end

      response "403", "forbidden - not admin" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:id) { public_assessment.id }
        let(:assessment) do
          {
            assessment: {
              title: "Updated Assessment",
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

    delete "Delete assessment (admin)" do
      tags "Admin - Assessments"
      description "Delete an assessment (admin only)"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "assessment deleted" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let!(:assessment_to_delete) { create(:assessment, title: "Delete Me") }
        let(:id) { assessment_to_delete.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["deleted_id"]).to eq(assessment_to_delete.id)
          expect(data["notes"]).to include("Assessment deleted successfully")
        end
      end

      response "403", "forbidden - not admin" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:id) { public_assessment.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_error")
        end
      end
    end
  end
end
