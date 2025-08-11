require "swagger_helper"

RSpec.describe "Api::V1::Admin::QuestionOptions", type: :request do
  let!(:country_usa) { create(:country, :usa) }
  let!(:admin_user) { create(:user, :admin, country: country_usa) }
  let!(:regular_user) { create(:user, country: country_usa) }

  let!(:admin_session) { create(:session, user: admin_user) }
  let!(:user_session) { create(:session, user: regular_user) }

  let(:admin_token) { admin_session.token }
  let(:user_token) { user_session.token }

  let!(:assessment) { create(:assessment, title: "Test Assessment") }
  let!(:section) { create(:assessment_section, assessment: assessment, name: "Test Section", order: 1) }
  let!(:question) do
    question = build(:assessment_question, :multiple_choice, assessment: assessment, assessment_section: section, order: 1)
    question.text = "What is your favorite programming language?"
    question.save!
    question
  end
  let!(:option1) { create(:assessment_question_option, assessment_question: question, text: { "en" => "Ruby" }, order: 1, is_correct_answer: true, points: 10) }
  let!(:option2) { create(:assessment_question_option, assessment_question: question, text: { "en" => "Python" }, order: 2, is_correct_answer: false, points: 5) }

  path "/api/v1/admin/questions/{question_id}/options" do
    parameter name: :question_id, in: :path, type: :integer, description: "Question ID"

    get "List question options (admin)" do
      tags "Admin - Question Options"
      description "Retrieve all options for a question with optional filtering (admin only)"
      produces "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :is_correct, in: :query, type: :boolean, required: false, description: "Filter by correct answer status", example: true
      parameter name: :search, in: :query, type: :string, required: false, description: "Search by option text", example: "ruby"
      parameter name: :sort_by, in: :query, type: :string, required: false, description: "Sort field (order, points, created_at)", example: "order"
      parameter name: :sort_order, in: :query, type: :string, required: false, description: "Sort direction", enum: ["asc", "desc"], example: "asc"

      response "200", "options found" do
        let(:question_id) { question.id }
        let(:Authorization) { "Bearer #{admin_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["options"]).to be_an(Array)
          expect(data["data"]["total_count"]).to be_a(Integer)
          expect(data["data"]["question"]["id"]).to eq(question.id)
          expect(data["notes"]).to include("Question options retrieved successfully")
        end
      end

      response "403", "forbidden - not admin" do
        let(:question_id) { question.id }
        let(:Authorization) { "Bearer #{user_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_error")
        end
      end
    end

    post "Create question option (admin)" do
      tags "Admin - Question Options"
      description "Create a new option for a question (admin only)"
      produces "application/json"
      consumes "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :option, in: :body, description: "Option data for creation", schema: {
        type: :object,
        properties: {
          option: {
            type: :object,
            description: "Option attributes",
            properties: {
              text: {
                type: :object,
                description: "Option text in multiple languages",
                example: { "en" => "JavaScript" },
                properties: {
                  en: { type: :string, description: "English text" },
                  es: { type: :string, description: "Spanish text" },
                  fr: { type: :string, description: "French text" },
                },
              },
              order: {
                type: :integer,
                description: "Display order (auto-assigned if not provided)",
                example: 3,
                minimum: 1,
              },
              is_correct_answer: {
                type: :boolean,
                description: "Whether this is a correct answer",
                example: false,
              },
              points: {
                type: :integer,
                description: "Points awarded for selecting this option",
                example: 5,
              },
              metadata: {
                type: :object,
                description: "Additional metadata",
                example: {},
              },
            },
            required: %w[text],
          },
        },
        required: ["option"],
        example: {
          option: {
            text: { "en" => "JavaScript" },
            order: 3,
            is_correct_answer: false,
            points: 5,
          },
        },
      }

      response "200", "option created" do
        schema type: :object,
               properties: {
                 status: { type: :string, example: "ok" },
                 data: {
                   type: :object,
                   properties: {
                     option: { "$ref" => "#/components/schemas/AssessmentQuestionOption" },
                     selection_count: { type: :integer, example: 0 },
                     selection_percentage: { type: :number, example: 0.0 },
                   },
                 },
                 errors: { type: :array, items: { type: :object } },
                 notes: { type: :array, items: { type: :string }, example: ["Question option created successfully"] },
               },
               examples: {
                 option_created: {
                   summary: "Option created successfully",
                   value: {
                     status: "ok",
                     data: {
                       option: {
                         id: 1,
                         text: { "en" => "JavaScript" },
                         order: 1,
                         is_correct_answer: true,
                         points: "15.0",
                         has_assigned_points: true,
                         metadata: nil,
                         created_at: "2024-01-01T00:00:00.000Z",
                         updated_at: "2024-01-01T00:00:00.000Z",
                       },
                       selection_count: 0,
                       selection_percentage: 0.0,
                     },
                     errors: [],
                     notes: ["Question option created successfully"],
                   },
                 },
               }
        let(:question_id) { question.id }
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:option) do
          {
            option: {
              text: { "en" => "JavaScript" },
              order: 3,
              is_correct_answer: true,
              points: 15,
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["option"]["text"]).to eq("JavaScript")
          expect(data["data"]["option"]["is_correct_answer"]).to eq(true)
          expect(data["data"]["option"]["points"].to_f).to eq(15.0)
          expect(data["notes"]).to include("Question option created successfully")
        end
      end

      response "422", "invalid question type" do
        let!(:text_question) do
          question = build(:assessment_question, assessment: assessment, assessment_section: section, order: 2)
          question.text = "What is your name?"
          question.type = "AssessmentQuestions::RichText"
          question.save!
          question
        end
        let(:question_id) { text_question.id }
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:option) do
          {
            option: {
              text: { "en" => "Invalid option" },
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("validation_error")
          expect(data["errors"].first["message"]).to include("does not support options")
        end
      end

      response "403", "forbidden - not admin" do
        let(:question_id) { question.id }
        let(:Authorization) { "Bearer #{user_token}" }
        let(:option) do
          {
            option: {
              text: { "en" => "New option" },
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_error")
        end
      end

      response "422", "invalid option data" do
        let(:question_id) { question.id }
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:option) do
          {
            option: {
              text: { "en" => "" }, # Invalid: empty text
              points: "invalid",    # Invalid: non-numeric points
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("validation_error")
        end
      end
    end
  end

  path "/api/v1/admin/questions/{question_id}/options/{id}" do
    parameter name: :question_id, in: :path, type: :integer, description: "Question ID"
    parameter name: :id, in: :path, type: :integer, description: "Option ID"

    get "Get question option details (admin)" do
      tags "Admin - Question Options"
      description "Retrieve details of a specific question option (admin only)"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "option found" do
        let(:question_id) { question.id }
        let(:id) { option1.id }
        let(:Authorization) { "Bearer #{admin_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["option"]["id"]).to eq(option1.id)
          expect(data["data"]["option"]["text"]).to eq("Ruby")
          expect(data["data"]["option"]["is_correct_answer"]).to eq(true)
          expect(data["data"]["statistics"]).to be_a(Hash)
          expect(data["notes"]).to include("Question option retrieved successfully")
        end
      end

      response "404", "option not found" do
        let(:question_id) { question.id }
        let(:id) { 99999 }
        let(:Authorization) { "Bearer #{admin_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("not_found_error")
        end
      end
    end

    patch "Update question option (admin)" do
      tags "Admin - Question Options"
      description "Update a question option (admin only)"
      produces "application/json"
      consumes "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :option, in: :body, description: "Option data for update", schema: {
                  type: :object,
                  properties: {
                    option: {
                      type: :object,
                      description: "Option attributes to update",
                      properties: {
                        text: {
                          type: :object,
                          description: "Option text in multiple languages",
                          example: { "en" => "Updated Ruby" },
                        },
                        order: {
                          type: :integer,
                          description: "Display order",
                          example: 1,
                          minimum: 1,
                        },
                        is_correct_answer: {
                          type: :boolean,
                          description: "Whether this is a correct answer",
                          example: true,
                        },
                        points: {
                          type: :integer,
                          description: "Points awarded for selecting this option",
                          example: 20,
                        },
                      },
                    },
                  },
                  required: ["option"],
                  example: {
                    option: {
                      text: { "en" => "Ruby on Rails" },
                      is_correct_answer: true,
                      points: 20,
                    },
                  },
                }

      response "200", "option updated" do
        let(:question_id) { question.id }
        let(:id) { option1.id }
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:option) do
          {
            option: {
              text: { "en" => "Ruby on Rails" },
              is_correct_answer: true,
              points: 20,
            },
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["option"]["text"]).to eq("Ruby on Rails")
          expect(data["data"]["option"]["points"].to_f).to eq(20.0)
          expect(data["notes"]).to include("Question option updated successfully")
        end
      end

      response "403", "forbidden - not admin" do
        let(:question_id) { question.id }
        let(:id) { option1.id }
        let(:Authorization) { "Bearer #{user_token}" }
        let(:option) do
          {
            option: {
              text: { "en" => "Updated option" },
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

    delete "Delete question option (admin)" do
      tags "Admin - Question Options"
      description "Delete a question option (admin only)"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "option deleted" do
        let(:question_id) { question.id }
        let!(:option_to_delete) { create(:assessment_question_option, assessment_question: question, text: { "en" => "Delete me" }, order: 10) }
        let(:id) { option_to_delete.id }
        let(:Authorization) { "Bearer #{admin_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["deleted_id"]).to eq(option_to_delete.id)
          expect(data["notes"].first).to include("Question option")
          expect(data["notes"].first).to include("deleted successfully")
        end
      end

      response "422", "cannot delete - minimum options required" do
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
                       message: { type: :string, example: "Cannot delete option: Question must have at least 2 options" },
                       details: { type: :object, example: { "minimum_required" => 2 } },
                     },
                   },
                 },
                 notes: { type: :array, items: { type: :string } },
               },
               examples: {
                 minimum_options_error: {
                   summary: "Cannot delete - minimum options required",
                   value: {
                     status: "error",
                     data: {},
                     errors: [{
                       error_code: "validation_error",
                       message: "Cannot delete option: Question must have at least 2 options",
                       details: { "minimum_required" => 2 },
                     }],
                     notes: [],
                   },
                 },
               }
        let(:question_id) { question.id }
        let(:id) { option1.id }
        let(:Authorization) { "Bearer #{admin_token}" }

        before do
          # Delete option2 to leave only 2 options, then try to delete another
          option2.destroy
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("validation_error")
          expect(data["errors"].first["message"]).to include("minimum 2 options required")
        end
      end

      response "403", "forbidden - not admin" do
        let(:question_id) { question.id }
        let(:id) { option1.id }
        let(:Authorization) { "Bearer #{user_token}" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_error")
        end
      end
    end
  end

  path "/api/v1/admin/questions/{question_id}/options/reorder" do
    parameter name: :question_id, in: :path, type: :integer, description: "Question ID"

    post "Reorder question options (admin)" do
      tags "Admin - Question Options"
      description "Reorder question options by providing new order (admin only)"
      produces "application/json"
      consumes "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :reorder_params, in: :body, description: "Reorder parameters", schema: {
        type: :object,
        properties: {
          option_orders: {
            type: :array,
            items: { type: :integer },
            description: "Array of option IDs in the desired order",
            example: [2, 1, 3],
          },
        },
        required: ["option_orders"],
        example: {
          option_orders: [2, 1, 3],
        },
      }

      response "200", "options reordered" do
        schema type: :object,
               properties: {
                 status: { type: :string, example: "ok" },
                 data: {
                   type: :object,
                   properties: {
                     options: {
                       type: :array,
                       items: { "$ref" => "#/components/schemas/AssessmentQuestionOption" },
                     },
                     reordered_count: { type: :integer, example: 2 },
                   },
                 },
                 errors: { type: :array, items: { type: :object } },
                 notes: { type: :array, items: { type: :string }, example: ["Question options reordered successfully"] },
               },
               examples: {
                 options_reordered: {
                   summary: "Options successfully reordered",
                   value: {
                     status: "ok",
                     data: {
                       options: [
                         {
                           id: 2,
                           text: { "en" => "Python" },
                           order: 1,
                           is_correct_answer: false,
                         },
                         {
                           id: 1,
                           text: { "en" => "JavaScript" },
                           order: 2,
                           is_correct_answer: true,
                         },
                       ],
                       reordered_count: 2,
                     },
                     errors: [],
                     notes: ["Question options reordered successfully"],
                   },
                 },
               }
        let(:question_id) { question.id }
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:reorder_params) { { option_orders: [option2.id, option1.id] } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["reordered_count"]).to eq(2)
          expect(data["data"]["options"]).to be_an(Array)
          expect(data["notes"]).to include("Question options reordered successfully")
        end
      end

      response "404", "invalid option ID" do
        let(:question_id) { question.id }
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:reorder_params) { { option_orders: [99999, option1.id] } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("not_found_error")
        end
      end
    end
  end
end
