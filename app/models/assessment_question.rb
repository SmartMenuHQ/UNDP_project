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

  translates :text, backend: :jsonb

  # Validations
  validates :text, presence: true, length: { minimum: 3, maximum: 1000 }
  validates :type, presence: true
  validates :order, presence: true, numericality: { greater_than: 0 }
  validates :order, uniqueness: { scope: :assessment_section_id }

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
    when 'AssessmentQuestions::MultipleChoice'
      'check-square'
    when 'AssessmentQuestions::Radio'
      'circle-dot'
    when 'AssessmentQuestions::BooleanType'
      'toggle-left'
    when 'AssessmentQuestions::DateType'
      'calendar'
    when 'AssessmentQuestions::RangeType'
      'sliders'
    when 'AssessmentQuestions::RichText'
      'file-text'
    when 'AssessmentQuestions::FileUpload'
      'upload'
    else
      'help-circle'
    end
  end

  def question_type_color
    case type
    when 'AssessmentQuestions::MultipleChoice'
      'blue'
    when 'AssessmentQuestions::Radio'
      'green'
    when 'AssessmentQuestions::BooleanType'
      'purple'
    when 'AssessmentQuestions::DateType'
      'orange'
    when 'AssessmentQuestions::RangeType'
      'red'
    when 'AssessmentQuestions::RichText'
      'indigo'
    when 'AssessmentQuestions::FileUpload'
      'yellow'
    else
      'gray'
    end
  end

  def required_label
    is_required? ? 'Required' : 'Optional'
  end

  def required_badge_color
    is_required? ? 'red' : 'gray'
  end

  def display_text
    text.presence || "Question #{order}"
  end

  def can_be_deleted?
    true # Add business logic here if needed
  end

  def preview_data
    {
      id: id,
      text: text,
      type: question_type_name,
      required: is_required?,
      options: respond_to?(:options) ? options : nil
    }
  end

  after_save :queue_translation_job, if: :should_auto_translate?

  private

  def should_auto_translate?
    saved_change_to_text? && text.present?
  end

  def queue_translation_job
    return unless Rails.application.config.auto_translation_enabled

    source_locale = default_locale || 'en'

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
