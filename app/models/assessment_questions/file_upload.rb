# == Schema Information
#
# Table name: assessment_questions
#
#  id                     :bigint           not null, primary key
#  active                 :boolean          default(TRUE)
#  default_locale         :string
#  is_required            :boolean          default(FALSE)
#  meta_data              :jsonb
#  options_json           :jsonb
#  order                  :integer
#  text                   :text
#  type                   :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  assessment_sections_id :bigint
#  assessments_id         :bigint
#
# Indexes
#
#  index_assessment_questions_on_assessment_sections_id  (assessment_sections_id)
#  index_assessment_questions_on_assessments_id          (assessments_id)
#
# -*- SkipSchemaAnnotations
module AssessmentQuestions
  class FileUpload < AssessmentQuestion
    # Default configuration constants
    DEFAULT_ALLOWED_TYPES = [
      "image/jpeg",
      "image/png",
      "image/gif",
      "application/pdf",
      "application/msword",
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      "text/plain",
    ].freeze

    DEFAULT_MAX_FILE_SIZE = 10.megabytes # 10MB default
    # Validations
    validates :allowed_data_types, presence: true
    validates :max_file_size, presence: true, numericality: { greater_than: 0 }
    validate :validate_allowed_data_types_format
    validate :validate_max_file_size_reasonable

    # Store accessor for meta_data attributes
    store_accessor :meta_data, :allowed_data_types, :max_file_size, :upload_mode

    # Default validation rules for FileUpload questions
    def default_validation_rule_set_for_type
      rules = {}

      # Set default file size limit (10MB) if not configured
      file_size_limit = max_file_size.present? ? max_file_size : 10.megabytes
      rules["file_size"] = {
        "max_size" => file_size_limit,
        "message" => "default_rules.max_file_size",
      }

      # Set default allowed file types if not configured
      if allowed_data_types.present?
        rules["file_type"] = {
          "allowed_types" => allowed_data_types,
          "message" => "validation_errors.file_type_not_allowed",
        }
      else
        # Default to common document/image types
        default_types = ["pdf", "doc", "docx", "jpg", "jpeg", "png", "gif", "txt"]
        rules["file_type"] = {
          "allowed_types" => default_types,
          "message" => "validation_errors.file_type_not_allowed",
        }
      end

      rules
    end

    # Available validation rules for FileUpload questions
    def available_validation_rules_for_type
      base_validation_rules.concat([
        "file_size" => { name: "File Size Limit", description: "File size must not exceed limit" },
        "file_type" => { name: "File Type Restriction", description: "Only specific file types allowed" },
      ])
    end

    # Callbacks
    after_initialize :set_default_values

    # Override setter for max_file_size to ensure integer conversion
    def max_file_size=(value)
      super(value.present? ? value.to_i : nil)
    end

    # Override setter for upload_mode to validate values
    def upload_mode=(value)
      super(%w[single multiple].include?(value.to_s) ? value.to_s : nil)
    end

    # Override getters to provide defaults when values are nil
    def allowed_data_types
      super || DEFAULT_ALLOWED_TYPES
    end

    def max_file_size
      super || DEFAULT_MAX_FILE_SIZE
    end

    def upload_mode
      super || "single"
    end

    # Helper methods for checking upload mode
    def single_file?
      upload_mode == "single"
    end

    def multiple_files?
      upload_mode == "multiple"
    end

    private

    def set_default_values
      # Set default values for store_accessor attributes
      self.allowed_data_types ||= DEFAULT_ALLOWED_TYPES
      self.max_file_size ||= DEFAULT_MAX_FILE_SIZE
      self.upload_mode ||= "single"
    end

    def validate_allowed_data_types_format
      return if allowed_data_types.blank?

      unless allowed_data_types.is_a?(Array)
        errors.add(:allowed_data_types, "must be an array")
        return
      end

      if allowed_data_types.empty?
        errors.add(:allowed_data_types, "must contain at least one file type")
        return
      end

      allowed_data_types.each do |type|
        unless type.is_a?(String) && type.include?("/")
          errors.add(:allowed_data_types, "contains invalid MIME type: #{type}")
        end
      end
    end

    def validate_max_file_size_reasonable
      return if max_file_size.blank?

      max_file_size_int = max_file_size.to_i

      if max_file_size_int < 1.kilobyte
        errors.add(:max_file_size, "must be at least 1KB")
      elsif max_file_size_int > 100.megabytes
        errors.add(:max_file_size, "cannot exceed 100MB")
      end
    end

    public

    # Override setter for allowed_data_types to handle string input
    def allowed_data_types=(types)
      if types.is_a?(String)
        super([types])
      elsif types.is_a?(Array)
        super(types)
      else
        super(types)
      end
    end

    # Validation methods
    def validate_file_type(file)
      return true if file.blank?

      content_type = file.content_type
      return false if content_type.blank?

      allowed_data_types.include?(content_type)
    end

    def validate_file_size(file)
      return true if file.blank?

      file.size <= max_file_size
    end

    def validate_uploaded_file(file)
      errors = []

      unless validate_file_type(file)
        errors << "File type '#{file.content_type}' is not allowed. Allowed types: #{allowed_data_types.join(", ")}"
      end

      unless validate_file_size(file)
        errors << "File size #{file.size} bytes exceeds maximum allowed size of #{max_file_size} bytes (#{max_file_size_human})"
      end

      errors
    end

    # Helper methods for display
    def max_file_size_human
      if max_file_size >= 1.megabyte
        "#{max_file_size / 1.megabyte}MB"
      elsif max_file_size >= 1.kilobyte
        "#{max_file_size / 1.kilobyte}KB"
      else
        "#{max_file_size} bytes"
      end
    end

    def allowed_extensions
      allowed_data_types.map do |mime_type|
        case mime_type
        when "image/jpeg" then ".jpg, .jpeg"
        when "image/png" then ".png"
        when "image/gif" then ".gif"
        when "application/pdf" then ".pdf"
        when "application/msword" then ".doc"
        when "application/vnd.openxmlformats-officedocument.wordprocessingml.document" then ".docx"
        when "text/plain" then ".txt"
        else mime_type
        end
      end.join(", ")
    end

    # Configuration helpers
    def self.common_file_types
      {
        images: ["image/jpeg", "image/png", "image/gif"],
        documents: [
          "application/pdf",
          "application/msword",
          "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        ],
        text: ["text/plain"],
        all: DEFAULT_ALLOWED_TYPES,
      }
    end

    def configure_for_images_only
      self.allowed_data_types = self.class.common_file_types[:images]
      self.max_file_size = 5.megabytes
    end

    def configure_for_documents_only
      self.allowed_data_types = self.class.common_file_types[:documents]
      self.max_file_size = 20.megabytes
    end

    # Override to extract file information from response
    def extract_response_value(response)
      return response.value unless response.value.is_a?(Hash)

      # For file upload questions, extract file-related information
      response.value["file"] || response.value[:file] ||
      response.value["filename"] || response.value[:filename] ||
      response.value["files"] || response.value[:files] ||
      super
    end

    private

    def configure_for_all_types
      self.allowed_data_types = self.class.common_file_types[:all]
      self.max_file_size = DEFAULT_MAX_FILE_SIZE
    end
  end
end
