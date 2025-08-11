class Api::V1::Business::ResponseSessionsController < Api::V1::Business::BaseController
  before_action :set_assessment
  before_action :set_session, only: [:show, :update, :start, :submit_section, :show_section, :section_responses]

  def index
    sessions = @assessment.assessment_response_sessions.where(user: current_user).recent
    @data = { response_sessions: sessions }
    note!("Response sessions retrieved successfully")
    render :index
  end

  def show
    authorize_view!
    @data = { response_session: @session }
    note!("Response session retrieved successfully")
  end

  def create
    session = AssessmentResponseSession.create_for_user(current_user, @assessment)
    @data = { response_session: session }
    note!("Response session created successfully")
    render :show
  end

  def update
    authorize_view!
    if @session.update(session_params)
      @data = { response_session: @session }
      note!("Response session updated successfully")
      render :show
    else
      raise ApiException::ValidationError.new("Update failed", details: { errors: @session.errors.full_messages })
    end
  end

  def start
    authorize_view!
    if @session.may_start?
      @session.start!
      first_section = @session.first_visible_section
      @data = { response_session: @session }
      @meta = {
        first_section_id: first_section&.id,
        links: {
          show_section: (first_section ? show_section_api_v1_business_assessment_response_session_path(@assessment, @session, section_id: first_section.id) : nil),
          submit_section: (first_section ? submit_section_api_v1_business_assessment_response_session_path(@assessment, @session, section_id: first_section.id) : nil),
        },
      }
      note!("Session started successfully; first visible section provided in meta")
      render :show
    else
      raise ApiException::ValidationError.new("Cannot start this session")
    end
  end

  # Fetch a section details and its questions for this session, enforcing access rules
  def show_section
    authorize_view!
    section = @assessment.assessment_sections.find_by(id: params[:section_id])
    raise ApiException::NotFoundError.new("Section not found") unless section
    raise ApiException::AuthorizationError.new("Forbidden") unless @session.can_access_section?(section)

    questions = @session.visible_questions_in_section(section)

    @data = {
      section: section,
      questions: questions,
    }
    note!("Section and questions fetched successfully")
    render :show_section
  end

  # Submit current section responses and return next/previous links (no full payload, fetch via show_section)
  def submit_section
    authorize_view!

    current_section = @assessment.assessment_sections.find_by(id: params[:section_id])
    raise ApiException::ValidationError.new("section_id is required") unless current_section
    raise ApiException::AuthorizationError.new("Forbidden") unless @session.can_access_section?(current_section)

    # Persist submitted responses for this section
    submit_responses_for_section!(current_section)

    # Validate required visible questions in this section are answered
    missing_required_ids = required_visible_questions_in_section(current_section).reject do |q|
      resp = @session.assessment_question_responses.find_by(assessment_question: q)
      resp&.has_valid_response?
    end.map(&:id)

    if missing_required_ids.any?
      @data = { response_session: @session }
      @meta = {
        section_id: current_section.id,
        missing_required_question_ids: missing_required_ids,
        links: {
          show_section: show_section_api_v1_business_assessment_response_session_path(@assessment, @session, section_id: current_section.id),
        },
      }
      note!("Section has missing required responses")
      return render :show
    end

    next_section = @session.next_visible_section(current_section)
    prev_section = @session.previous_visible_section(current_section)

    if next_section.nil? && @session.may_complete? && @session.all_required_visible_questions_answered?
      @session.complete!
    end

    @data = { response_session: @session }
    @meta = {
      next_section_id: next_section&.id,
      previous_section_id: prev_section&.id,
      links: {
        show_next_section: (next_section ? show_section_api_v1_business_assessment_response_session_path(@assessment, @session, section_id: next_section.id) : nil),
        show_previous_section: (prev_section ? show_section_api_v1_business_assessment_response_session_path(@assessment, @session, section_id: prev_section.id) : nil),
        submit_section: submit_section_api_v1_business_assessment_response_session_path(@assessment, @session, section_id: current_section.id),
      },
    }
    note!("Section submitted; navigation meta returned")
    render :show
  end

  # Return responses for questions in the given section
  def section_responses
    authorize_view!
    section = @assessment.assessment_sections.find_by(id: params[:section_id])
    raise ApiException::NotFoundError.new("Section not found") unless section
    raise ApiException::AuthorizationError.new("Forbidden") unless @session.can_access_section?(section)

    questions = @session.visible_questions_in_section(section)
    responses = questions.map { |q| @session.responses_for_question(q) }.compact

    @data = {
      section: section,
      responses: responses,
    }
    note!("Section responses fetched successfully")
    render :section_responses
  end

  private

  def set_assessment
    @assessment = Assessment.find(params[:assessment_id])
  rescue ActiveRecord::RecordNotFound
    raise ApiException::NotFoundError.new("Assessment not found")
  end

  def set_session
    @session = @assessment.assessment_response_sessions.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    raise ApiException::NotFoundError.new("Response session not found")
  end

  def session_params
    params.fetch(:response_session, {}).permit(:respondent_name, metadata: {})
  end

  def authorize_view!
    # non-admin users may only access their own sessions
    raise ApiException::AuthorizationError.new("Forbidden") unless @session.user_id == current_user.id
  end

  # ----- helpers for submit_section -----
  def responses_param_array
    raw = params[:responses]
    return [] unless raw.is_a?(Array)
    raw
  end

  def submit_responses_for_section!(section)
    responses_param_array.each do |resp_hash|
      qid = resp_hash[:question_id] || resp_hash["question_id"]
      next unless qid
      question = section.assessment_questions.find_by(id: qid)
      next unless question
      value = normalize_response_value(question, resp_hash)
      @session.create_response_for_question(question, value)
    end
  end

  def required_visible_questions_in_section(section)
    @session.visible_questions_in_section(section).select { |q| q.is_required }
  end

  def normalize_response_value(question, resp_hash)
    case question.type
    when "AssessmentQuestions::MultipleChoice", "AssessmentQuestions::Radio", "AssessmentQuestions::BooleanType"
      if resp_hash.key?(:selected_option_ids)
        resp_hash[:selected_option_ids]
      elsif resp_hash.key?("selected_option_ids")
        resp_hash["selected_option_ids"]
      else
        resp_hash[:value] || resp_hash["value"]
      end
    when "AssessmentQuestions::RangeType"
      (resp_hash[:value] || resp_hash["value"]) || { number: resp_hash[:number] || resp_hash["number"] }
    when "AssessmentQuestions::DateType"
      (resp_hash[:value] || resp_hash["value"]) || { date: resp_hash[:date] || resp_hash["date"] }
    else
      (resp_hash[:value] || resp_hash["value"]) || { text: resp_hash[:text] || resp_hash["text"] }
    end
  end
end
