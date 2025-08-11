class Api::V1::AssessmentsController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :set_assessment, only: [:show, :sections, :questions, :visibility_summary]

  # GET /api/v1/assessments
  def index
    @assessments = policy_scope(Assessment).includes(:assessment_sections, :assessment_questions)

    # Apply filtering based on user's country
    if current_user && !current_user.admin?
      @assessments = @assessments.accessible_to_country(current_user.country&.code)
    end

    @data = {
      assessments: @assessments,
      total_count: @assessments.count,
    }

    note!("Assessments retrieved successfully")
  end

  # GET /api/v1/assessments/:id
  def show
    authorize @assessment

    # Get user session for this assessment if exists
    user_session = current_user&.assessment_response_sessions&.find_by(assessment: @assessment)

    @data = {
      assessment: @assessment,
      user_permissions: {
        can_take_assessment: policy(@assessment).take_assessment?,
      },
      user_session: user_session,
      visibility_summary: @assessment.visibility_summary_for_user(current_user),
    }

    note!("Assessment retrieved successfully")
  end

  # GET /api/v1/assessments/:id/sections
  def sections
    authorize @assessment, :show?

    visible_sections = @assessment.visible_sections_for_user(current_user)

    @data = {
      sections: visible_sections,
      total_count: visible_sections.count,
      assessment: {
        id: @assessment.id,
        title: @assessment.title,
      },
    }

    note!("Assessment sections retrieved successfully")
  end

  # GET /api/v1/assessments/:id/questions
  def questions
    authorize @assessment, :show?

    visible_questions = @assessment.visible_questions_for_user(current_user)

    @data = {
      questions: visible_questions,
      total_count: visible_questions.count,
      assessment: {
        id: @assessment.id,
        title: @assessment.title,
      },
    }

    note!("Assessment questions retrieved successfully")
  end

  # GET /api/v1/assessments/:id/visibility_summary
  def visibility_summary
    authorize @assessment, :show?

    # Get user session for this assessment if exists
    user_session = current_user&.assessment_response_sessions&.find_by(assessment: @assessment)

    @data = {
      visibility_summary: @assessment.visibility_summary_for_user(current_user),
      assessment: {
        id: @assessment.id,
        title: @assessment.title,
      },
      session: user_session,
    }

    note!("Assessment visibility summary retrieved successfully")
  end

  private

  def set_assessment
    @assessment = Assessment.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    raise ApiException::NotFoundError.new("Assessment not found")
  end
end
