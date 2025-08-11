# == Schema Information
#
# Table name: assessment_question_options
#
#  id                     :bigint           not null, primary key
#  default_locale         :string
#  is_correct_answer      :boolean          default(FALSE)
#  metadata               :jsonb
#  order                  :integer
#  points                 :decimal(10, 2)   default(0.0)
#  text                   :jsonb
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  assessment_id          :bigint           not null
#  assessment_question_id :bigint           not null
#
# Indexes
#
#  index_assessment_question_options_on_assessment_id           (assessment_id)
#  index_assessment_question_options_on_assessment_question_id  (assessment_question_id)
#  index_assessment_question_options_on_is_correct_answer       (is_correct_answer)
#  index_assessment_question_options_on_points                  (points)
#
# Foreign Keys
#
#  fk_rails_...  (assessment_id => assessments.id)
#  fk_rails_...  (assessment_question_id => assessment_questions.id)
#
class AssessmentQuestionOption < ApplicationRecord
  extend Mobility

  belongs_to :assessment
  belongs_to :assessment_question

  has_many :selected_options, dependent: :destroy
  has_many :assessment_question_responses, through: :selected_options

  translates :text, backend: :jsonb

  # Validations
  validates :text, presence: true
  validates :order, presence: true, numericality: { greater_than: 0 }
  validates :points, numericality: true, allow_nil: true

  # Scopes
  scope :ordered, -> { order(:order) }

  # Marking methods
  def correct_answer?
    is_correct_answer?
  end

  def has_points?
    points.present? && points > 0
  end

  def has_assigned_points?
    points.present? && points != 0
  end

  def display_points
    return "0" unless has_points?
    points.to_s
  end

  # Callbacks
  after_initialize :ensure_text_initialized
  after_save :queue_translation_job, if: :should_auto_translate?

  # Public method to get localized text
  def localized_text(locale = nil)
    locale ||= Current.locale.to_s
    text_data = read_attribute(:text) || {}

    # Handle nested hash structure from Mobility gem
    if text_data.is_a?(Hash) && text_data[locale].present?
      text_value = text_data[locale]
      # If the value is another hash, extract the actual text
      if text_value.is_a?(Hash) && text_value[locale].present?
        text_value[locale]
      elsif text_value.is_a?(Hash) && text_value["en"].present?
        text_value["en"]
      elsif text_value.is_a?(Hash) && text_value.values.first.present?
        text_value.values.first
      else
        text_value.to_s
      end
    elsif text_data.is_a?(Hash) && text_data["en"].present?
      text_value = text_data["en"]
      # If the value is another hash, extract the actual text
      if text_value.is_a?(Hash) && text_value["en"].present?
        text_value["en"]
      elsif text_value.is_a?(Hash) && text_value.values.first.present?
        text_value.values.first
      else
        text_value.to_s
      end
    elsif text_data.is_a?(Hash) && text_data.values.first.present?
      text_value = text_data.values.first
      # If the value is another hash, extract the actual text
      if text_value.is_a?(Hash) && text_value.values.first.present?
        text_value.values.first
      else
        text_value.to_s
      end
    else
      ""
    end
  end

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

  def ensure_text_initialized
    self.text ||= {}
  end
end
