require "swagger_helper"

RSpec.describe "Api::V1::Admin::MarkingRules", type: :request do
  let!(:admin_user) { create(:user, :admin) }
  let!(:regular_user) { create(:user) }
  let!(:admin_session) { create(:session, user: admin_user) }
  let!(:user_session) { create(:session, user: regular_user) }
  let(:Authorization) { nil }
  let(:admin_token) { admin_session.token }
  let(:user_token) { user_session.token }

  let!(:assessment) { create(:assessment) }
  let!(:section) { create(:assessment_section, assessment: assessment) }
  let!(:question) { create(:assessment_question, assessment: assessment, assessment_section: section, type: "AssessmentQuestions::MultipleChoice") }
  let!(:marking_scheme) { assessment.assessment_marking_schemes.create!(name: "Default Scheme", total_possible_score: 100) }

  path "/api/v1/admin/assessments/{assessment_id}/marking-schemes/{marking_scheme_id}/rules" do
    parameter name: :assessment_id, in: :path, type: :integer, description: "Assessment ID"
    parameter name: :marking_scheme_id, in: :path, type: :integer, description: "Marking Scheme ID"

    get "List marking rules (admin)" do
      tags "Admin - Marking Rules"
      description "List marking rules for a scheme, with pagination and filters"
      produces "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false
      parameter name: :is_active, in: :query, type: :boolean, required: false
      parameter name: :question_id, in: :query, type: :integer, required: false

      response "200", "marking rules found" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:assessment_id) { assessment.id }
        let(:marking_scheme_id) { marking_scheme.id }

        before do
          marking_scheme.assessment_question_marking_rules.create!(assessment_question: question, rule_type: "option_based", points: 10, order: 1)
        end

        schema type: :object,
               properties: {
                 status: { type: :string },
                 data: {
                   type: :object,
                   properties: {
                     marking_rules: {
                       type: :array,
                       items: { "$ref" => "#/components/schemas/MarkingRule" },
                     },
                     total_count: { type: :integer },
                     active_count: { type: :integer },
                     pagination: { type: :object },
                     assessment: { type: :object },
                     marking_scheme: { type: :object },
                   },
                 },
                 errors: { type: :array, items: { "$ref" => "#/components/schemas/Error" } },
                 notes: { type: :array, items: { type: :string } },
               }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["marking_rules"]).to be_an(Array)
          expect(data["notes"]).to include("Marking rules retrieved successfully")
        end
      end

      response "403", "forbidden - not admin" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:assessment_id) { assessment.id }
        let(:marking_scheme_id) { marking_scheme.id }

        schema "$ref" => "#/components/schemas/ApiResponse"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_error")
        end
      end

      response "401", "unauthorized" do
        let(:assessment_id) { assessment.id }
        let(:marking_scheme_id) { marking_scheme.id }

        schema "$ref" => "#/components/schemas/ApiResponse"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("invalid_token_error")
        end
      end
    end

    post "Create marking rule (admin)" do
      tags "Admin - Marking Rules"
      description "Create a marking rule for a question under a scheme"
      produces "application/json"
      consumes "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :marking_rule, in: :body, description: "Marking rule attributes. rule_type defaults from the question's default if omitted; points default based on question type.", schema: {
        type: :object,
        properties: {
          marking_rule: {
            oneOf: [
              {
                type: :object,
                description: "MultipleChoice / Radio / BooleanType rule (option_based)",
                properties: {
                  assessment_question_id: { type: :integer, description: "Target question ID (MultipleChoice/Radio/BooleanType)", example: 100 },
                  rule_type: { type: :string, enum: ["option_based"], description: "Must be 'option_based' for choice questions", example: "option_based" },
                  points: { type: :number, description: "Default points for correct answers without explicit option points", example: 10 },
                  is_active: { type: :boolean, description: "Activate this rule", example: true },
                  order: { type: :integer, description: "Rule evaluation order (1..N)", example: 1 },
                  criteria: {
                    type: :object,
                    description: "Option-based criteria",
                    properties: {
                      partial_scoring: { type: :boolean, description: "Award partial points for subsets of correct options", example: true },
                      negative_scoring: { type: :boolean, description: "Deduct points for wrong selections (if supported)", example: false },
                    },
                    example: { partial_scoring: true },
                  },
                },
                required: ["assessment_question_id", "rule_type"],
                example: {
                  assessment_question_id: 100,
                  rule_type: "option_based",
                  points: 10,
                  is_active: true,
                  criteria: { partial_scoring: true },
                },
              },
              {
                type: :object,
                description: "RangeType rule (range_based)",
                properties: {
                  assessment_question_id: { type: :integer, description: "Target RangeType question ID", example: 101 },
                  rule_type: { type: :string, enum: ["range_based"], description: "Must be 'range_based' for RangeType", example: "range_based" },
                  points: { type: :number, description: "Points when value within min..max (plus optional tolerance)", example: 5 },
                  is_active: { type: :boolean, description: "Activate this rule", example: true },
                  order: { type: :integer, description: "Rule evaluation order (1..N)", example: 1 },
                  criteria: {
                    type: :object,
                    description: "Range definition",
                    properties: {
                      min: { type: :number, description: "Minimum inclusive", example: 1 },
                      max: { type: :number, description: "Maximum inclusive", example: 5 },
                      tolerance: { type: :number, description: "Allowed deviation from bounds", example: 0 },
                    },
                    required: ["min", "max"],
                    example: { min: 1, max: 5, tolerance: 0 },
                  },
                },
                required: ["assessment_question_id", "rule_type", "points", "criteria"],
              },
              {
                type: :object,
                description: "DateType rule (tolerance_based)",
                properties: {
                  assessment_question_id: { type: :integer, description: "Target DateType question ID", example: 102 },
                  rule_type: { type: :string, enum: ["tolerance_based"], description: "Must be 'tolerance_based' for date proximity", example: "tolerance_based" },
                  points: { type: :number, description: "Points when within tolerance of expected date", example: 5 },
                  is_active: { type: :boolean, description: "Activate this rule", example: true },
                  order: { type: :integer, description: "Rule evaluation order (1..N)", example: 1 },
                  criteria: {
                    type: :object,
                    description: "Expected date and tolerance",
                    properties: {
                      expected_value: { type: :number, description: "Expected date encoded (e.g., YYYYMMDD)", example: 20240101 },
                      tolerance: { type: :number, description: "Permitted deviation (units per implementation)", example: 2 },
                    },
                    required: ["expected_value", "tolerance"],
                    example: { expected_value: 20240101, tolerance: 2 },
                  },
                },
                required: ["assessment_question_id", "rule_type", "points", "criteria"],
              },
              {
                type: :object,
                description: "RichText rule (partial_match / exact_match / keyword_based)",
                properties: {
                  assessment_question_id: { type: :integer, description: "Target RichText question ID", example: 103 },
                  rule_type: { type: :string, enum: ["partial_match", "exact_match", "keyword_based"], description: "Supported text rule types", example: "partial_match" },
                  points: { type: :number, description: "Max points when the rule is satisfied", example: 15 },
                  is_active: { type: :boolean, description: "Activate this rule", example: true },
                  order: { type: :integer, description: "Rule evaluation order (1..N)", example: 1 },
                  criteria: {
                    type: :object,
                    description: "Text matching criteria",
                    properties: {
                      expected_values: { type: :array, items: { type: :string }, description: "Phrases to match (partial/exact)", example: ["safety", "compliance"] },
                      partial_match_threshold: { type: :number, description: "Threshold for partial match similarity (0-1)", example: 0.7 },
                      scoring_method: { type: :string, enum: ["proportional", "all_or_nothing"], description: "How to award points for matches", example: "proportional" },
                      case_sensitive: { type: :boolean, description: "Apply case sensitivity for exact match", example: false },
                      trim_whitespace: { type: :boolean, description: "Trim whitespace before comparison", example: true },
                    },
                    example: { expected_values: ["safety", "compliance"], partial_match_threshold: 0.7, scoring_method: "proportional" },
                  },
                },
                required: ["assessment_question_id", "rule_type", "points"],
              },
              {
                type: :object,
                description: "FileUpload rule (file_based / size_based / type_based)",
                properties: {
                  assessment_question_id: { type: :integer, description: "Target FileUpload question ID", example: 104 },
                  rule_type: { type: :string, enum: ["file_based", "size_based", "type_based"], description: "Supported file rule types", example: "file_based" },
                  points: { type: :number, description: "Points awarded when file satisfies constraints", example: 5 },
                  is_active: { type: :boolean, description: "Activate this rule", example: true },
                  order: { type: :integer, description: "Rule evaluation order (1..N)", example: 1 },
                  criteria: {
                    type: :object,
                    description: "File constraints / policies",
                    properties: {
                      file_criteria: {
                        type: :object,
                        description: "Constraints object for file-based validation",
                        properties: {
                          allowed_types: { type: :array, items: { type: :string }, description: "Allowed MIME types", example: ["application/pdf"] },
                          max_size: { type: :integer, description: "Max file size in bytes", example: 1_048_576 },
                        },
                      },
                      max_size: { type: :integer, description: "Max file size (for size_based)", example: 1_048_576 },
                      allowed_types: { type: :array, items: { type: :string }, description: "Allowed MIME types (for type_based)", example: ["image/png", "image/jpeg"] },
                    },
                    example: { file_criteria: { allowed_types: ["application/pdf"], max_size: 1_048_576 } },
                  },
                },
                required: ["assessment_question_id", "rule_type", "points"],
              },
            ],
          },
        },
        required: ["marking_rule"],
      }

      response "200", "marking rule created" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:assessment_id) { assessment.id }
        let(:marking_scheme_id) { marking_scheme.id }
        let(:marking_rule) do
          {
            marking_rule: {
              assessment_question_id: question.id,
              rule_type: "option_based",
              points: 10,
              is_active: true,
              criteria: { partial_scoring: true },
            },
          }
        end

        schema type: :object,
               properties: {
                 status: { type: :string },
                 data: {
                   type: :object,
                   properties: {
                     marking_rule: { "$ref" => "#/components/schemas/MarkingRule" },
                   },
                 },
                 errors: { type: :array, items: { "$ref" => "#/components/schemas/Error" } },
                 notes: { type: :array, items: { type: :string } },
               }

        # Custom examples for different question types
        example "application/json", :multiple_choice_example, {
          status: "ok",
          data: {
            marking_rule: {
              id: 1,
              rule_type: "option_based",
              points: 10,
              is_active: true,
              order: 1,
              criteria: { partial_scoring: true },
              assessment_question: { id: 100, type: "AssessmentQuestions::MultipleChoice", sub_type: nil },
              marking_scheme: { id: 1 },
              created_at: "2025-01-01T00:00:00Z",
              updated_at: "2025-01-01T00:00:00Z",
            },
          },
          errors: [],
          notes: ["Marking rule created successfully"],
        }, "Create rule for MultipleChoice (option_based)"

        example "application/json", :range_type_example, {
          status: "ok",
          data: {
            marking_rule: {
              id: 2,
              rule_type: "range_based",
              points: 5,
              is_active: true,
              order: 1,
              criteria: { min: 1, max: 5, tolerance: 0 },
              assessment_question: { id: 101, type: "AssessmentQuestions::RangeType", sub_type: nil },
              marking_scheme: { id: 1 },
              created_at: "2025-01-01T00:00:00Z",
              updated_at: "2025-01-01T00:00:00Z",
            },
          },
          errors: [],
          notes: ["Marking rule created successfully"],
        }, "Create rule for RangeType (range_based)"

        example "application/json", :date_type_example, {
          status: "ok",
          data: {
            marking_rule: {
              id: 3,
              rule_type: "tolerance_based",
              points: 5,
              is_active: true,
              order: 1,
              criteria: { expected_value: 20240101, tolerance: 2 },
              assessment_question: { id: 102, type: "AssessmentQuestions::DateType", sub_type: nil },
              marking_scheme: { id: 1 },
              created_at: "2025-01-01T00:00:00Z",
              updated_at: "2025-01-01T00:00:00Z",
            },
          },
          errors: [],
          notes: ["Marking rule created successfully"],
        }, "Create rule for DateType (tolerance_based)"

        example "application/json", :rich_text_example, {
          status: "ok",
          data: {
            marking_rule: {
              id: 4,
              rule_type: "partial_match",
              points: 15,
              is_active: true,
              order: 1,
              criteria: { expected_values: ["safety", "compliance"], partial_match_threshold: 0.7, scoring_method: "proportional" },
              assessment_question: { id: 103, type: "AssessmentQuestions::RichText", sub_type: nil },
              marking_scheme: { id: 1 },
              created_at: "2025-01-01T00:00:00Z",
              updated_at: "2025-01-01T00:00:00Z",
            },
          },
          errors: [],
          notes: ["Marking rule created successfully"],
        }, "Create rule for RichText (partial_match)"

        example "application/json", :file_upload_example, {
          status: "ok",
          data: {
            marking_rule: {
              id: 5,
              rule_type: "file_based",
              points: 5,
              is_active: true,
              order: 1,
              criteria: { file_criteria: { allowed_types: ["application/pdf"], max_size: 1048576 } },
              assessment_question: { id: 104, type: "AssessmentQuestions::FileUpload", sub_type: nil },
              marking_scheme: { id: 1 },
              created_at: "2025-01-01T00:00:00Z",
              updated_at: "2025-01-01T00:00:00Z",
            },
          },
          errors: [],
          notes: ["Marking rule created successfully"],
        }, "Create rule for FileUpload (file_based)"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["marking_rule"]["rule_type"]).to eq("option_based")
          expect(data["notes"]).to include("Marking rule created successfully")
        end
      end

      response "422", "validation failed" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:assessment_id) { assessment.id }
        let(:marking_scheme_id) { marking_scheme.id }
        let(:marking_rule) do
          { marking_rule: { assessment_question_id: question.id, rule_type: "__invalid__" } }
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
        let(:marking_scheme_id) { marking_scheme.id }
        let(:marking_rule) do
          { marking_rule: { assessment_question_id: question.id } }
        end

        schema "$ref" => "#/components/schemas/ApiResponse"

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("error")
          expect(data["errors"].first["error_code"]).to eq("authorization_error")
        end
      end

      response "401", "unauthorized" do
        let(:assessment_id) { assessment.id }
        let(:marking_scheme_id) { marking_scheme.id }
        let(:marking_rule) do
          { marking_rule: { assessment_question_id: question.id } }
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

  path "/api/v1/admin/assessments/{assessment_id}/marking-schemes/{marking_scheme_id}/rules/bulk_create" do
    parameter name: :assessment_id, in: :path, type: :integer, description: "Assessment ID"
    parameter name: :marking_scheme_id, in: :path, type: :integer, description: "Marking Scheme ID"

    post "Bulk create missing rules (admin)" do
      tags "Admin - Marking Rules"
      description "Auto-generate marking rules for questions without rules"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "rules created" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:assessment_id) { assessment.id }
        let(:marking_scheme_id) { marking_scheme.id }

        before do
          # ensure at least one question without a rule exists
          question
        end

        schema type: :object,
               properties: {
                 status: { type: :string },
                 data: {
                   type: :object,
                   properties: {
                     created_count: { type: :integer },
                     marking_rules: { type: :array, items: { "$ref" => "#/components/schemas/MarkingRule" } },
                   },
                 },
                 errors: { type: :array, items: { "$ref" => "#/components/schemas/Error" } },
                 notes: { type: :array, items: { type: :string } },
               }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq("ok")
          expect(data["data"]["created_count"]).to be_a(Integer)
        end
      end

      response "403", "forbidden - not admin" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:assessment_id) { assessment.id }
        let(:marking_scheme_id) { marking_scheme.id }

        schema "$ref" => "#/components/schemas/ApiResponse"

        run_test!
      end
    end
  end

  path "/api/v1/admin/assessments/{assessment_id}/marking-schemes/{marking_scheme_id}/rules/rule_types" do
    parameter name: :assessment_id, in: :path, type: :integer, description: "Assessment ID"
    parameter name: :marking_scheme_id, in: :path, type: :integer, description: "Marking Scheme ID"
    parameter name: :question_id, in: :query, type: :integer, description: "Question ID"

    get "Get available rule types for a question (admin)" do
      tags "Admin - Marking Rules"
      description "List available rule types for the given question"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "rule types returned" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:assessment_id) { assessment.id }
        let(:marking_scheme_id) { marking_scheme.id }
        let(:question_id) { question.id }

        schema type: :object,
               properties: {
                 status: { type: :string },
                 data: {
                   type: :object,
                   properties: {
                     rule_types: {
                       type: :array,
                       items: { type: :object, properties: { key: { type: :string }, name: { type: :string }, description: { type: :string } } },
                     },
                     default: { type: :string },
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
        let(:marking_scheme_id) { marking_scheme.id }
        let(:question_id) { question.id }

        schema "$ref" => "#/components/schemas/ApiResponse"

        run_test!
      end
    end
  end

  path "/api/v1/admin/assessments/{assessment_id}/marking-schemes/{marking_scheme_id}/rules/criteria_fields" do
    parameter name: :assessment_id, in: :path, type: :integer, description: "Assessment ID"
    parameter name: :marking_scheme_id, in: :path, type: :integer, description: "Marking Scheme ID"
    parameter name: :rule_type, in: :query, type: :string, description: "Rule type key"

    get "Get criteria fields for rule type (admin)" do
      tags "Admin - Marking Rules"
      description "List criteria fields definition for a rule type"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "criteria fields returned" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:assessment_id) { assessment.id }
        let(:marking_scheme_id) { marking_scheme.id }
        let(:rule_type) { "option_based" }

        schema type: :object,
               properties: {
                 status: { type: :string },
                 data: {
                   type: :object,
                   properties: {
                     criteria_fields: { type: :array, items: { type: :object } },
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
        let(:marking_scheme_id) { marking_scheme.id }
        let(:rule_type) { "option_based" }

        schema "$ref" => "#/components/schemas/ApiResponse"

        run_test!
      end
    end
  end

  path "/api/v1/admin/assessments/{assessment_id}/marking-schemes/{marking_scheme_id}/rules/{id}" do
    parameter name: :assessment_id, in: :path, type: :integer, description: "Assessment ID"
    parameter name: :marking_scheme_id, in: :path, type: :integer, description: "Marking Scheme ID"
    parameter name: :id, in: :path, type: :integer, description: "Marking Rule ID"

    patch "Update marking rule (admin)" do
      tags "Admin - Marking Rules"
      description "Update a marking rule"
      produces "application/json"
      consumes "application/json"
      security [{ bearerAuth: [] }]

      parameter name: :marking_rule, in: :body, description: "Marking rule fields to update.", schema: {
        type: :object,
        properties: {
          marking_rule: {
            type: :object,
            description: "Marking rule attributes",
            properties: {
              rule_type: { type: :string, description: "Rule type key", example: "option_based" },
              points: { type: :number, description: "Points for the rule", example: 12 },
              is_active: { type: :boolean, description: "Whether the rule is active", example: true },
              order: { type: :integer, description: "Display/evaluation order", example: 2 },
              criteria: { type: :object, description: "Rule-specific criteria object" },
            },
          },
        },
        required: ["marking_rule"],
        example: {
          marking_rule: {
            points: 12,
            is_active: true,
          },
        },
      }

      response "200", "marking rule updated" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:assessment_id) { assessment.id }
        let(:marking_scheme_id) { marking_scheme.id }
        let!(:rule) { marking_scheme.assessment_question_marking_rules.create!(assessment_question: question, rule_type: "option_based", points: 10) }
        let(:id) { rule.id }
        let(:marking_rule) do
          { marking_rule: { points: 12 } }
        end

        schema type: :object,
               properties: {
                 status: { type: :string },
                 data: {
                   type: :object,
                   properties: {
                     marking_rule: { "$ref" => "#/components/schemas/MarkingRule" },
                   },
                 },
                 errors: { type: :array, items: { "$ref" => "#/components/schemas/Error" } },
                 notes: { type: :array, items: { type: :string } },
               }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["data"]["marking_rule"]["points"]).to eq(12)
        end
      end

      response "403", "forbidden - not admin" do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:assessment_id) { assessment.id }
        let(:marking_scheme_id) { marking_scheme.id }
        let!(:rule) { marking_scheme.assessment_question_marking_rules.create!(assessment_question: question, rule_type: "option_based", points: 10) }
        let(:id) { rule.id }
        let(:marking_rule) do
          { marking_rule: { points: 12 } }
        end

        schema "$ref" => "#/components/schemas/ApiResponse"

        run_test!
      end
    end

    delete "Delete marking rule (admin)" do
      tags "Admin - Marking Rules"
      description "Delete a marking rule"
      produces "application/json"
      security [{ bearerAuth: [] }]

      response "200", "marking rule deleted" do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:assessment_id) { assessment.id }
        let(:marking_scheme_id) { marking_scheme.id }
        let!(:rule) { marking_scheme.assessment_question_marking_rules.create!(assessment_question: question, rule_type: "option_based", points: 10) }
        let(:id) { rule.id }

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
        let(:marking_scheme_id) { marking_scheme.id }
        let(:id) { 0 }

        schema "$ref" => "#/components/schemas/ApiResponse"

        run_test!
      end
    end
  end

  # Create tests for each question type and typical rule type
  describe "Create marking rules per question type", document: false do
    let!(:section2) { create(:assessment_section, assessment: assessment, order: (assessment.assessment_sections.maximum(:order).to_i + 1)) }

    path "/api/v1/admin/assessments/{assessment_id}/marking-schemes/{marking_scheme_id}/rules" do
      parameter name: :assessment_id, in: :path, type: :integer, description: "Assessment ID"
      parameter name: :marking_scheme_id, in: :path, type: :integer, description: "Marking Scheme ID"

      post "Create rule for MultipleChoice (option_based)" do
        tags "Admin - Marking Rules - MultipleChoice"
        operationId "create_rule_multiple_choice_option_based"
        description "Create an option_based rule for MultipleChoice question"
        produces "application/json"
        consumes "application/json"
        security [{ bearerAuth: [] }]

        let!(:mc_question) { create(:assessment_question, assessment: assessment, assessment_section: section2, type: "AssessmentQuestions::MultipleChoice") }

        parameter name: :marking_rule, in: :body, description: "Rule attributes for option_based scoring", schema: {
          type: :object,
          properties: {
            marking_rule: {
              type: :object,
              description: "Marking rule attributes",
              properties: {
                assessment_question_id: { type: :integer, description: "Target MultipleChoice question ID", example: 1 },
                rule_type: { type: :string, description: "Use 'option_based' for MultipleChoice/Radio/Boolean", example: "option_based" },
                points: { type: :number, description: "Default points when correct option has no explicit points", example: 10 },
                is_active: { type: :boolean, description: "Activate the rule", example: true },
                criteria: { type: :object, description: "Option-based flags", example: { partial_scoring: true } },
              },
              required: ["assessment_question_id", "rule_type"],
            },
          },
          required: ["marking_rule"],
        }

        response "200", "rule created" do
          let(:Authorization) { "Bearer #{admin_token}" }
          let(:assessment_id) { assessment.id }
          let(:marking_scheme_id) { marking_scheme.id }
          let(:marking_rule) do
            { marking_rule: { assessment_question_id: mc_question.id, rule_type: "option_based", points: 10, is_active: true, criteria: { partial_scoring: true } } }
          end

          schema "$ref" => "#/components/schemas/ApiResponse"

          run_test!
        end
      end

      post "Create rule for RangeType (range_based)" do
        tags "Admin - Marking Rules - RangeType"
        operationId "create_rule_range_type_range_based"
        description "Create a range_based rule for RangeType question"
        produces "application/json"
        consumes "application/json"
        security [{ bearerAuth: [] }]

        let!(:range_question) { create(:assessment_question, assessment: assessment, assessment_section: section2, type: "AssessmentQuestions::RangeType") }

        parameter name: :marking_rule, in: :body, description: "Rule attributes for range_based scoring", schema: {
          type: :object,
          properties: {
            marking_rule: {
              type: :object,
              properties: {
                assessment_question_id: { type: :integer, description: "Target RangeType question ID", example: 1 },
                rule_type: { type: :string, description: "Use 'range_based' for numeric range questions", example: "range_based" },
                points: { type: :number, description: "Points if value falls in range", example: 5 },
                criteria: { type: :object, description: "Range definition", example: { min: 1, max: 5, tolerance: 0 } },
              },
              required: ["assessment_question_id", "rule_type", "points"],
            },
          },
          required: ["marking_rule"],
        }

        response "200", "rule created" do
          let(:Authorization) { "Bearer #{admin_token}" }
          let(:assessment_id) { assessment.id }
          let(:marking_scheme_id) { marking_scheme.id }
          let(:marking_rule) do
            { marking_rule: { assessment_question_id: range_question.id, rule_type: "range_based", points: 5, criteria: { min: 1, max: 5, tolerance: 0 } } }
          end

          schema "$ref" => "#/components/schemas/ApiResponse"

          run_test!
        end
      end

      post "Create rule for DateType (tolerance_based)" do
        tags "Admin - Marking Rules - DateType"
        operationId "create_rule_date_type_tolerance_based"
        description "Create a tolerance_based rule for DateType question"
        produces "application/json"
        consumes "application/json"
        security [{ bearerAuth: [] }]

        let!(:date_question) { create(:assessment_question, assessment: assessment, assessment_section: section2, type: "AssessmentQuestions::DateType") }

        parameter name: :marking_rule, in: :body, description: "Rule attributes for tolerance-based date scoring", schema: {
          type: :object,
          properties: {
            marking_rule: {
              type: :object,
              properties: {
                assessment_question_id: { type: :integer, description: "Target DateType question ID", example: 1 },
                rule_type: { type: :string, description: "Use 'tolerance_based' for proximity to expected value", example: "tolerance_based" },
                points: { type: :number, description: "Points if within tolerance", example: 5 },
                criteria: { type: :object, description: "Expected value and tolerance", example: { expected_value: 20240101, tolerance: 2 } },
              },
              required: ["assessment_question_id", "rule_type", "points"],
            },
          },
          required: ["marking_rule"],
        }

        response "200", "rule created" do
          let(:Authorization) { "Bearer #{admin_token}" }
          let(:assessment_id) { assessment.id }
          let(:marking_scheme_id) { marking_scheme.id }
          let(:marking_rule) do
            { marking_rule: { assessment_question_id: date_question.id, rule_type: "tolerance_based", points: 5, criteria: { expected_value: 20240101, tolerance: 2 } } }
          end

          schema "$ref" => "#/components/schemas/ApiResponse"

          run_test!
        end
      end

      post "Create rule for RichText (partial_match)" do
        tags "Admin - Marking Rules - RichText"
        operationId "create_rule_rich_text_partial_match"
        description "Create a partial_match rule for RichText question"
        produces "application/json"
        consumes "application/json"
        security [{ bearerAuth: [] }]

        let!(:rt_question) { create(:assessment_question, assessment: assessment, assessment_section: section2, type: "AssessmentQuestions::RichText") }

        parameter name: :marking_rule, in: :body, description: "Rule attributes for partial match text scoring", schema: {
          type: :object,
          properties: {
            marking_rule: {
              type: :object,
              properties: {
                assessment_question_id: { type: :integer, description: "Target RichText question ID", example: 1 },
                rule_type: { type: :string, description: "Use 'partial_match' for keyword similarity", example: "partial_match" },
                points: { type: :number, description: "Max points when threshold satisfied", example: 15 },
                criteria: { type: :object, description: "Expected phrases and threshold", example: { expected_values: ["safety", "compliance"], partial_match_threshold: 0.7, scoring_method: "proportional" } },
              },
              required: ["assessment_question_id", "rule_type", "points"],
            },
          },
          required: ["marking_rule"],
        }

        response "200", "rule created" do
          let(:Authorization) { "Bearer #{admin_token}" }
          let(:assessment_id) { assessment.id }
          let(:marking_scheme_id) { marking_scheme.id }
          let(:marking_rule) do
            { marking_rule: { assessment_question_id: rt_question.id, rule_type: "partial_match", points: 15, criteria: { expected_values: ["safety", "compliance"], partial_match_threshold: 0.7, scoring_method: "proportional" } } }
          end

          schema "$ref" => "#/components/schemas/ApiResponse"

          run_test!
        end
      end

      post "Create rule for FileUpload (file_based)" do
        tags "Admin - Marking Rules - FileUpload"
        operationId "create_rule_file_upload_file_based"
        description "Create a file_based rule for FileUpload question"
        produces "application/json"
        consumes "application/json"
        security [{ bearerAuth: [] }]

        let!(:file_question) { create(:assessment_question, assessment: assessment, assessment_section: section2, type: "AssessmentQuestions::FileUpload") }

        parameter name: :marking_rule, in: :body, description: "Rule attributes for file constraints", schema: {
          type: :object,
          properties: {
            marking_rule: {
              type: :object,
              properties: {
                assessment_question_id: { type: :integer, description: "Target FileUpload question ID", example: 1 },
                rule_type: { type: :string, description: "Use 'file_based' for validating file type/size", example: "file_based" },
                points: { type: :number, description: "Awarded points if file meets criteria", example: 5 },
                criteria: { type: :object, description: "File constraints", example: { file_criteria: { allowed_types: ["application/pdf"], max_size: 1048576 } } },
              },
              required: ["assessment_question_id", "rule_type", "points"],
            },
          },
          required: ["marking_rule"],
        }

        response "200", "rule created" do
          let(:Authorization) { "Bearer #{admin_token}" }
          let(:assessment_id) { assessment.id }
          let(:marking_scheme_id) { marking_scheme.id }
          let(:marking_rule) do
            { marking_rule: { assessment_question_id: file_question.id, rule_type: "file_based", points: 5, criteria: { file_criteria: { allowed_types: ["application/pdf"], max_size: 1_048_576 } } } }
          end

          schema "$ref" => "#/components/schemas/ApiResponse"

          run_test!
        end
      end
    end
  end
end
