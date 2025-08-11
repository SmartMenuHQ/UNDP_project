class ResponseSessionsController < ApplicationController
  before_action :set_assessment
  before_action :set_session, only: [:show, :edit, :update, :destroy, :start, :submit, :mark, :publish, :cancel, :reset]

  def index
    @sessions = @assessment.assessment_response_sessions
      .includes(:assessment_question_responses)
      .recent

    # Filter by state if provided
    @sessions = @sessions.by_state(params[:state]) if params[:state].present?

    # Filter by date range if provided
    if params[:start_date].present? && params[:end_date].present?
      @sessions = @sessions.completed_between(
        Date.parse(params[:start_date]),
        Date.parse(params[:end_date])
      )
    end

    @stats = AssessmentResponseSession.stats_for_assessment(@assessment)
    @states = AssessmentResponseSession.aasm.states.map(&:name)
  end

  def show
    @responses = @session.assessment_question_responses
      .includes(:assessment_question, :selected_options, :assessment_question_options)
      .joins(:assessment_question)
      .order("assessment_questions.order")

    @scores = @session.assessment_response_scores if @session.marked?
  end

  def new
    @session = @assessment.assessment_response_sessions.build
  end

  def create
    @session = @assessment.assessment_response_sessions.build(session_params)

    if @session.save
      redirect_to assessment_response_session_path(@assessment, @session),
                  notice: "Response session was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @session.update(session_params)
      redirect_to assessment_response_session_path(@assessment, @session),
                  notice: "Response session was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @session.destroy
    redirect_to assessment_response_sessions_path(@assessment),
                notice: "Response session was successfully deleted."
  end

  # State transition actions
  def start
    # Handle GET requests by redirecting to show page
    if request.get?
      redirect_to assessment_response_session_path(@assessment, @session)
      return
    end

    # Handle PATCH requests for state transition
    if @session.may_start?
      @session.start!
      redirect_to assessment_response_session_path(@assessment, @session),
                  notice: "Session started successfully."
    else
      redirect_to assessment_response_session_path(@assessment, @session),
                  alert: "Cannot start this session."
    end
  end

  def submit
    # Handle GET requests by redirecting to show page
    if request.get?
      redirect_to assessment_response_session_path(@assessment, @session)
      return
    end

    # Handle PATCH requests for state transition
    if @session.may_submit?
      @session.submit!
      redirect_to assessment_response_session_path(@assessment, @session),
                  notice: "Session submitted successfully."
    else
      redirect_to assessment_response_session_path(@assessment, @session),
                  alert: "Cannot submit this session. Please complete all required questions."
    end
  end

  def mark
    # Handle GET requests by redirecting to show page
    if request.get?
      redirect_to assessment_response_session_path(@assessment, @session)
      return
    end

    # Handle PATCH requests for state transition
    if @session.mark_in_background!
      redirect_to assessment_response_session_path(@assessment, @session),
                  notice: "Session queued for marking. You will be notified when complete."
    else
      redirect_to assessment_response_session_path(@assessment, @session),
                  alert: "Cannot mark this session."
    end
  end

  def publish
    # Handle GET requests by redirecting to show page
    if request.get?
      redirect_to assessment_response_session_path(@assessment, @session)
      return
    end

    # Handle PATCH requests for state transition
    if @session.may_publish_results?
      @session.publish_results!
      redirect_to assessment_response_session_path(@assessment, @session),
                  notice: "Results published successfully."
    else
      redirect_to assessment_response_session_path(@assessment, @session),
                  alert: "Cannot publish results for this session."
    end
  end

  def cancel
    # Handle GET requests by redirecting to show page
    if request.get?
      redirect_to assessment_response_session_path(@assessment, @session)
      return
    end

    # Handle PATCH requests for state transition
    if @session.may_cancel?
      @session.cancel!
      redirect_to assessment_response_session_path(@assessment, @session),
                  notice: "Session cancelled successfully."
    else
      redirect_to assessment_response_session_path(@assessment, @session),
                  alert: "Cannot cancel this session."
    end
  end

  def reset
    # Handle GET requests by redirecting to show page
    if request.get?
      redirect_to assessment_response_session_path(@assessment, @session)
      return
    end

    # Handle PATCH requests for state transition
    if @session.may_reset?
      @session.reset!
      redirect_to assessment_response_session_path(@assessment, @session),
                  notice: "Session reset successfully."
    else
      redirect_to assessment_response_session_path(@assessment, @session),
                  alert: "Cannot reset this session."
    end
  end

  # Bulk operations
  def bulk_mark
    session_ids = params[:session_ids]

    if session_ids.blank?
      respond_to do |format|
        format.html { redirect_to assessment_response_sessions_path(@assessment), alert: "No sessions selected for marking." }
        format.json { render json: { error: "No sessions selected for marking." }, status: :bad_request }
      end
      return
    end

    # Validate sessions can be marked
    sessions = @assessment.assessment_response_sessions
      .where(id: session_ids)
      .where(state: ["submitted", "under_review"])

    if sessions.empty?
      respond_to do |format|
        format.html { redirect_to assessment_response_sessions_path(@assessment), alert: "No valid sessions found for marking." }
        format.json { render json: { error: "No valid sessions found for marking." }, status: :bad_request }
      end
      return
    end

    # Queue bulk marking job
    AssessmentResponseSession.bulk_mark_in_background(sessions.pluck(:id))

    respond_to do |format|
      format.html { redirect_to assessment_response_sessions_path(@assessment), notice: "Queued #{sessions.count} sessions for marking. You will be notified when complete." }
      format.json { render json: { message: "Queued #{sessions.count} sessions for marking.", count: sessions.count }, status: :ok }
    end
  end

  def bulk_publish
    session_ids = params[:session_ids]

    if session_ids.blank?
      respond_to do |format|
        format.html { redirect_to assessment_response_sessions_path(@assessment), alert: "No sessions selected for publishing." }
        format.json { render json: { error: "No sessions selected for publishing." }, status: :bad_request }
      end
      return
    end

    sessions = @assessment.assessment_response_sessions
      .where(id: session_ids)
      .where(state: "marked")

    if sessions.empty?
      respond_to do |format|
        format.html { redirect_to assessment_response_sessions_path(@assessment), alert: "No valid sessions found for publishing." }
        format.json { render json: { error: "No valid sessions found for publishing." }, status: :bad_request }
      end
      return
    end

    published_count = 0

    sessions.each do |session|
      if session.may_publish_results?
        session.publish_results!
        published_count += 1
      end
    end

    respond_to do |format|
      format.html { redirect_to assessment_response_sessions_path(@assessment), notice: "Successfully published #{published_count} sessions." }
      format.json { render json: { message: "Successfully published #{published_count} sessions.", count: published_count }, status: :ok }
    end
  end

  # Analytics and reporting
  def analytics
    @sessions = @assessment.assessment_response_sessions
    @stats = {
      total_sessions: @sessions.count,
      by_state: @sessions.group(:state).count,
      completion_rate: calculate_completion_rate,
      average_score: @sessions.where.not(total_score: 0).average(:total_score)&.round(2) || 0,
      score_distribution: calculate_score_distribution,
      time_analytics: calculate_time_analytics,
      pass_rate: calculate_pass_rate,
    }

    # Chart data for frontend
    @chart_data = {
      states: @stats[:by_state],
      scores: @stats[:score_distribution],
      completion_over_time: completion_over_time_data,
    }
  end

  def export
    @sessions = @assessment.assessment_response_sessions.includes(:assessment_question_responses)

    respond_to do |format|
      format.csv do
        csv_data = generate_csv_export
        send_data csv_data,
                  filename: "#{@assessment.title.parameterize}-responses-#{Date.current}.csv",
                  type: "text/csv"
      end

      format.json do
        render json: {
          assessment: @assessment.title,
          exported_at: Time.current,
          sessions: @sessions.map(&:as_json),
        }
      end
    end
  end

  private

  def set_assessment
    @assessment = Assessment.find(params[:assessment_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to assessments_path, alert: "Assessment not found."
  end

  def set_session
    @session = @assessment.assessment_response_sessions.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to assessment_response_sessions_path(@assessment),
                alert: "Response session not found."
  end

  def session_params
    params.require(:assessment_response_session).permit(
      :respondent_name, :respondent_email, :feedback,
      metadata: {},
    )
  end

  def calculate_completion_rate
    total = @sessions.count
    return 0 if total.zero?

    completed = @sessions.where(state: ["completed", "submitted", "marked", "published"]).count
    (completed.to_f / total * 100).round(2)
  end

  def calculate_score_distribution
    marked_sessions = @sessions.where(state: ["marked", "published"])
    return {} if marked_sessions.empty?

    scores = marked_sessions.pluck(:total_score, :max_possible_score)
      .map { |earned, possible| possible.zero? ? 0 : (earned / possible * 100).round }

    {
      "0-20%" => scores.count { |s| s < 20 },
      "20-40%" => scores.count { |s| s >= 20 && s < 40 },
      "40-60%" => scores.count { |s| s >= 40 && s < 60 },
      "60-80%" => scores.count { |s| s >= 60 && s < 80 },
      "80-100%" => scores.count { |s| s >= 80 },
    }
  end

  def calculate_time_analytics
    completed_sessions = @sessions.where.not(started_at: nil, completed_at: nil)
    return {} if completed_sessions.empty?

    durations = completed_sessions.pluck(:started_at, :completed_at)
      .map { |start, finish| ((finish - start) / 60).round } # minutes

    {
      average_duration: durations.sum / durations.count,
      median_duration: durations.sort[durations.count / 2],
      min_duration: durations.min,
      max_duration: durations.max,
    }
  end

  def calculate_pass_rate
    marked_sessions = @sessions.where(state: ["marked", "published"])
    return 0 if marked_sessions.empty?

    passed = marked_sessions.select(&:passed?).count
    (passed.to_f / marked_sessions.count * 100).round(2)
  end

  def completion_over_time_data
    completed_sessions = @sessions.where.not(completed_at: nil)

    if completed_sessions.any?
      completed_sessions.group_by_day(:completed_at, last: 30).count
    else
      {} # Return empty hash if no completed sessions
    end
  end

  def generate_csv_export
    require "csv"

    CSV.generate(headers: true) do |csv|
      # Header row
      csv << [
        "ID", "Respondent Name", "Respondent Email", "State", "Started At",
        "Completed At", "Submitted At", "Marked At", "Duration", "Total Score",
        "Max Possible Score", "Percentage", "Grade", "Passed",
      ]

      # Data rows
      @sessions.each do |session|
        csv << [
          session.id,
          session.respondent_name,
          session.respondent_email,
          session.state,
          session.started_at&.strftime("%Y-%m-%d %H:%M:%S"),
          session.completed_at&.strftime("%Y-%m-%d %H:%M:%S"),
          session.submitted_at&.strftime("%Y-%m-%d %H:%M:%S"),
          session.marked_at&.strftime("%Y-%m-%d %H:%M:%S"),
          session.duration_formatted,
          session.total_score,
          session.max_possible_score,
          session.score_percentage,
          session.grade,
          session.passed? ? "Yes" : "No",
        ]
      end
    end
  end
end
