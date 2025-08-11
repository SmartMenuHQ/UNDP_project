require "swagger_helper"

RSpec.describe "Api::V1::Admin::AssessmentQuestions", type: :request do
  let!(:country_usa) { create(:country, :usa) }
  let!(:admin_user) { create(:user, :admin, country: country_usa) }
  let!(:regular_user) { create(:user, country: country_usa) }

  let!(:admin_session) { create(:session, user: admin_user) }
  let!(:user_session) { create(:session, user: regular_user) }

  let(:admin_token) { admin_session.token }
  let(:user_token) { user_session.token }

  let!(:assessment) { create(:assessment, title: "Test Assessment") }
  let!(:section) { create(:assessment_section, assessment: assessment, name: "Test Section", order: 1) }
  let!(:question1) do
    question = build(:assessment_question, assessment: assessment, assessment_section: section, order: 1)
    question.text = { "en" => "What is your first question about?" }
    question.save!
    question
  end
  let!(:question2) do
    question = build(:assessment_question, assessment: assessment, assessment_section: section, order: 2)
    question.text = { "en" => "This is a second question with conditional visibility features" }
    question.is_conditional = true
    question.trigger_question_id = question1.id
    question.trigger_response_type = "value_equals"
    question.trigger_values = ["yes"]
    question.operator = "equals"
    question.save!
    question
  end

  path "/api/v1/admin/assessments/{assessment_id}/sections/{section_id}/questions" do
    parameter name: :assessment_id, in: :path, type: :integer, description: "Assessment ID"
    parameter name: :section_id, in: :path, type: :integer, description: "Section ID"

    get "List assessment questions (admin)" do
      tags "Admin - Assessment Questions"
      description "Retrieve all questions for a section with optional filtering (admin only)"
      produces "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :page, in: :query, type: :integer, required: false, description: "Page number for pagination (default: 1)", example: 1
      parameter name: :per_page, in: :query, type: :integer, required: false, description: "Items per page (default: 25, max: 100)", example: 25
      parameter name: :active, in: :query, type: :boolean, required: false, description: "Filter by active status", example: true
      parameter name: :is_required, in: :query, type: :boolean, required: false, description: "Filter by required status", example: true
      parameter name: :question_type, in: :query, type: :string, required: false, description: "Filter by question type", example: "AssessmentQuestions::MultipleChoice"
      parameter name: :search, in: :query, type: :string, required: false, description: "Search by question text", example: "name"
      parameter name: :sort_by, in: :query, type: :string, required: false, description: "Sort field (order, created_at, updated_at)", example: "order"
      parameter name: :sort_order, in: :query, type: :string, required: false, description: "Sort direction", enum: ["asc", "desc"], example: "asc"

      response "200", "questions found" do
        schema type: :object,
               properties: {
                 status: { type: :string, example: "ok" },
                 data: {
                   type: :object,
                   properties: {
                     questions: {
                       type: :array,
                       items: { "$ref" => "#/components/schemas/AssessmentQuestion" },
                     },
                     total_count: { type: :integer, example: 5 },
                     section: { "$ref" => "#/components/schemas/AssessmentSection" },
                     available_question_types: {
                       type: :array,
                       items: {
                         type: :object,
                         properties: {
                           type: { type: :string },
                           name: { type: :string },
                           description: { type: :string },
                         },
                       },
                     },
                   },
                 },
                 errors: { type: :array, items: { type: :object } },
                 notes: { type: :array, items: { type: :string }, example: ["Assessment questions retrieved successfully"] },
               },
               examples: {
                 questions_found: {
                   summary: "List of assessment questions",
                   value: {
                     status: "ok",
                     data: {
                       questions: [
                         {
                           id: 1,
                           text: { "en" => "What is your name?" },
                           type: "AssessmentQuestions::RichText",
                           question_type_name: "Rich Text",
                           order: 1,
                           is_required: true,
                           active: true,
                           created_at: "2024-01-01T00:00:00.000Z",
                         },
                       ],
                       total_count: 5,
                       section: { id: 1, name: "Introduction", order: 1 },
                       available_question_types: [
                         { type: "AssessmentQuestions::RichText", name: "Rich Text", description: "Rich text input" },
                       ],
                     },
                     errors: [],
                     notes: ["Assessment questions retrieved successfully"],
                   },
                 },
               }
        let(:assessment_id) { assessment.id }
        let(:section_id) { section.id }
        let(:Authorization) { "Bearer #{admin_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["questions"]).to be_an(Array)
          expect(data["data"]["total_count"]).to be_a(Integer)
          expect(data["data"]["section"]["id"]).to eq(section.id)
          expect(data["data"]["available_question_types"]).to be_an(Array)
          expect(data["notes"]).to include("Assessment questions retrieved successfully")
        end
      end

      response "403", "forbidden - not admin" do
        let(:assessment_id) { assessment.id }
        let(:section_id) { section.id }
        let(:Authorization) { "Bearer #{user_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_error")
        end
      end
    end

    post "Create assessment question (admin)" do
      tags "Admin - Assessment Questions"
      description "Create a new question for a section (admin only)"
      produces "application/json"
      consumes "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :question, in: :body, description: "Question data for creation", schema: {
        type: :object,
        properties: {
          question: {
            type: :object,
            description: "Question attributes",
            properties: {
              type: {
                type: :string,
                description: "Question type class name",
                example: "AssessmentQuestions::MultipleChoice",
                enum: [
                  "AssessmentQuestions::RichText",
                  "AssessmentQuestions::MultipleChoice",
                  "AssessmentQuestions::Radio",
                  "AssessmentQuestions::BooleanType",
                  "AssessmentQuestions::DateType",
                  "AssessmentQuestions::RangeType",
                  "AssessmentQuestions::FileUpload",
                ],
              },
              text: {
                type: :object,
                description: "Question text in multiple languages",
                example: { "en" => "What is your favorite color?" },
                properties: {
                  en: { type: :string, description: "English text" },
                  es: { type: :string, description: "Spanish text" },
                  fr: { type: :string, description: "French text" },
                },
              },
              sub_type: {
                type: :string,
                description: "Question sub-type (required for some question types)",
                example: "long_text",
              },
              order: {
                type: :integer,
                description: "Display order (auto-assigned if not provided)",
                example: 1,
                minimum: 1,
              },
              is_required: {
                type: :boolean,
                description: "Whether this question is required",
                example: true,
              },
              active: {
                type: :boolean,
                description: "Whether this question is active",
                example: true,
              },
              is_conditional: {
                type: :boolean,
                description: "Whether this question has conditional visibility",
                example: false,
              },
              trigger_question_id: {
                type: :integer,
                description: "ID of the question that triggers visibility (required if is_conditional is true)",
                example: 1,
              },
              trigger_response_type: {
                type: :string,
                description: "Type of response to check (required if is_conditional is true)",
                enum: ["option_selected", "value_equals", "value_range"],
                example: "value_equals",
              },
              trigger_values: {
                type: :array,
                items: { type: :string },
                description: "Array of values/option IDs that trigger visibility (required if is_conditional is true)",
                example: ["yes", "true"],
              },
              operator: {
                type: :string,
                description: "Comparison operator (required if is_conditional is true)",
                enum: ["equals", "not_equals", "contains", "greater_than", "less_than", "between", "any", "all", "none"],
                example: "equals",
              },
              has_country_restrictions: {
                type: :boolean,
                description: "Whether this question has country restrictions",
                example: false,
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
              meta_data: {
                type: :object,
                description: "Additional metadata",
                example: {},
              },
            },
            required: %w[type text],
          },
        },
        required: ["question"],
        example: {
          question: {
            type: "AssessmentQuestions::MultipleChoice",
            text: { "en" => "What is your favorite color?" },
            is_required: true,
            active: true,
            is_conditional: false,
          },
        },
      }

      response "200", "question created" do
        schema type: :object,
               properties: {
                 status: { type: :string, example: "ok" },
                 data: {
                   type: :object,
                   properties: {
                     question: { "$ref" => "#/components/schemas/AssessmentQuestion" },
                   },
                 },
                 errors: { type: :array, items: { type: :object } },
                 notes: { type: :array, items: { type: :string }, example: ["Assessment question created successfully"] },
               }
        let(:assessment_id) { assessment.id }
        let(:section_id) { section.id }
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:question) do
          {
            question: {
              type: "AssessmentQuestions::MultipleChoice",
              text: { "en" => "What is your preferred programming language?" },
              is_required: true,
              active: true,
              is_conditional: false,
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["question"]["type"]).to eq("AssessmentQuestions::MultipleChoice")
          expect(data["data"]["question"]["text"]).to eq("What is your preferred programming language?")
          expect(data["notes"]).to include("Assessment question created successfully")
        end
      end

      response "200", "conditional question created" do
        let(:assessment_id) { assessment.id }
        let(:section_id) { section.id }
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:question) do
          {
            question: {
              type: "AssessmentQuestions::RichText",
              sub_type: "long_text",
              text: { "en" => "Please explain your choice" },
              is_required: false,
              active: true,
              is_conditional: true,
              trigger_question_id: question1.id,
              trigger_response_type: "value_equals",
              trigger_values: ["other"],
              operator: "equals",
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["question"]["is_conditional"]).to eq(true)
          expect(data["data"]["question"]["trigger_question_id"]).to eq(question1.id)
          expect(data["data"]["question"]["operator"]).to eq("equals")
          expect(data["data"]["question"]["trigger_values"]).to eq(["other"])
          expect(data["notes"]).to include("Assessment question created successfully")
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
                       message: { type: :string, example: "Text can't be blank" },
                       details: { type: :object, example: { "field" => "text" } },
                     },
                   },
                 },
                 notes: { type: :array, items: { type: :string } },
               },
               examples: {
                 validation_error: {
                   summary: "Question validation failed",
                   value: {
                     status: "error",
                     data: {},
                     errors: [{
                       error_code: "validation_error",
                       message: "Text can't be blank",
                       details: { "field" => "text" },
                     }],
                     notes: [],
                   },
                 },
               }
        let(:assessment_id) { assessment.id }
        let(:section_id) { section.id }
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:question) do
          {
            question: {
              type: "InvalidQuestionType",  # Invalid type should fail validation
              text: { "en" => "Valid text for testing" },
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("validation_error")
        end
      end

      response "422", "invalid question type" do
        let(:assessment_id) { assessment.id }
        let(:section_id) { section.id }
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:question) do
          {
            question: {
              type: "InvalidQuestionType",
              text: { "en" => "Valid question text" },
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("validation_error")
          expect(data["errors"].first["message"]).to include("Invalid question type")
        end
      end

      response "403", "forbidden - not admin" do
        let(:assessment_id) { assessment.id }
        let(:section_id) { section.id }
        let(:Authorization) { "Bearer #{user_token}" }
        let(:question) do
          {
            question: {
              type: "AssessmentQuestions::RichText",
              text: { "en" => "Valid question" },
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

  path "/api/v1/admin/assessments/{assessment_id}/sections/{section_id}/questions/{id}" do
    parameter name: :assessment_id, in: :path, type: :integer, description: "Assessment ID"
    parameter name: :section_id, in: :path, type: :integer, description: "Section ID"
    parameter name: :id, in: :path, type: :integer, description: "Question ID"

    get "Get assessment question details (admin)" do
      tags "Admin - Assessment Questions"
      description "Retrieve details of a specific assessment question (admin only)"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "question found" do
        schema type: :object,
               properties: {
                 status: { type: :string, example: "ok" },
                 data: {
                   type: :object,
                   properties: {
                     question: { "$ref" => "#/components/schemas/AssessmentQuestion" },
                     statistics: {
                       type: :object,
                       properties: {
                         total_responses: { type: :integer, example: 25 },
                         completion_rate: { type: :number, example: 85.5 },
                         average_time: { type: :number, example: 45.2 },
                       },
                     },
                   },
                 },
                 errors: { type: :array, items: { type: :object } },
                 notes: { type: :array, items: { type: :string }, example: ["Assessment question retrieved successfully"] },
               },
               examples: {
                 question_found: {
                   summary: "Assessment question details",
                   value: {
                     status: "ok",
                     data: {
                       question: {
                         id: 2,
                         text: { "en" => "What is your experience level?" },
                         type: "AssessmentQuestions::MultipleChoice",
                         question_type_name: "Multiple Choice",
                         order: 2,
                         is_required: true,
                         active: true,
                         is_conditional: true,
                         trigger_question_id: 1,
                         trigger_response_type: "value_equals",
                         trigger_values: ["yes"],
                         operator: "equals",
                         created_at: "2024-01-01T00:00:00.000Z",
                       },
                       statistics: {
                         total_responses: 25,
                         completion_rate: 85.5,
                         average_time: 45.2,
                       },
                     },
                     errors: [],
                     notes: ["Assessment question retrieved successfully"],
                   },
                 },
               }
        let(:assessment_id) { assessment.id }
        let(:section_id) { section.id }
        let(:id) { question2.id }
        let(:Authorization) { "Bearer #{admin_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["question"]["id"]).to eq(question2.id)
          expect(data["data"]["question"]["is_conditional"]).to eq(true)
          expect(data["data"]["question"]["trigger_question_id"]).to eq(question1.id)
          expect(data["data"]["statistics"]).to be_a(Hash)
          expect(data["notes"]).to include("Assessment question retrieved successfully")
        end
      end

      response "404", "question not found" do
        let(:assessment_id) { assessment.id }
        let(:section_id) { section.id }
        let(:id) { 99999 }
        let(:Authorization) { "Bearer #{admin_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("not_found_error")
        end
      end
    end

    patch "Update assessment question (admin)" do
      tags "Admin - Assessment Questions"
      description "Update an assessment question (admin only)"
      produces "application/json"
      consumes "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :question, in: :body, description: "Question data for update", schema: {
        type: :object,
        properties: {
          question: {
            type: :object,
            description: "Question attributes to update",
            properties: {
              text: {
                type: :object,
                description: "Question text in multiple languages",
                example: { "en" => "Updated question text?" },
              },
              is_required: {
                type: :boolean,
                description: "Whether this question is required",
                example: false,
              },
              active: {
                type: :boolean,
                description: "Whether this question is active",
                example: true,
              },
              is_conditional: {
                type: :boolean,
                description: "Whether this question has conditional visibility",
                example: true,
              },
              trigger_question_id: {
                type: :integer,
                description: "ID of the question that triggers visibility",
                example: 1,
              },
              trigger_response_type: {
                type: :string,
                description: "Type of response to check",
                enum: ["option_selected", "value_equals", "value_range"],
                example: "value_equals",
              },
              trigger_values: {
                type: :array,
                items: { type: :string },
                description: "Array of values that trigger visibility",
                example: ["no"],
              },
              operator: {
                type: :string,
                description: "Comparison operator",
                enum: ["equals", "not_equals", "contains", "greater_than", "less_than", "between", "any", "all", "none"],
                example: "not_equals",
              },
            },
          },
        },
        required: ["question"],
        example: {
          question: {
            text: { "en" => "Updated: What is your favorite color?" },
            is_required: false,
            is_conditional: true,
            trigger_question_id: 1,
            trigger_response_type: "value_equals",
            trigger_values: ["yes"],
            operator: "equals",
          },
        },
      }

      response "200", "question updated" do
        let(:assessment_id) { assessment.id }
        let(:section_id) { section.id }
        let(:id) { question2.id }
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:question) do
          {
            question: {
              text: { "en" => "Updated question text" },
              sub_type: "long_text",
              is_required: false,
              is_conditional: true,
              trigger_question_id: question1.id,
              trigger_response_type: "value_equals",
              trigger_values: ["skip"],
              operator: "not_equals",
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["question"]["text"]).to eq("Updated question text")
          expect(data["data"]["question"]["is_conditional"]).to eq(true)
          expect(data["data"]["question"]["operator"]).to eq("not_equals")
          expect(data["data"]["question"]["trigger_question_id"]).to eq(question1.id)
          expect(data["notes"]).to include("Assessment question updated successfully")
        end
      end

      response "403", "forbidden - not admin" do
        let(:assessment_id) { assessment.id }
        let(:section_id) { section.id }
        let(:id) { question1.id }
        let(:Authorization) { "Bearer #{user_token}" }
        let(:question) do
          {
            question: {
              text: { "en" => "Updated question" },
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

    delete "Delete assessment question (admin)" do
      tags "Admin - Assessment Questions"
      description "Delete an assessment question (admin only)"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "question deleted" do
        let(:assessment_id) { assessment.id }
        let(:section_id) { section.id }
        let!(:question_to_delete) do
          question = build(:assessment_question, assessment: assessment, assessment_section: section, order: 10)
          question.text = "Question to delete"
          question.save!
          question
        end
        let(:id) { question_to_delete.id }
        let(:Authorization) { "Bearer #{admin_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["deleted_id"]).to eq(question_to_delete.id)
          expect(data["notes"].first).to include("deleted successfully")
        end
      end

      response "422", "cannot delete question with responses" do
        let(:assessment_id) { assessment.id }
        let(:section_id) { section.id }
        let(:id) { question1.id }
        let(:Authorization) { "Bearer #{admin_token}" }
        let!(:response_session) { create(:assessment_response_session, assessment: assessment, user: regular_user) }
        let!(:question_response) do
          create(:assessment_question_response,
                 assessment_question: question1,
                 assessment: assessment,
                 assessment_response_session: response_session,
                 value: "test response")
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("validation_error")
          expect(data["errors"].first["details"]["responses_count"]).to be > 0
        end
      end

      response "403", "forbidden - not admin" do
        let(:assessment_id) { assessment.id }
        let(:section_id) { section.id }
        let(:id) { question1.id }
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
