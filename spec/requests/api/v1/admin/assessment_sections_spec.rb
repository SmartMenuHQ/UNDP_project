require "swagger_helper"

RSpec.describe "Api::V1::Admin::AssessmentSections", type: :request do
  let!(:country_usa) { create(:country, :usa) }
  let!(:admin_user) { create(:user, :admin, country: country_usa) }
  let!(:regular_user) { create(:user, country: country_usa) }

  let!(:admin_session) { create(:session, user: admin_user) }
  let!(:user_session) { create(:session, user: regular_user) }

  let(:admin_token) { admin_session.token }
  let(:user_token) { user_session.token }

  let!(:assessment) { create(:assessment, title: "Test Assessment") }
  let!(:section1) { create(:assessment_section, assessment: assessment, name: "Section 1", order: 1) }
  let!(:section2) { create(:assessment_section, assessment: assessment, name: "Section 2", order: 2) }

  path "/api/v1/admin/assessments/{assessment_id}/sections" do
    parameter name: :assessment_id, in: :path, type: :integer, description: "Assessment ID"

    get "List assessment sections (admin)" do
      tags "Admin - Assessment Sections"
      description "Retrieve all sections for an assessment with optional filtering (admin only)"
      produces "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :page, in: :query, type: :integer, required: false, description: "Page number for pagination (default: 1)", example: 1
      parameter name: :per_page, in: :query, type: :integer, required: false, description: "Items per page (default: 25, max: 100)", example: 25
      parameter name: :active, in: :query, type: :boolean, required: false, description: "Filter by active status", example: true
      parameter name: :search, in: :query, type: :string, required: false, description: "Search by section name", example: "introduction"
      parameter name: :sort_by, in: :query, type: :string, required: false, description: "Sort field (order, name, created_at)", example: "order"
      parameter name: :sort_order, in: :query, type: :string, required: false, description: "Sort direction", enum: ["asc", "desc"], example: "asc"

      response "200", "sections found" do
        schema type: :object,
               properties: {
                 status: { type: :string, example: "ok" },
                 data: {
                   type: :object,
                   properties: {
                     sections: {
                       type: :array,
                       items: { "$ref" => "#/components/schemas/AssessmentSection" },
                     },
                     total_count: { type: :integer, example: 2 },
                     assessment: { "$ref" => "#/components/schemas/Assessment" },
                   },
                 },
                 errors: { type: :array, items: { type: :object } },
                 notes: { type: :array, items: { type: :string }, example: ["Assessment sections retrieved successfully"] },
               },
               examples: {
                 sections_found: {
                   summary: "List of assessment sections",
                   value: {
                     status: "ok",
                     data: {
                       sections: [{
                         id: 1,
                         name: "Introduction",
                         order: 1,
                         is_conditional: false,
                         has_country_restrictions: false,
                         questions_count: 3,
                         created_at: "2024-01-01T00:00:00.000Z",
                       }],
                       total_count: 1,
                       assessment: {
                         id: 1,
                         title: "Customer Satisfaction Survey",
                         description: "Annual customer feedback survey",
                       },
                     },
                     errors: [],
                     notes: ["Assessment sections retrieved successfully"],
                   },
                 },
               }
        let(:assessment_id) { assessment.id }
        let(:Authorization) { "Bearer #{admin_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["sections"]).to be_an(Array)
          expect(data["data"]["total_count"]).to be_a(Integer)
          expect(data["data"]["assessment"]["id"]).to eq(assessment.id)
          expect(data["notes"]).to include("Assessment sections retrieved successfully")
        end
      end

      response "403", "forbidden - not admin" do
        let(:assessment_id) { assessment.id }
        let(:Authorization) { "Bearer #{user_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_error")
        end
      end

      response "404", "assessment not found" do
        let(:assessment_id) { 99999 }
        let(:Authorization) { "Bearer #{admin_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("not_found_error")
        end
      end
    end

    post "Create assessment section (admin)" do
      tags "Admin - Assessment Sections"
      description "Create a new section for an assessment (admin only)"
      produces "application/json"
      consumes "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :section, in: :body, description: "Section data for creation", schema: {
        type: :object,
        properties: {
          section: {
            type: :object,
            description: "Section attributes",
            properties: {
              name: {
                type: :string,
                description: "Section name",
                example: "Introduction",
                maxLength: 200,
              },
              order: {
                type: :integer,
                description: "Display order (auto-assigned if not provided)",
                example: 1,
                minimum: 1,
              },
              is_conditional: {
                type: :boolean,
                description: "Whether this section has conditional visibility",
                example: false,
              },
              has_country_restrictions: {
                type: :boolean,
                description: "Whether this section has country restrictions",
                example: false,
              },
              visibility_conditions: {
                type: :object,
                description: "Conditional visibility rules (if is_conditional is true)",
                example: {},
              },
              restricted_countries: {
                type: :array,
                items: {
                  type: :string,
                  pattern: "^[A-Z]{3}$",
                },
                description: "Country codes to restrict (if has_country_restrictions is true)",
                example: ["CHN"],
              },
              metadata: {
                type: :object,
                description: "Additional metadata",
                example: {},
              },
            },
            required: %w[name],
          },
        },
        required: ["section"],
        example: {
          section: {
            name: "Introduction",
            order: 1,
            is_conditional: false,
            has_country_restrictions: false,
            metadata: {
              description: "Welcome section with basic instructions",
              estimated_time_minutes: 3,
              category: "introduction",
            },
          },
        },
      }

      response "200", "section created" do
        schema type: :object,
               properties: {
                 status: { type: :string, example: "ok" },
                 data: {
                   type: :object,
                   properties: {
                     section: { "$ref" => "#/components/schemas/AssessmentSection" },
                     questions_count: { type: :integer, example: 0 },
                   },
                 },
                 errors: { type: :array, items: { type: :object } },
                 notes: { type: :array, items: { type: :string }, example: ["Assessment section created successfully"] },
               }
        let(:assessment_id) { assessment.id }
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:section) do
          {
            section: {
              name: "New Section",
              order: 3,
              is_conditional: false,
              has_country_restrictions: false,
            },
          }
        end

        schema "$ref" => "#/components/schemas/ApiResponse"

        examples "application/json" => {
          "Basic Section Creation" => {
            value: {
              status: "ok",
              data: {
                section: {
                  id: 1,
                  name: "New Section",
                  order: 3,
                  metadata: {},
                  is_conditional: false,
                  has_country_restrictions: false,
                  restricted_countries: [],
                  questions_count: 0,
                  created_at: "2024-01-15T10:30:00Z",
                  updated_at: "2024-01-15T10:30:00Z",
                },
              },
              errors: [],
              notes: ["Assessment section 'New Section' created successfully"],
            },
          },
        }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["section"]["name"]).to eq("New Section")
          expect(data["data"]["section"]["order"]).to eq(3)
          expect(data["notes"]).to include("Assessment section 'New Section' created successfully")
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
                       message: { type: :string, example: "Name is too long (maximum is 200 characters)" },
                       details: { type: :object, example: { "field" => "name" } },
                     },
                   },
                 },
                 notes: { type: :array, items: { type: :string } },
               },
               examples: {
                 validation_error: {
                   summary: "Section validation failed",
                   value: {
                     status: "error",
                     data: {},
                     errors: [{
                       error_code: "validation_error",
                       message: "Name is too long (maximum is 200 characters)",
                       details: { "field" => "name" },
                     }],
                     notes: [],
                   },
                 },
               }
        let(:assessment_id) { assessment.id }
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:section) do
          {
            section: {
              name: "x" * 300,  # Exceeds maximum length of 255
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
        let(:assessment_id) { assessment.id }
        let(:Authorization) { "Bearer #{user_token}" }
        let(:section) do
          {
            section: {
              name: "New Section",
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

  path "/api/v1/admin/assessments/{assessment_id}/sections/{id}" do
    parameter name: :assessment_id, in: :path, type: :integer, description: "Assessment ID"
    parameter name: :id, in: :path, type: :integer, description: "Section ID"

    get "Get assessment section details (admin)" do
      tags "Admin - Assessment Sections"
      description "Retrieve details of a specific assessment section (admin only)"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "section found" do
        let(:assessment_id) { assessment.id }
        let(:id) { section1.id }
        let(:Authorization) { "Bearer #{admin_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["section"]["id"]).to eq(section1.id)
          expect(data["data"]["section"]["name"]).to eq(section1.name)
          expect(data["data"]["questions_count"]).to be_a(Integer)
          expect(data["data"]["statistics"]).to be_a(Hash)
          expect(data["notes"]).to include("Assessment section retrieved successfully")
        end
      end

      response "404", "section not found" do
        schema type: :object,
               properties: {
                 status: { type: :string, example: "error" },
                 data: { type: :object, example: {} },
                 errors: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       error_code: { type: :string, example: "not_found_error" },
                       message: { type: :string, example: "Assessment section not found" },
                       details: { type: :object, example: {} },
                     },
                   },
                 },
                 notes: { type: :array, items: { type: :string } },
               },
               examples: {
                 not_found_error: {
                   summary: "Section not found",
                   value: {
                     status: "error",
                     data: {},
                     errors: [{
                       error_code: "not_found_error",
                       message: "Assessment section not found",
                       details: {},
                     }],
                     notes: [],
                   },
                 },
               }
        let(:assessment_id) { assessment.id }
        let(:id) { 99999 }
        let(:Authorization) { "Bearer #{admin_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("not_found_error")
        end
      end

      response "403", "forbidden - not admin" do
        let(:assessment_id) { assessment.id }
        let(:id) { section1.id }
        let(:Authorization) { "Bearer #{user_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_error")
        end
      end
    end

    patch "Update assessment section (admin)" do
      tags "Admin - Assessment Sections"
      description "Update an assessment section (admin only)"
      produces "application/json"
      consumes "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :section, in: :body, description: "Section data for update", schema: {
        type: :object,
        properties: {
          section: {
            type: :object,
            description: "Section attributes to update",
            properties: {
              name: {
                type: :string,
                description: "Section name",
                example: "Updated Introduction",
                maxLength: 200,
              },
              order: {
                type: :integer,
                description: "Display order",
                example: 2,
                minimum: 1,
              },
              is_conditional: {
                type: :boolean,
                description: "Whether this section has conditional visibility",
                example: true,
              },
              has_country_restrictions: {
                type: :boolean,
                description: "Whether this section has country restrictions",
                example: false,
              },
              visibility_conditions: {
                type: :object,
                description: "Conditional visibility rules",
                example: { trigger_question_id: 5, operator: "equals", value: "yes" },
              },
              restricted_countries: {
                type: :array,
                items: {
                  type: :string,
                  pattern: "^[A-Z]{3}$",
                },
                description: "Country codes to restrict",
                example: [],
              },
            },
          },
        },
        required: ["section"],
        example: {
          section: {
            name: "Updated Introduction",
            order: 2,
          },
        },
      }

      response "200", "section updated" do
        let(:assessment_id) { assessment.id }
        let(:id) { section1.id }
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:section) do
          {
            section: {
              name: "Updated Section Name",
              order: 5,
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["section"]["name"]).to eq("Updated Section Name")
          expect(data["data"]["section"]["order"]).to eq(5)
          expect(data["notes"]).to include("Assessment section 'Updated Section Name' updated successfully")
        end
      end

      response "403", "forbidden - not admin" do
        let(:assessment_id) { assessment.id }
        let(:id) { section1.id }
        let(:Authorization) { "Bearer #{user_token}" }
        let(:section) do
          {
            section: {
              name: "Updated Section",
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

    delete "Delete assessment section (admin)" do
      tags "Admin - Assessment Sections"
      description "Delete an assessment section (admin only)"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "section deleted" do
        let(:assessment_id) { assessment.id }
        let!(:section_to_delete) { create(:assessment_section, assessment: assessment, name: "Delete Me", order: 10) }
        let(:id) { section_to_delete.id }
        let(:Authorization) { "Bearer #{admin_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["deleted_id"]).to eq(section_to_delete.id)
          expect(data["notes"]).to include("Assessment section 'Delete Me' deleted successfully")
        end
      end

      response "422", "cannot delete section with questions" do
        let(:assessment_id) { assessment.id }
        let(:id) { section1.id }
        let(:Authorization) { "Bearer #{admin_token}" }
        let!(:question) do
          question = build(:assessment_question, assessment: assessment, assessment_section: section1)
          question.text = "Test question with sufficient length"
          question.save!
          question
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("validation_error")
          expect(data["errors"].first["details"]["questions_count"]).to be > 0
        end
      end

      response "403", "forbidden - not admin" do
        let(:assessment_id) { assessment.id }
        let(:id) { section1.id }
        let(:Authorization) { "Bearer #{user_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_error")
        end
      end
    end
  end
end
