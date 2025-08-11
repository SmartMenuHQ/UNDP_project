require "swagger_helper"

RSpec.describe "Api::V1::Admin::MarkingSchemes", type: :request do
  let!(:admin_user) { create(:user, :admin) }
  let!(:regular_user) { create(:user) }
  let!(:admin_session) { create(:session, user: admin_user) }
  let!(:user_session) { create(:session, user: regular_user) }
  let(:Authorization) { nil }
  let(:admin_token) { admin_session.token }
  let(:user_token) { user_session.token }

  let!(:assessment) { create(:assessment, title: "Assess A") }

  path "/api/v1/admin/assessments/{assessment_id}/marking-schemes" do
    parameter name: :assessment_id, in: :path, type: :integer, description: "Assessment ID"

    get "List marking schemes (admin)" do
      tags "Admin - Marking Schemes"
      description "List marking schemes for an assessment with pagination and filters"
      produces "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false
      parameter name: :is_active, in: :query, type: :boolean, required: false
      parameter name: :search, in: :query, type: :string, required: false

      response "200", "marking schemes found" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:assessment_id) { assessment.id }

        before do
          assessment.assessment_marking_schemes.create!(name: "Scheme 1", total_possible_score: 10)
          assessment.assessment_marking_schemes.create!(name: "Scheme 2", is_active: true, total_possible_score: 20)
        end

        schema type: :object,
               properties: {
                 status: { type: :string },
                 data: {
                   type: :object,
                   properties: {
                     marking_schemes: {
                       type: :array,
                       items: { "$ref" => "#/components/schemas/MarkingScheme" },
                     },
                     total_count: { type: :integer },
                     active_count: { type: :integer },
                     pagination: { type: :object },
                     assessment: { type: :object },
                   },
                 },
                 errors: { type: :array, items: { "$ref" => "#/components/schemas/Error" } },
                 notes: { type: :array, items: { type: :string } },
               }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["marking_schemes"]).to be_an(Array)
          expect(data["data"]["total_count"]).to be_a(Integer)
          expect(data["notes"]).to include("Marking schemes retrieved successfully")
        end
      end

      response "403", "forbidden - not admin" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:assessment_id) { assessment.id }

        schema "$ref" => "#/components/schemas/ApiResponse"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_error")
        end
      end

      response "401", "unauthorized" do
        let(:assessment_id) { assessment.id }
        let(:Authorization) { nil }

        schema "$ref" => "#/components/schemas/ApiResponse"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("invalid_token_error")
        end
      end
    end

    post "Create marking scheme (admin)" do
      tags "Admin - Marking Schemes"
      description "Create a marking scheme for an assessment"
      produces "application/json"
      consumes "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :marking_scheme, in: :body, description: "Marking scheme attributes. If total_possible_score is omitted, a default is calculated as 10 points per question. Settings allow configuration of passing thresholds, grade boundaries, and feedback templates.", schema: {
        type: :object,
        properties: {
          marking_scheme: {
            type: :object,
            description: "Marking scheme attributes",
            properties: {
              name: {
                type: :string,
                description: "Name of the marking scheme (must be present)",
                example: "Midterm Scheme",
              },
              description: {
                type: :string,
                description: "Optional description of the marking scheme",
                example: "Auto-grading scheme",
              },
              is_active: {
                type: :boolean,
                description: "Whether to set this scheme active immediately",
                example: false,
              },
              total_possible_score: {
                type: :number,
                description: "Total points available across all rules (auto-calculated if omitted)",
                example: 100,
              },
              settings: {
                type: :object,
                description: "Scheme settings for passing score, grade boundaries, and feedback templates",
                properties: {
                  passing_score: {
                    type: :number,
                    description: "Passing threshold as percentage (0-100)",
                    example: 60,
                  },
                  grade_boundaries: {
                    type: :object,
                    additionalProperties: { type: :number },
                    description: "Map of grade letter to minimum percentage threshold",
                    example: { "A": 90, "B": 80, "C": 70, "D": 60, "F": 0 },
                  },
                  feedback_templates: {
                    type: :object,
                    additionalProperties: { type: :string },
                    description: "Map of grade letter to feedback message template",
                    example: { "A": "Excellent work!", "C": "Satisfactory performance" },
                  },
                },
              },
            },
            required: ["name"],
          },
        },
        required: ["marking_scheme"],
        example: {
          marking_scheme: {
            name: "Midterm Scheme",
            description: "Auto-grading scheme",
            is_active: false,
            total_possible_score: 100,
            settings: {
              passing_score: 60,
              grade_boundaries: { A: 90, B: 80, C: 70, D: 60, F: 0 },
              feedback_templates: { A: "Excellent work!", C: "Satisfactory performance" },
            },
          },
        },
      }

      response "200", "marking scheme created" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:assessment_id) { assessment.id }
        let(:marking_scheme) do
          {
            marking_scheme: {
              name: "Midterm Scheme",
              description: "Auto-grading scheme",
              is_active: false,
              total_possible_score: 100,
            },
          }
        end

        schema type: :object,
               properties: {
                 status: { type: :string },
                 data: {
                   type: :object,
                   properties: {
                     marking_scheme: { "$ref" => "#/components/schemas/MarkingScheme" },
                   },
                 },
                 errors: { type: :array, items: { "$ref" => "#/components/schemas/Error" } },
                 notes: { type: :array, items: { type: :string } },
               }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["marking_scheme"]["name"]).to eq("Midterm Scheme")
          expect(data["notes"]).to include("Marking scheme created successfully")
        end
      end

      response "422", "validation failed" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:assessment_id) { assessment.id }
        let(:marking_scheme) do
          { marking_scheme: { name: "" } }
        end

        schema "$ref" => "#/components/schemas/ApiResponse"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("validation_error")
        end
      end

      response "403", "forbidden - not admin" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:assessment_id) { assessment.id }
        let(:marking_scheme) do
          { marking_scheme: { name: "Unauthorized" } }
        end

        schema "$ref" => "#/components/schemas/ApiResponse"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_error")
        end
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }
        let(:assessment_id) { assessment.id }
        let(:marking_scheme) do
          { marking_scheme: { name: "Unauthorized" } }
        end

        schema "$ref" => "#/components/schemas/ApiResponse"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("invalid_token_error")
        end
      end
    end
  end

  path "/api/v1/admin/assessments/{assessment_id}/marking-schemes/{id}" do
    parameter name: :assessment_id, in: :path, type: :integer, description: "Assessment ID"
    parameter name: :id, in: :path, type: :integer, description: "Marking Scheme ID"

    get "Get marking scheme (admin)" do
      tags "Admin - Marking Schemes"
      description "Retrieve a single marking scheme"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "marking scheme found" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:assessment_id) { assessment.id }
        let!(:scheme) { assessment.assessment_marking_schemes.create!(name: "S1", total_possible_score: 10) }
        let(:id) { scheme.id }

        schema type: :object,
               properties: {
                 status: { type: :string },
                 data: {
                   type: :object,
                   properties: {
                     marking_scheme: { "$ref" => "#/components/schemas/MarkingScheme" },
                   },
                 },
                 errors: { type: :array, items: { "$ref" => "#/components/schemas/Error" } },
                 notes: { type: :array, items: { type: :string } },
               }

        run_test!
      end

      response "404", "not found" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:assessment_id) { assessment.id }
        let(:id) { 0 }

        schema "$ref" => "#/components/schemas/ApiResponse"

        run_test!
      end
    end

    patch "Update marking scheme (admin)" do
      tags "Admin - Marking Schemes"
      description "Update a marking scheme"
      produces "application/json"
      consumes "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :marking_scheme, in: :body, description: "Marking scheme fields to update.", schema: {
        type: :object,
        properties: {
          marking_scheme: {
            type: :object,
            description: "Marking scheme attributes",
            properties: {
              name: { type: :string, description: "Name of the scheme", example: "Updated Scheme" },
              description: { type: :string, description: "Description", example: "Updated description" },
              is_active: { type: :boolean, description: "Set active status", example: false },
              total_possible_score: { type: :number, description: "Total possible score", example: 120 },
              settings: { type: :object, description: "Settings object" },
            },
          },
        },
        required: ["marking_scheme"],
        example: {
          marking_scheme: {
            name: "Updated Scheme",
            description: "Updated description",
            is_active: false,
          },
        },
      }

      response "200", "marking scheme updated" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:assessment_id) { assessment.id }
        let!(:scheme) { assessment.assessment_marking_schemes.create!(name: "S1", total_possible_score: 10) }
        let(:id) { scheme.id }
        let(:marking_scheme) do
          { marking_scheme: { name: "Updated Scheme" } }
        end

        schema type: :object,
               properties: {
                 status: { type: :string },
                 data: {
                   type: :object,
                   properties: {
                     marking_scheme: { "$ref" => "#/components/schemas/MarkingScheme" },
                   },
                 },
                 errors: { type: :array, items: { "$ref" => "#/components/schemas/Error" } },
                 notes: { type: :array, items: { type: :string } },
               }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["data"]["marking_scheme"]["name"]).to eq("Updated Scheme")
        end
      end

      response "403", "forbidden - not admin" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:assessment_id) { assessment.id }
        let!(:scheme) { assessment.assessment_marking_schemes.create!(name: "S1", total_possible_score: 10) }
        let(:id) { scheme.id }
        let(:marking_scheme) do
          { marking_scheme: { name: "Updated" } }
        end

        schema "$ref" => "#/components/schemas/ApiResponse"

        run_test!
      end
    end

    delete "Delete marking scheme (admin)" do
      tags "Admin - Marking Schemes"
      description "Delete a marking scheme"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "marking scheme deleted" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:assessment_id) { assessment.id }
        let!(:scheme) { assessment.assessment_marking_schemes.create!(name: "ToDelete", total_possible_score: 10) }
        let(:id) { scheme.id }

        schema type: :object,
               properties: {
                 status: { type: :string },
                 data: { type: :object, properties: { deleted_id: { type: :integer } } },
                 errors: { type: :array, items: { "$ref" => "#/components/schemas/Error" } },
                 notes: { type: :array, items: { type: :string } },
               }

        run_test!
      end

      response "403", "forbidden - not admin" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:assessment_id) { assessment.id }
        let(:id) { 0 }

        schema "$ref" => "#/components/schemas/ApiResponse"

        run_test!
      end
    end
  end

  path "/api/v1/admin/assessments/{assessment_id}/marking-schemes/{id}/activate" do
    parameter name: :assessment_id, in: :path, type: :integer, description: "Assessment ID"
    parameter name: :id, in: :path, type: :integer, description: "Marking Scheme ID"

    post "Activate marking scheme (admin)" do
      tags "Admin - Marking Schemes"
      description "Activate a marking scheme (deactivates others for the assessment)"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "marking scheme activated" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:assessment_id) { assessment.id }
        let!(:scheme1) { assessment.assessment_marking_schemes.create!(name: "S1", total_possible_score: 10, is_active: false) }
        let!(:scheme2) { assessment.assessment_marking_schemes.create!(name: "S2", total_possible_score: 10, is_active: true) }
        let(:id) { scheme1.id }

        schema type: :object,
               properties: {
                 status: { type: :string },
                 data: {
                   type: :object,
                   properties: {
                     marking_scheme: { "$ref" => "#/components/schemas/MarkingScheme" },
                   },
                 },
                 errors: { type: :array, items: { "$ref" => "#/components/schemas/Error" } },
                 notes: { type: :array, items: { type: :string } },
               }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["data"]["marking_scheme"]["is_active"]).to be(true)
        end
      end

      response "403", "forbidden - not admin" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:assessment_id) { assessment.id }
        let(:id) { 0 }

        schema "$ref" => "#/components/schemas/ApiResponse"

        run_test!
      end
    end
  end

  path "/api/v1/admin/assessments/{assessment_id}/marking-schemes/{id}/clone" do
    parameter name: :assessment_id, in: :path, type: :integer, description: "Assessment ID"
    parameter name: :id, in: :path, type: :integer, description: "Marking Scheme ID"

    post "Clone marking scheme (admin)" do
      tags "Admin - Marking Schemes"
      description "Clone a marking scheme including its rules"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "marking scheme cloned" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:assessment_id) { assessment.id }
        let!(:scheme) { assessment.assessment_marking_schemes.create!(name: "Original", total_possible_score: 10) }
        let(:id) { scheme.id }

        schema type: :object,
               properties: {
                 status: { type: :string },
                 data: {
                   type: :object,
                   properties: {
                     marking_scheme: { "$ref" => "#/components/schemas/MarkingScheme" },
                   },
                 },
                 errors: { type: :array, items: { "$ref" => "#/components/schemas/Error" } },
                 notes: { type: :array, items: { type: :string } },
               }

        run_test!
      end

      response "403", "forbidden - not admin" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:assessment_id) { assessment.id }
        let(:id) { 0 }

        schema "$ref" => "#/components/schemas/ApiResponse"

        run_test!
      end
    end
  end
end
