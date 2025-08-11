# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join("swagger").to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "Questionnaire CMS API",
        version: "v1",
        description: "API for managing assessments, questions, and user responses with advanced features like conditional visibility, country restrictions, and comprehensive marking systems.",
        contact: {
          name: "API Support",
          email: "support@questionnaire-cms.com",
        },
      },
      paths: {},
      servers: [
        {
          url: "http://localhost:3000",
          description: "Development server",
        },
        {
          url: "https://{defaultHost}",
          variables: {
            defaultHost: {
              default: "api.questionnaire-cms.com",
            },
          },
          description: "Production server",
        },
      ],
      components: {
        securitySchemes: {
          bearerAuth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: "Token",
          },
        },
        schemas: {
          User: {
            type: :object,
            properties: {
              id: { type: :integer },
              email_address: { type: :string, format: :email },
              first_name: { type: :string },
              last_name: { type: :string },
              full_name: { type: :string },
              display_name: { type: :string },
              admin: { type: :boolean },
              profile_completed: { type: :boolean },
              default_language: { type: :string },
              country: { "$ref" => "#/components/schemas/Country" },
              created_at: { type: :string, format: "date-time" },
              updated_at: { type: :string, format: "date-time" },
            },
          },
          Country: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              code: { type: :string },
              display_name: { type: :string },
              region: { type: :string },
              active: { type: :boolean },
              sort_order: { type: :integer },
            },
          },
          Assessment: {
            type: :object,
            properties: {
              id: { type: :integer },
              title: { type: :string },
              description: { type: :string },
              active: { type: :boolean },
              has_country_restrictions: { type: :boolean },
              restricted_countries: { type: :array, items: { type: :string } },
              sections_count: { type: :integer },
              questions_count: { type: :integer },
              created_at: { type: :string, format: "date-time" },
              updated_at: { type: :string, format: "date-time" },
            },
          },
          AssessmentSection: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              order: { type: :integer },
              metadata: { type: :object },
              is_conditional: { type: :boolean },
              trigger_question_id: { type: :integer },
              trigger_response_type: { type: :string, enum: ["option_selected", "value_equals", "value_range"] },
              trigger_values: { type: :array, items: { type: :string } },
              operator: { type: :string, enum: ["equals", "not_equals", "contains", "greater_than", "less_than", "between", "any", "all", "none"] },
              has_country_restrictions: { type: :boolean },
              restricted_countries: { type: :array, items: { type: :string } },
              restricted_country_names: { type: :array, items: { type: :string } },
              questions_count: { type: :integer },
              created_at: { type: :string, format: "date-time" },
              updated_at: { type: :string, format: "date-time" },
            },
          },
          AssessmentQuestion: {
            type: :object,
            properties: {
              id: { type: :integer },
              text: {
                type: :string,
                description: "Text content in the current user's locale (Mobility gem)",
                example: "What is your name?",
              },
              type: { type: :string },
              question_type: { type: :string },
              question_type_name: { type: :string },
              sub_type: { type: :string, nullable: true },
              order: { type: :integer },
              is_required: { type: :boolean },
              active: { type: :boolean },
              meta_data: { type: :object },
              is_conditional: { type: :boolean },
              trigger_question_id: { type: :integer },
              trigger_response_type: { type: :string, enum: ["option_selected", "value_equals", "value_range"] },
              trigger_values: { type: :array, items: { type: :string } },
              operator: { type: :string, enum: ["equals", "not_equals", "contains", "greater_than", "less_than", "between", "any", "all", "none"] },
              has_country_restrictions: { type: :boolean },
              restricted_countries: { type: :array, items: { type: :string } },
              restricted_country_names: { type: :array, items: { type: :string } },
              options: { type: :array, items: { "$ref" => "#/components/schemas/AssessmentQuestionOption" } },
              section: { "$ref" => "#/components/schemas/AssessmentSection" },
              created_at: { type: :string, format: "date-time" },
              updated_at: { type: :string, format: "date-time" },
            },
          },
          AssessmentQuestionOption: {
            type: :object,
            properties: {
              id: { type: :integer },
              text: {
                type: :string,
                description: "Text content in the current user's locale (Mobility gem)",
                example: "Option 1",
              },
              order: { type: :integer },
              is_correct_answer: { type: :boolean },
              points: { type: [:number, :string], nullable: true },
              has_assigned_points: { type: :boolean },
              metadata: { type: :object, nullable: true },
              selection_count: { type: :integer },
              selection_percentage: { type: :number },
              created_at: { type: :string, format: "date-time" },
              updated_at: { type: :string, format: "date-time" },
            },
          },
          AssessmentResponseSession: {
            type: :object,
            properties: {
              id: { type: :integer },
              respondent_name: { type: :string },
              state: { type: :string, enum: ["draft", "started", "submitted", "completed"] },
              started_at: { type: :string, format: "date-time", nullable: true },
              completed_at: { type: :string, format: "date-time", nullable: true },
              submitted_at: { type: :string, format: "date-time", nullable: true },
              marked_at: { type: :string, format: "date-time", nullable: true },
              total_score: { type: [:number, :string] },
              max_possible_score: { type: [:number, :string] },
              score_percentage: { type: [:number, :string], nullable: true },
              grade: { type: :string, nullable: true },
              feedback: { type: :string, nullable: true },
              progress_percentage: { type: [:number, :string], nullable: true },
              current_section_id: { type: :integer, nullable: true },
              current_question_id: { type: :integer, nullable: true },
              user: { "$ref" => "#/components/schemas/User" },
              assessment: { "$ref" => "#/components/schemas/Assessment" },
              created_at: { type: :string, format: "date-time", nullable: true },
              updated_at: { type: :string, format: "date-time", nullable: true },
            },
          },
          AssessmentQuestionResponse: {
            type: :object,
            properties: {
              id: { type: :integer },
              value: { type: :object },
              metadata: { type: :object },
              question: { "$ref" => "#/components/schemas/AssessmentQuestion" },
              selected_options: { type: :array, items: { "$ref" => "#/components/schemas/AssessmentQuestionOption" } },
              created_at: { type: :string, format: "date-time" },
              updated_at: { type: :string, format: "date-time" },
            },
          },
          # Business meta schemas
          BusinessStartMeta: {
            type: :object,
            properties: {
              first_section_id: { type: :integer, nullable: true, description: "ID of the first section user can access" },
              links: {
                type: :object,
                properties: {
                  show_section: { type: :string, nullable: true, description: "URL to fetch section details" },
                  submit_section: { type: :string, description: "URL to submit current section responses" },
                },
              },
            },
          },
          BusinessSubmitMeta: {
            type: :object,
            properties: {
              next_section_id: { type: :integer, nullable: true },
              previous_section_id: { type: :integer, nullable: true },
              links: {
                type: :object,
                properties: {
                  show_next_section: { type: :string, nullable: true },
                  show_previous_section: { type: :string, nullable: true },
                  submit_section: { type: :string },
                },
              },
              current_section_id: { type: :integer, nullable: true },
              missing_required_question_ids: { type: :array, items: { type: :integer } },
            },
          },
          BusinessSectionSubmitRequest: {
            type: :array,
            description: "Array of responses to save for the section",
            items: {
              type: :object,
              properties: {
                question_id: { type: :integer, description: "Question ID" },
                selected_option_ids: { type: :array, items: { type: :integer }, description: "Choice selection" },
                number: { type: :number, description: "Numeric input for range questions" },
                date: { type: :string, description: "Date input for date questions", example: "2025-01-01" },
                text: { type: :string, description: "Text input for rich text questions" },
                value: { type: :object, description: "Alternate structured value by type" },
              },
              required: ["question_id"],
            },
            example: [
              { question_id: 1, selected_option_ids: [10, 12] },
              { question_id: 2, number: 4 },
              { question_id: 3, text: "My answer" },
            ],
          },
          MarkingScheme: {
            type: :object,
            properties: {
              id: { type: :integer, example: 1 },
              name: { type: :string, description: "Human-readable name for the marking scheme", example: "Default Scheme" },
              description: { type: :string, nullable: true, description: "Optional description of the scheme's purpose", example: "Auto-grading scheme" },
              is_active: { type: :boolean, description: "Whether this scheme is the active one for its assessment", example: true },
              total_possible_score: { type: :number, description: "Total points available across all rules", example: 100 },
              settings: {
                type: :object,
                description: "Configuration settings for passing score, grade boundaries, and feedback templates",
                properties: {
                  passing_score: { type: :number, nullable: true, description: "Passing threshold as a percentage (0-100)", example: 60 },
                  grade_boundaries: {
                    type: :object,
                    nullable: true,
                    additionalProperties: { type: :number },
                    description: "Map of grade letter to minimum percentage threshold",
                    example: { "A": 90, "B": 80, "C": 70, "D": 60, "F": 0 },
                  },
                  feedback_templates: {
                    type: :object,
                    nullable: true,
                    additionalProperties: { type: :string },
                    description: "Map of grade letter to feedback message template",
                    example: { "A": "Excellent work!", "C": "Satisfactory performance" },
                  },
                },
              },
              assessment: {
                type: :object,
                properties: {
                  id: { type: :integer, example: 1 },
                },
              },
              created_at: { type: :string, format: "date-time", example: "2025-08-10T12:34:56Z" },
              updated_at: { type: :string, format: "date-time", example: "2025-08-10T12:34:56Z" },
            },
          },
          MarkingRule: {
            type: :object,
            properties: {
              id: { type: :integer, description: "Unique identifier of the marking rule", example: 10 },
              rule_type: {
                type: :string,
                description: "Type of rule to evaluate against the response",
                enum: [
                  "option_based", "range_based", "tolerance_based",
                  "partial_match", "exact_match", "keyword_based", "format_based",
                  "file_based", "size_based", "type_based",
                ],
                example: "option_based",
              },
              points: { type: :number, description: "Points awarded if the rule condition is satisfied", example: 10 },
              is_active: { type: :boolean, description: "Whether this rule participates in evaluation", example: true },
              order: { type: :integer, description: "Evaluation order for rules within the scheme (1..N)", example: 1 },
              criteria: {
                type: :object,
                description: "Rule-specific configuration. The schema varies depending on rule_type.",
                oneOf: [
                  {
                    description: "option_based criteria (MultipleChoice/Radio/BooleanType)",
                    type: :object,
                    properties: {
                      partial_scoring: { type: :boolean, description: "Award partial points for subsets of correct options", example: true },
                      negative_scoring: { type: :boolean, description: "Deduct points for wrong selections if enabled", example: false },
                    },
                    example: { partial_scoring: true },
                  },
                  {
                    description: "range_based criteria (RangeType)",
                    type: :object,
                    properties: {
                      min: { type: :number, description: "Minimum inclusive", example: 1 },
                      max: { type: :number, description: "Maximum inclusive", example: 5 },
                      tolerance: { type: :number, description: "Allowed deviation from min/max", example: 0 },
                    },
                    required: ["min", "max"],
                    example: { min: 1, max: 5, tolerance: 0 },
                  },
                  {
                    description: "tolerance_based criteria (DateType proximity)",
                    type: :object,
                    properties: {
                      expected_value: { type: :number, description: "Expected value (e.g., date encoded as YYYYMMDD)", example: 20240101 },
                      tolerance: { type: :number, description: "Permitted deviation from expected value", example: 2 },
                    },
                    required: ["expected_value", "tolerance"],
                    example: { expected_value: 20240101, tolerance: 2 },
                  },
                  {
                    description: "text-based criteria (RichText) for partial_match/exact_match/keyword_based/format_based",
                    type: :object,
                    minProperties: 1,
                    additionalProperties: false,
                    properties: {
                      expected_values: { type: :array, items: { type: :string }, description: "Phrases or exact values to compare against", example: ["safety", "compliance"] },
                      partial_match_threshold: { type: :number, description: "Similarity threshold for partial_match (0-1)", example: 0.7 },
                      scoring_method: { type: :string, enum: ["proportional", "all_or_nothing"], description: "How to award points for text matches", example: "proportional" },
                      case_sensitive: { type: :boolean, description: "Apply case sensitivity for exact match", example: false },
                      trim_whitespace: { type: :boolean, description: "Trim whitespace before comparison", example: true },
                      format_pattern: { type: :string, description: "Regex pattern for format_based rules (if used)", example: "^\\d{3}-\\d{3}$" },
                    },
                    example: { expected_values: ["safety", "compliance"], partial_match_threshold: 0.7, scoring_method: "proportional" },
                  },
                  {
                    description: "file-based criteria (FileUpload)",
                    type: :object,
                    minProperties: 1,
                    additionalProperties: false,
                    properties: {
                      file_criteria: {
                        type: :object,
                        description: "Constraints for file_based",
                        properties: {
                          allowed_types: { type: :array, items: { type: :string }, description: "Allowed MIME types", example: ["application/pdf"] },
                          max_size: { type: :integer, description: "Max file size in bytes", example: 1_048_576 },
                        },
                        additionalProperties: false,
                      },
                      max_size: { type: :integer, description: "Max file size (size_based)", example: 1_048_576 },
                      allowed_types: { type: :array, items: { type: :string }, description: "Allowed MIME types (type_based)", example: ["image/png", "image/jpeg"] },
                    },
                    example: { file_criteria: { allowed_types: ["application/pdf"], max_size: 1_048_576 } },
                  },
                ],
              },
              assessment_question: {
                type: :object,
                description: "Summary of the target question for this rule",
                properties: {
                  id: { type: :integer, description: "Question ID", example: 100 },
                  type: { type: :string, description: "Question STI type", example: "AssessmentQuestions::MultipleChoice" },
                  sub_type: { type: :string, nullable: true, description: "Optional sub-type hint (e.g., email/url)", example: nil },
                },
              },
              marking_scheme: {
                type: :object,
                description: "Summary of parent marking scheme",
                properties: {
                  id: { type: :integer, example: 1 },
                },
              },
              created_at: { type: :string, format: "date-time", description: "Creation timestamp" },
              updated_at: { type: :string, format: "date-time", description: "Last update timestamp" },
            },
          },
          Error: {
            type: :object,
            properties: {
              error_code: { type: :string },
              message: { type: :string },
              details: { type: :object },
            },
          },
          ApiResponse: {
            type: :object,
            properties: {
              status: { type: :string, enum: ["ok", "error", "redirect"] },
              data: { type: :object },
              errors: { type: :array, items: { "$ref" => "#/components/schemas/Error" } },
              notes: { type: :array, items: { type: :string } },
            },
          },
        },
      },
    },
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
