# == Schema Information
#
# Table name: assessment_questions
#
#  id                    :bigint           not null, primary key
#  active                :boolean          default(TRUE)
#  default_locale        :string
#  is_required           :boolean          default(FALSE)
#  meta_data             :jsonb
#  options_json          :jsonb
#  order                 :integer
#  sub_type              :string
#  text                  :jsonb
#  type                  :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  assessment_id         :bigint
#  assessment_section_id :bigint
#
# Indexes
#
#  index_assessment_questions_on_assessment_id          (assessment_id)
#  index_assessment_questions_on_assessment_section_id  (assessment_section_id)
#
class AssessmentQuestion < ApplicationRecord
  extend Mobility

  belongs_to :assessment
  belongs_to :assessment_section

  has_many :assessment_question_responses, dependent: :destroy

  translates :text, backend: :jsonb

  # Validations
  validates :text, presence: true, length: { minimum: 3, maximum: 1000 }
  validates :type, presence: true
  validates :order, presence: true, numericality: { greater_than: 0 }
  validates :order, uniqueness: { scope: :assessment_section_id }

  # Store accessor for custom validation rule set in meta_data
  store_accessor :meta_data, :custom_rule_set

  # Callbacks
  after_initialize :ensure_meta_data_initialized

  # Scopes
  scope :active, -> { where(active: true) }
  scope :required, -> { where(is_required: true) }
  scope :optional, -> { where(is_required: false) }
  scope :ordered, -> { order(:order) }

  # Instance methods
  def question_type_name
    type.demodulize.humanize
  end

  def question_type_icon
    case type
    when "AssessmentQuestions::MultipleChoice"
      "check-square"
    when "AssessmentQuestions::Radio"
      "circle-dot"
    when "AssessmentQuestions::BooleanType"
      "toggle-left"
    when "AssessmentQuestions::DateType"
      "calendar"
    when "AssessmentQuestions::RangeType"
      "sliders"
    when "AssessmentQuestions::RichText"
      "file-text"
    when "AssessmentQuestions::FileUpload"
      "upload"
    else
      "help-circle"
    end
  end

  def question_type_color
    case type
    when "AssessmentQuestions::MultipleChoice"
      "blue"
    when "AssessmentQuestions::Radio"
      "green"
    when "AssessmentQuestions::BooleanType"
      "purple"
    when "AssessmentQuestions::DateType"
      "orange"
    when "AssessmentQuestions::RangeType"
      "red"
    when "AssessmentQuestions::RichText"
      "indigo"
    when "AssessmentQuestions::FileUpload"
      "yellow"
    else
      "gray"
    end
  end

  def required_label
    is_required? ? "Required" : "Optional"
  end

  def required_badge_color
    is_required? ? "red" : "gray"
  end

  def display_text
    text.presence || "Question #{order}"
  end

  def can_be_deleted?
    true # Add business logic here if needed
  end

  # Helper method to get available sub-types for the current question type
  # Dynamically gets sub_types from the question type class enum if defined
  def available_sub_types
    return [] unless type

    # Get the question type class
    question_class = type.constantize rescue nil
    return [] unless question_class

    # Check if the class has sub_type enum defined
    return [] unless question_class.respond_to?(:sub_types)

    # Get the enum values and convert to display format
    question_class.sub_types.map do |key, value|
      [format_sub_type_name(key), value]
    end
  end

  # Helper method to get display name for current sub-type
  def sub_type_name
    return "Default" if sub_type.blank?

    found = available_sub_types.find { |name, value| value == sub_type }
    found ? found[0] : format_sub_type_name(sub_type)
  end

  # Validation rule methods
  def validation_rule_set
    rules = {}

    # Add required validation rule if question is required
    if is_required?
      rules["required"] = { "message" => "validation_errors.required" }
    end

    # Get default rules from the specific question type class
    rules.merge!(default_validation_rule_set_for_type || {})

    # Merge with custom rules (highest priority)
    rules.merge!(custom_rule_set || {})

    rules
  end

  def has_validation_rules?
    validation_rule_set.present?
  end

  def add_validation_rule(rule_name, rule_config)
    self.custom_rule_set = (custom_rule_set || {}).merge(rule_name.to_s => rule_config)
  end

  def remove_validation_rule(rule_name)
    return unless custom_rule_set.present?
    self.custom_rule_set = custom_rule_set.except(rule_name.to_s)
  end

  # Get available validation rules for this question type - delegated to specific question type
  def available_validation_rules
    available_validation_rules_for_type
  end

  protected

  # Default validation rules for this question type - override in subclasses
  def default_validation_rule_set_for_type
    {}
  end

  # Available validation rules for this question type - override in subclasses
  def available_validation_rules_for_type
    base_validation_rules
  end

  # Base validation rules available to all question types
  def base_validation_rules
    [
      "required" => { name: I18n.t("validation_errors.required"), description: I18n.t("validation_errors.required") },
    ]
  end

  private

  # Format sub_type names for display
  def format_sub_type_name(key)
    case key.to_s
    when "datetime"
      "Date & Time"
    when "short_text"
      "Short Text"
    when "long_text"
      "Long Text"
    when "rich_text"
      "Rich Text"
    when "radio_buttons"
      "Radio Buttons"
    when "button_group"
      "Button Group"
    when "number_input"
      "Number Input"
    when "toggle_buttons"
      "Toggle Buttons"
    else
      key.to_s.humanize
    end
  end

  def preview_data
    {
      id: id,
      text: text,
      type: question_type_name,
      required: is_required?,
      options: respond_to?(:options) ? options : nil,
    }
  end

  after_save :queue_translation_job, if: :should_auto_translate?

  private

  def should_auto_translate?
    saved_change_to_text? && text.present?
  end

  def queue_translation_job
    return unless Rails.application.config.auto_translation_enabled

    source_locale = default_locale || "en"

    # Skip if the source locale is not available
    return unless Rails.application.config.i18n.available_locales.include?(source_locale.to_sym)

    # Queue the translation job
    TranslationJob.perform_later(self.class.name, id, source_locale)

    Rails.logger.info "Queued translation job for #{self.class.name} ##{id} from #{source_locale}"
  end

  def ensure_meta_data_initialized
    self.meta_data ||= {}
  end
end
