# == Schema Information
#
# Table name: assessment_response_sessions
#
#  id                 :bigint           not null, primary key
#  completed_at       :datetime
#  feedback           :text
#  grade              :string
#  marked_at          :datetime
#  max_possible_score :decimal(10, 2)   default(0.0)
#  metadata           :jsonb
#  respondent_name    :string           not null
#  started_at         :datetime
#  state              :string           default("draft"), not null
#  submitted_at       :datetime
#  total_score        :decimal(10, 2)   default(0.0)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  assessment_id      :bigint           not null
#  user_id            :bigint           not null
#
# Indexes
#
#  index_assessment_response_sessions_on_assessment_id            (assessment_id)
#  index_assessment_response_sessions_on_assessment_id_and_state  (assessment_id,state)
#  index_assessment_response_sessions_on_completed_at             (completed_at)
#  index_assessment_response_sessions_on_marked_at                (marked_at)
#  index_assessment_response_sessions_on_started_at               (started_at)
#  index_assessment_response_sessions_on_state                    (state)
#  index_assessment_response_sessions_on_submitted_at             (submitted_at)
#  index_assessment_response_sessions_on_total_score              (total_score)
#  index_assessment_response_sessions_on_user_id                  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (assessment_id => assessments.id)
#  fk_rails_...  (user_id => users.id)
#
class AssessmentResponseSession < ApplicationRecord
  include AASM

  # Associations
  belongs_to :assessment
  belongs_to :user
  has_many :assessment_question_responses, dependent: :destroy
  has_many :assessment_response_scores, through: :assessment_question_responses

  # Validations
  validates :respondent_name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :state, presence: true
  validates :user_id, uniqueness: { scope: :assessment_id }
  validates :total_score, :max_possible_score, numericality: { greater_than_or_equal_to: 0 }

  # Store accessor for metadata
  store_accessor :metadata, :browser_info, :ip_address, :session_data, :time_spent, :question_times

  # Scopes
  scope :by_state, ->(state) { where(state: state) }
  scope :by_assessment, ->(assessment) { where(assessment: assessment) }
  scope :recent, -> { order(created_at: :desc) }
  scope :completed_between, ->(start_date, end_date) { where(completed_at: start_date..end_date) }
  scope :with_user, -> { where.not(user_id: nil) }
  scope :anonymous, -> { where(user_id: nil) }

  # AASM State Machine
  aasm column: :state do
    # States
    state :draft, initial: true
    state :started
    state :in_progress
    state :completed
    state :submitted
    state :under_review
    state :marked
    state :published
    state :cancelled
    state :expired

    # Events and Transitions
    event :start do
      transitions from: :draft, to: :started, after: :record_start_time
    end

    event :begin_answering do
      transitions from: [:draft, :started], to: :in_progress
    end

    event :complete do
      transitions from: [:started, :in_progress], to: :completed,
                  after: :record_completion_time,
                  guard: :all_required_questions_answered?
    end

    event :submit do
      transitions from: :completed, to: :submitted,
                  after: :record_submission_time
    end

    event :send_for_review do
      transitions from: :submitted, to: :under_review
    end

    event :mark do
      transitions from: [:submitted, :under_review], to: :marked,
                  after: :record_marking_time
    end

    event :queue_marking do
      transitions from: [:submitted, :under_review], to: :under_review,
                  after: :enqueue_marking_job
    end

    event :publish_results do
      transitions from: :marked, to: :published
    end

    event :cancel do
      transitions from: [:draft, :started, :in_progress], to: :cancelled
    end

    event :expire do
      transitions from: [:draft, :started, :in_progress, :completed], to: :expired
    end

    event :reopen do
      transitions from: [:cancelled, :expired], to: :in_progress
    end

    event :reset do
      transitions to: :draft, after: :reset_session_data
    end
  end

  # Callbacks
  after_initialize :ensure_metadata_initialized
  before_save :update_progress_metadata

  # Instance Methods

  def duration
    return nil unless started_at && (completed_at || Time.current)
    ((completed_at || Time.current) - started_at).to_i
  end

  def duration_formatted
    return "Not started" unless duration

    hours = duration / 3600
    minutes = (duration % 3600) / 60
    seconds = duration % 60

    if hours > 0
      "#{hours}h #{minutes}m #{seconds}s"
    elsif minutes > 0
      "#{minutes}m #{seconds}s"
    else
      "#{seconds}s"
    end
  end

  def completion_percentage
    total_questions = assessment.assessment_questions.count
    return 0 if total_questions.zero?

    answered_questions = assessment_question_responses.joins(:assessment_question)
      .where(assessment_questions: { is_required: true })
      .count
    (answered_questions.to_f / total_questions * 100).round(2)
  end

  def score_percentage
    return 0 if max_possible_score.zero?
    (total_score / max_possible_score * 100).round(2)
  end

  def passed?
    return false unless marked?

    active_scheme = assessment.assessment_marking_schemes.find_by(is_active: true)
    return false unless active_scheme&.passing_score

    score_percentage >= active_scheme.passing_score.to_f
  end

  def can_be_completed?
    all_required_questions_answered?
  end

  # Visibility methods using the new VisibilityResolver
  def visible_questions
    assessment.visible_questions_for_session(self)
  end

  def visible_sections
    assessment.visible_sections_for_session(self)
  end

  def question_visible?(question)
    assessment.question_visible_to_session?(question, self)
  end

  def section_visible?(section)
    assessment.section_visible_to_session?(section, self)
  end

  def next_visible_question(current_question = nil)
    assessment.next_visible_question_for_session(self, current_question)
  end

  def previous_visible_question(current_question)
    assessment.previous_visible_question_for_session(self, current_question)
  end

  def next_visible_section(current_section = nil)
    assessment.next_visible_section_for_session(self, current_section)
  end

  def previous_visible_section(current_section)
    assessment.previous_visible_section_for_session(self, current_section)
  end

  def visible_questions_in_section(section)
    assessment.visible_questions_in_section_for_session(section, self)
  end

  def section_completion_percentage(section)
    visible_questions = assessment.visible_questions_in_section_for_session(section, self)
    return 100 if visible_questions.empty?

    answered_count = visible_questions.count do |question|
      assessment_question_responses.exists?(assessment_question: question)
    end

    (answered_count.to_f / visible_questions.count * 100).round(1)
  end

  # Check if all required visible questions have been answered
  def all_required_visible_questions_answered?
    assessment.session_can_complete?(self)
  end

  # New helpers for navigation and access control
  def first_visible_section
    visible_sections.first
  end

  def all_required_visible_questions_answered_before_section?(section)
    sections = visible_sections
    idx = sections.index(section)
    return true if idx.nil? || idx.zero?

    preceding = sections[0...idx]
    preceding.all? do |sec|
      required_questions = visible_questions_in_section(sec).select(&:is_required)
      required_questions.all? do |q|
        resp = assessment_question_responses.find_by(assessment_question: q)
        resp&.has_valid_response?
      end
    end
  end

  def can_access_section?(section)
    section_visible?(section) && all_required_visible_questions_answered_before_section?(section)
  end

  def responses_for_question(question)
    assessment_question_responses.find_by(assessment_question: question)
  end

  def create_response_for_question(question, value)
    response = assessment_question_responses.find_or_initialize_by(
      assessment_question: question,
      assessment: assessment,
    )

    response.response_value = value
    response.save!
    response
  end

  def calculate_final_score!
    return unless can_be_marked?

    active_scheme = assessment.assessment_marking_schemes.find_by(is_active: true)
    return unless active_scheme

    total_earned = 0
    total_possible = 0

    assessment_question_responses.includes(:assessment_question).each do |response|
      score = response.grade_response(active_scheme.id)
      total_earned += score.score_earned
      total_possible += score.max_possible_score
    end

    update!(
      total_score: total_earned,
      max_possible_score: total_possible,
      grade: calculate_letter_grade(total_earned, total_possible, active_scheme),
    )
  end

  def generate_feedback!
    return unless marked?

    active_scheme = assessment.assessment_marking_schemes.find_by(is_active: true)
    return unless active_scheme&.settings&.dig("feedback_templates")

    template = active_scheme.settings["feedback_templates"][grade]
    self.feedback = template if template.present?
    save!
  end

  # Marking methods
  def mark_in_background!(marking_scheme_id = nil)
    if can_be_marked?
      MarkingJob.perform_later(id, marking_scheme_id)
      queue_marking! if may_queue_marking?
      true
    else
      false
    end
  end

  def mark_synchronously!(marking_scheme_id = nil)
    if can_be_marked?
      MarkingJob.perform_now(id, marking_scheme_id)
      true
    else
      false
    end
  end

  # Class Methods
  def self.for_user(user, assessment)
    find_by(user: user, assessment: assessment)
  end

  def self.create_for_user(user, assessment, metadata = {})
    create!(
      assessment: assessment,
      user: user,
      respondent_name: user.full_name.presence || "Anonymous",
      state: "draft",
      metadata: metadata,
    )
  end

  def self.bulk_mark_in_background(session_ids, marking_scheme_id = nil)
    BulkMarkingJob.perform_later(session_ids, marking_scheme_id)
  end

  def self.stats_for_assessment(assessment)
    sessions = where(assessment: assessment)

    {
      total: sessions.count,
      by_state: sessions.group(:state).count,
      average_score: sessions.where.not(total_score: 0).average(:total_score)&.round(2) || 0,
      pass_rate: calculate_pass_rate(sessions),
      average_duration: calculate_average_duration(sessions),
    }
  end

  private

  def record_start_time
    update_column(:started_at, Time.current)
  end

  def record_completion_time
    update_column(:completed_at, Time.current)
  end

  def record_submission_time
    update_column(:submitted_at, Time.current)
  end

  def record_marking_time
    update_column(:marked_at, Time.current)
  end

  def enqueue_marking_job
    MarkingJob.perform_later(id)
    Rails.logger.info "Queued marking job for session #{id}"
  end

  def reset_session_data
    update!(
      started_at: nil,
      completed_at: nil,
      submitted_at: nil,
      marked_at: nil,
      total_score: 0.0,
      max_possible_score: 0.0,
      grade: nil,
      feedback: nil,
    )

    # Clear all responses
    assessment_question_responses.destroy_all
  end

  def all_required_questions_answered?
    # Use the new visibility-aware method
    all_required_visible_questions_answered?
  end

  def calculate_letter_grade(earned, possible, scheme)
    return "F" if possible.zero?

    percentage = (earned / possible * 100).round(2)
    boundaries = scheme.settings&.dig("grade_boundaries") || {}

    boundaries.each do |grade, threshold|
      return grade if percentage >= threshold
    end

    "F"
  end

  def ensure_metadata_initialized
    self.metadata ||= {}
  end

  def update_progress_metadata
    if metadata_changed?
      self.metadata["last_updated"] = Time.current.iso8601
      self.metadata["completion_percentage"] = completion_percentage
    end
  end

  def self.calculate_pass_rate(sessions)
    marked_sessions = sessions.where(state: ["marked", "published"])
    return 0 if marked_sessions.empty?

    passed = marked_sessions.select(&:passed?).count
    (passed.to_f / marked_sessions.count * 100).round(2)
  end

  def self.calculate_average_duration(sessions)
    durations = sessions.where.not(started_at: nil, completed_at: nil)
      .pluck(:started_at, :completed_at)
      .map { |start, finish| start && finish ? (finish - start).to_i : nil }
      .compact

    return "0m" if durations.empty?

    average_seconds = durations.sum / durations.count

    hours = average_seconds / 3600
    minutes = (average_seconds % 3600) / 60

    if hours > 0
      "#{hours}h #{minutes}m"
    else
      "#{minutes}m"
    end
  end
end
