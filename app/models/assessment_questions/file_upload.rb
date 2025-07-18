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
      'image/jpeg',
      'image/png',
      'image/gif',
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'text/plain'
    ].freeze

    DEFAULT_MAX_FILE_SIZE = 10.megabytes # 10MB default

        # Validations
    validates :allowed_data_types, presence: true
    validates :max_file_size, presence: true, numericality: { greater_than: 0 }
    validate :validate_allowed_data_types_format
    validate :validate_max_file_size_reasonable

    # Callbacks
    after_initialize :set_default_values

    # Custom getter and setter methods for meta_data attributes
    def allowed_data_types
      ensure_meta_data_hash
      meta_data['allowed_data_types'] || DEFAULT_ALLOWED_TYPES
    end

    def allowed_data_types=(value)
      ensure_meta_data_hash
      meta_data['allowed_data_types'] = value
    end

    def max_file_size
      ensure_meta_data_hash
      meta_data['max_file_size'] || DEFAULT_MAX_FILE_SIZE
    end

    def max_file_size=(value)
      ensure_meta_data_hash
      meta_data['max_file_size'] = value.to_i if value.present?
    end

    private

    def ensure_meta_data_hash
      self.meta_data ||= {}
    end

    def set_default_values
      # Initialize meta_data as empty hash if nil
      ensure_meta_data_hash

      # Set default values for meta_data attributes
      self.allowed_data_types ||= DEFAULT_ALLOWED_TYPES
      self.max_file_size ||= DEFAULT_MAX_FILE_SIZE
    end

    def validate_allowed_data_types_format
      return if allowed_data_types.blank?

      unless allowed_data_types.is_a?(Array)
        errors.add(:allowed_data_types, 'must be an array')
        return
      end

      if allowed_data_types.empty?
        errors.add(:allowed_data_types, 'must contain at least one file type')
        return
      end

      allowed_data_types.each do |type|
        unless type.is_a?(String) && type.include?('/')
          errors.add(:allowed_data_types, "contains invalid MIME type: #{type}")
        end
      end
    end

    def validate_max_file_size_reasonable
      return if max_file_size.blank?

      max_file_size_int = max_file_size.to_i

      if max_file_size_int < 1.kilobyte
        errors.add(:max_file_size, 'must be at least 1KB')
      elsif max_file_size_int > 100.megabytes
        errors.add(:max_file_size, 'cannot exceed 100MB')
      end
    end

    public

    # Override setters to ensure proper types
    def allowed_data_types=(types)
      if types.is_a?(String)
        super([types])
      elsif types.is_a?(Array)
        super(types)
      else
        super(types)
      end
    end

    def max_file_size=(size)
      super(size.to_i) if size.present?
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
        errors << "File type '#{file.content_type}' is not allowed. Allowed types: #{allowed_data_types.join(', ')}"
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
        when 'image/jpeg' then '.jpg, .jpeg'
        when 'image/png' then '.png'
        when 'image/gif' then '.gif'
        when 'application/pdf' then '.pdf'
        when 'application/msword' then '.doc'
        when 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' then '.docx'
        when 'text/plain' then '.txt'
        else mime_type
        end
      end.join(', ')
    end

    # Configuration helpers
    def self.common_file_types
      {
        images: ['image/jpeg', 'image/png', 'image/gif'],
        documents: [
          'application/pdf',
          'application/msword',
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
        ],
        text: ['text/plain'],
        all: DEFAULT_ALLOWED_TYPES
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

    def configure_for_all_types
      self.allowed_data_types = self.class.common_file_types[:all]
      self.max_file_size = DEFAULT_MAX_FILE_SIZE
    end
  end
end
