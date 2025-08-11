class Api::V1::Admin::AssessmentsController < Api::V1::Admin::BaseController
  before_action :set_assessment, only: [:show, :update, :destroy]

  # GET /api/v1/admin/assessments
  def index
    @assessments = policy_scope(Assessment).includes(:assessment_sections, :assessment_questions)
    @total_count = @assessments.count

    @data = {
      assessments: @assessments,
      total_count: @total_count,
      active_count: Assessment.where(active: true).count,
      inactive_count: Assessment.where(active: false).count,
    }

    note!("Assessments retrieved successfully")
  end

  # GET /api/v1/admin/assessments/:id
  def show
    authorize @assessment

    @data = {
      assessment: @assessment,
      sections_count: @assessment.assessment_sections.count,
      questions_count: @assessment.assessment_questions.count,
      statistics: {
        response_sessions_count: @assessment.assessment_response_sessions.count,
        completed_sessions_count: @assessment.assessment_response_sessions.where(state: "completed").count,
        average_score: @assessment.assessment_response_sessions.where.not(total_score: nil).average(:total_score)&.round(2),
      },
    }

    note!("Assessment retrieved successfully")
  end

  # POST /api/v1/admin/assessments
  def create
    @assessment = Assessment.new(assessment_params)

    if @assessment.save
      @data = { assessment: @assessment }
      note!("Assessment created successfully")
    else
      raise ApiException::ValidationError.new("Assessment creation failed",
                                              details: { errors: @assessment.errors.full_messages })
    end
  end

  # PATCH/PUT /api/v1/admin/assessments/:id
  def update
    authorize @assessment

    if @assessment.update(assessment_params)
      @data = { assessment: @assessment }
      note!("Assessment updated successfully")
    else
      raise ApiException::ValidationError.new("Assessment update failed",
                                              details: { errors: @assessment.errors.full_messages })
    end
  end

  # DELETE /api/v1/admin/assessments/:id
  def destroy
    authorize @assessment

    if @assessment.destroy
      @data = { deleted_id: @assessment.id }
      note!("Assessment deleted successfully")
    else
      raise ApiException::ValidationError.new("Assessment deletion failed",
                                              details: { errors: @assessment.errors.full_messages })
    end
  end

  private

  def set_assessment
    @assessment = Assessment.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    raise ApiException::NotFoundError.new("Assessment not found")
  end

  def assessment_params
    params.require(:assessment).permit(:title, :description, :active, :has_country_restrictions,
                                       restricted_countries: [])
  end
end
