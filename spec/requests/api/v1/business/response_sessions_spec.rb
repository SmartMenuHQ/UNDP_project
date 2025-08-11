require "swagger_helper"

RSpec.describe "Api::V1::Business::ResponseSessions", type: :request do
  let!(:user) { create(:user) }
  let!(:session_rec) { create(:session, user: user) }
  let(:Authorization) { "Bearer #{session_rec.token}" }

  let!(:assessment) { create(:assessment) }

  path "/api/v1/business/assessments/{assessment_id}/response-sessions" do
    parameter name: :assessment_id, in: :path, type: :integer, description: "Assessment ID", example: 1

    get "List my response sessions" do
      tags "Business - Response Sessions"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "sessions listed" do
        let(:assessment_id) { assessment.id }
        schema "$ref" => "#/components/schemas/ApiResponse"
        run_test!
      end
    end

    post "Create a new response session" do
      tags "Business - Response Sessions"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "session created" do
        let(:assessment_id) { assessment.id }
        schema "$ref" => "#/components/schemas/ApiResponse"
        example "application/json", :created_session, {
          status: "ok",
          data: {
            response_session: {
              id: 1000,
              state: "draft",
              respondent_name: "Jane Doe",
              assessment: { id: 1, title: "Example Assessment" },
            },
          },
          errors: [],
          notes: ["Response session created successfully"],
        }
        run_test!
      end
    end
  end

  path "/api/v1/business/assessments/{assessment_id}/response-sessions/{id}" do
    parameter name: :assessment_id, in: :path, type: :integer, description: "Assessment ID", example: 1
    parameter name: :id, in: :path, type: :integer, description: "Response Session ID", example: 42

    get "Get response session" do
      tags "Business - Response Sessions"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "session found" do
        let(:assessment_id) { assessment.id }
        let!(:resp_session) { assessment.assessment_response_sessions.create!(respondent_name: user.full_name, user: user) }
        let(:id) { resp_session.id }
        schema "$ref" => "#/components/schemas/ApiResponse"
        run_test!
      end
    end
  end

  path "/api/v1/business/assessments/{assessment_id}/response-sessions/{id}/start" do
    parameter name: :assessment_id, in: :path, type: :integer, description: "Assessment ID", example: 1
    parameter name: :id, in: :path, type: :integer, description: "Response Session ID", example: 42

    patch "Start session" do
      tags "Business - Response Sessions"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "session started with first section link" do
        let(:assessment_id) { assessment.id }
        let!(:section) { create(:assessment_section, assessment: assessment) }
        let!(:resp_session) { assessment.assessment_response_sessions.create!(respondent_name: user.full_name, user: user) }
        let(:id) { resp_session.id }
        schema type: :object, properties: {
          status: { type: :string },
          data: {
            type: :object,
            properties: {
              response_session: { "$ref" => "#/components/schemas/AssessmentResponseSession" },
              meta: { "$ref" => "#/components/schemas/BusinessStartMeta" },
            },
          },
          errors: { type: :array, items: { "$ref" => "#/components/schemas/Error" } },
          notes: { type: :array, items: { type: :string } },
        }
        example "application/json", :start_with_meta, {
          status: "ok",
          data: {
            response_session: {
              id: 42,
              state: "started",
              respondent_name: "Jane Doe",
              assessment: { id: 1, title: "Example Assessment" },
            },
            meta: {
              first_section_id: 10,
              links: {
                show_section: "/api/v1/business/assessments/1/response-sessions/42/sections/10",
                submit_section: "/api/v1/business/assessments/1/response-sessions/42/submit_section",
              },
            },
          },
          errors: [],
          notes: ["Session started successfully; first visible section provided in meta"],
        }
        run_test!
      end
    end
  end

  path "/api/v1/business/assessments/{assessment_id}/response-sessions/{id}/sections/{section_id}" do
    parameter name: :assessment_id, in: :path, type: :integer, description: "Assessment ID", example: 1
    parameter name: :id, in: :path, type: :integer, description: "Response Session ID", example: 42
    parameter name: :section_id, in: :path, type: :integer, description: "Section ID", example: 10

    get "Show section details and questions" do
      tags "Business - Response Sessions"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "section fetched" do
        let(:assessment_id) { assessment.id }
        let!(:section) { create(:assessment_section, assessment: assessment) }
        let!(:question) { create(:assessment_question, assessment: assessment, assessment_section: section, type: "AssessmentQuestions::RichText", is_required: true) }
        let!(:resp_session) { assessment.assessment_response_sessions.create!(respondent_name: user.full_name, user: user) }
        let(:id) { resp_session.id }
        let(:section_id) { section.id }
        schema type: :object, properties: {
          status: { type: :string },
          data: {
            type: :object,
            properties: {
              section: {
                allOf: [
                  { "$ref" => "#/components/schemas/AssessmentSection" },
                  {
                    type: :object,
                    properties: {
                      questions: { type: :array, items: { "$ref" => "#/components/schemas/AssessmentQuestion" } },
                    },
                  },
                ],
              },
            },
          },
          errors: { type: :array, items: { "$ref" => "#/components/schemas/Error" } },
          notes: { type: :array, items: { type: :string } },
        }
        example "application/json", :section_and_questions, {
          status: "ok",
          data: {
            section: { id: 10, name: "Introduction", order: 1, questions: [
              { id: 100, text: "What is your name?", type: "AssessmentQuestions::RichText", is_required: true, order: 1 },
            ] },
          },
          errors: [],
          notes: ["Section and visible questions fetched successfully"],
        }
        run_test!
      end
    end
  end

  path "/api/v1/business/assessments/{assessment_id}/response-sessions/{id}/section_responses/{section_id}" do
    parameter name: :assessment_id, in: :path, type: :integer, description: "Assessment ID", example: 1
    parameter name: :id, in: :path, type: :integer, description: "Response Session ID", example: 42
    parameter name: :section_id, in: :path, type: :integer, description: "Section ID", example: 10

    get "Section responses" do
      tags "Business - Response Sessions"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "responses fetched" do
        let(:assessment_id) { assessment.id }
        let!(:section) { create(:assessment_section, assessment: assessment) }
        let!(:question) { create(:assessment_question, assessment: assessment, assessment_section: section, type: "AssessmentQuestions::RichText", is_required: true) }
        let!(:resp_session) { assessment.assessment_response_sessions.create!(respondent_name: user.full_name, user: user, state: "started", started_at: Time.current) }
        let(:id) { resp_session.id }
        let(:section_id) { section.id }
        before { resp_session.create_response_for_question(question, { text: "Answer" }) }
        schema type: :object, properties: {
          status: { type: :string },
          data: {
            type: :object,
            properties: {
              section: { "$ref" => "#/components/schemas/AssessmentSection" },
              responses: { type: :array, items: { "$ref" => "#/components/schemas/AssessmentQuestionResponse" } },
            },
          },
          errors: { type: :array, items: { "$ref" => "#/components/schemas/Error" } },
          notes: { type: :array, items: { type: :string } },
        }
        example "application/json", :section_responses, {
          status: "ok",
          data: {
            section: { id: 10, name: "Introduction", order: 1 },
            responses: [
              { id: 200, value: { text: "Answer" }, metadata: {}, question: { id: 100 } },
            ],
          },
          errors: [],
          notes: ["Section responses fetched successfully"],
        }
        run_test!
      end
    end
  end

  path "/api/v1/business/assessments/{assessment_id}/response-sessions/{id}/sections/{section_id}/submit" do
    parameter name: :assessment_id, in: :path, type: :integer, description: "Assessment ID", example: 1
    parameter name: :id, in: :path, type: :integer, description: "Response Session ID", example: 42
    parameter name: :section_id, in: :path, type: :integer, description: "Section ID", example: 10

    patch "Submit current section responses" do
      tags "Business - Response Sessions"
      consumes "application/json"
      produces "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :responses, in: :body, required: false, description: "Array of responses to save for the section", schema: { "$ref" => "#/components/schemas/BusinessSectionSubmitRequest" }

      response "200", "submitted; meta has next/previous links or completion" do
        let(:assessment_id) { assessment.id }
        let!(:section) { create(:assessment_section, assessment: assessment) }
        let!(:question) { create(:assessment_question, assessment: assessment, assessment_section: section, type: "AssessmentQuestions::RichText", is_required: true) }
        let!(:resp_session) { assessment.assessment_response_sessions.create!(respondent_name: user.full_name, user: user, state: "started", started_at: Time.current) }
        let(:id) { resp_session.id }
        let(:section_id) { section.id }
        let(:responses) { [{ question_id: question.id, text: "Hello" }] }
        schema type: :object, properties: {
          status: { type: :string },
          data: {
            type: :object,
            properties: {
              response_session: { "$ref" => "#/components/schemas/AssessmentResponseSession" },
              meta: { "$ref" => "#/components/schemas/BusinessSubmitMeta" },
            },
          },
          errors: { type: :array, items: { "$ref" => "#/components/schemas/Error" } },
          notes: { type: :array, items: { type: :string } },
        }
        example "application/json", :submitted_with_links, {
          status: "ok",
          data: {
            response_session: {
              id: 42,
              state: "in_progress",
              assessment: { id: 1, title: "Example Assessment" },
            },
            meta: {
              next_section_id: 11,
              previous_section_id: 10,
              links: {
                show_next_section: "/api/v1/business/assessments/1/response-sessions/42/sections/11",
                show_previous_section: "/api/v1/business/assessments/1/response-sessions/42/sections/10",
                submit_section: "/api/v1/business/assessments/1/response-sessions/42/sections/10/submit",
              },
            },
          },
          errors: [],
          notes: ["Section submitted; navigation meta returned"],
        }
        run_test!
      end
    end
  end
end
