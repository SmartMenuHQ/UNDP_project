# -*- SkipSchemaAnnotations
module AssessmentQuestions
  class DateType < AssessmentQuestion
    # Explicit attribute declaration for enum
    attribute :sub_type, :string

    # Sub-types for date questions
    enum :sub_type, {
      date: "date",
      year: "year",
      datetime: "datetime",
      time: "time",
      month: "month",
      week: "week",
      date_range: "date_range",
    }

    # Validations
    validates :sub_type, presence: true

    # Default validation rules based on sub_type
    def default_validation_rule_set_for_type
      rules = {}

      case sub_type
      when "date_range"
        # Default to current year for date ranges
        rules["date_range"] = {
          "min_date" => Date.current.beginning_of_year.to_s,
          "max_date" => Date.current.end_of_year.to_s,
          "message" => "default_rules.current_year_range",
        }
      when "date"
        # Allow past and future dates by default, but validate format
        rules["date_format"] = {
          "message" => "default_rules.valid_date_format",
        }
      when "datetime"
        rules["datetime_format"] = {
          "message" => "default_rules.valid_datetime_format",
        }
      when "year"
        # Reasonable year range
        rules["year_range"] = {
          "min_year" => 1900,
          "max_year" => Date.current.year + 10,
          "message" => "default_rules.reasonable_year_range",
        }
      end

      rules
    end

    # Available validation rules for DateType questions
    def available_validation_rules_for_type
      base_validation_rules.concat([
        "date_range" => { name: "Date Range", description: "Date must be within specified range" },
        "future_date" => { name: "Future Date Only", description: "Date must be in the future" },
        "past_date" => { name: "Past Date Only", description: "Date must be in the past" },
      ])
    end

    # Set default sub_type if not specified
    after_initialize :set_default_sub_type, if: :new_record?

    # Override to extract date value from response
    def extract_response_value(response)
      return response.value unless response.value.is_a?(Hash)

      # For date questions, prioritize date field
      response.value["date"] || response.value[:date] ||
      response.value["start_date"] || response.value[:start_date] ||
      response.value["end_date"] || response.value[:end_date] ||
      super
    end

    private

    def set_default_sub_type
      self.sub_type ||= "date"
    end
  end
end
