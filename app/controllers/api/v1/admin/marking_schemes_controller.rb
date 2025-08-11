class Api::V1::Admin::MarkingSchemesController < Api::V1::Admin::BaseController
  before_action :set_assessment
  before_action :set_marking_scheme, only: [:show, :update, :destroy, :activate, :clone]

  # GET /api/v1/admin/assessments/:assessment_id/marking-schemes
  def index
    authorize @assessment, :manage_marking?

    schemes = @assessment.assessment_marking_schemes.order(created_at: :desc)

    # Filtering
    schemes = schemes.where(is_active: ActiveModel::Type::Boolean.new.cast(params[:is_active])) if params.key?(:is_active)
    schemes = schemes.where("name ILIKE ?", "%#{params[:search]}%") if params[:search].present?

    # Pagination
    page = params[:page].presence || 1
    per_page = [params[:per_page].to_i, 100].min
    per_page = 25 if per_page <= 0
    schemes = schemes.page(page).per(per_page) if defined?(Kaminari)

    @data = {
      marking_schemes: schemes,
      total_count: @assessment.assessment_marking_schemes.count,
      active_count: @assessment.assessment_marking_schemes.where(is_active: true).count,
      pagination: {
        current_page: page.to_i,
        per_page: per_page,
        total_pages: (@assessment.assessment_marking_schemes.count.to_f / per_page).ceil,
      },
      assessment: {
        id: @assessment.id,
        title: @assessment.title,
      },
    }

    note!("Marking schemes retrieved successfully")
  end

  # GET /api/v1/admin/assessments/:assessment_id/marking-schemes/:id
  def show
    authorize @assessment, :manage_marking?

    @data = { marking_scheme: @marking_scheme }
    note!("Marking scheme retrieved successfully")
  end

  # POST /api/v1/admin/assessments/:assessment_id/marking-schemes
  def create
    authorize @assessment, :manage_marking?

    @marking_scheme = @assessment.assessment_marking_schemes.new(marking_scheme_params)

    # Default settings if not provided
    @marking_scheme.settings ||= {}
    @marking_scheme.settings["passing_score"] ||= 60.0
    @marking_scheme.settings["grade_boundaries"] ||= {
      "A" => 90,
      "B" => 80,
      "C" => 70,
      "D" => 60,
      "F" => 0,
    }
    @marking_scheme.settings["feedback_templates"] ||= {
      "A" => "Excellent work!",
      "B" => "Good job!",
      "C" => "Satisfactory performance",
      "D" => "Needs improvement",
      "F" => "Please review the material",
    }

    # Auto-calculate a default total possible score if not set
    if @marking_scheme.total_possible_score.blank?
      @marking_scheme.total_possible_score = @assessment.assessment_questions.count * 10.0
    end

    if @marking_scheme.save
      @data = { marking_scheme: @marking_scheme }
      note!("Marking scheme created successfully")
      render :create, status: :ok
    else
      raise ApiException::ValidationError.new(
        "Marking scheme creation failed",
        details: { errors: @marking_scheme.errors.full_messages },
      )
    end
  end

  # PATCH/PUT /api/v1/admin/assessments/:assessment_id/marking-schemes/:id
  def update
    authorize @assessment, :manage_marking?

    if @marking_scheme.update(marking_scheme_params)
      @data = { marking_scheme: @marking_scheme }
      note!("Marking scheme updated successfully")
      render :update, status: :ok
    else
      raise ApiException::ValidationError.new(
        "Marking scheme update failed",
        details: { errors: @marking_scheme.errors.full_messages },
      )
    end
  end

  # DELETE /api/v1/admin/assessments/:assessment_id/marking-schemes/:id
  def destroy
    authorize @assessment, :manage_marking?

    if @marking_scheme.destroy
      @data = { deleted_id: @marking_scheme.id }
      note!("Marking scheme deleted successfully")
      render :destroy, status: :ok
    else
      raise ApiException::ValidationError.new(
        "Marking scheme deletion failed",
        details: { errors: @marking_scheme.errors.full_messages },
      )
    end
  end

  # POST /api/v1/admin/assessments/:assessment_id/marking-schemes/:id/activate
  def activate
    authorize @assessment, :manage_marking?

    ActiveRecord::Base.transaction do
      @assessment.assessment_marking_schemes.update_all(is_active: false)
      @marking_scheme.update!(is_active: true)
    end

    @data = { marking_scheme: @marking_scheme }
    note!("Marking scheme activated successfully")
  end

  # POST /api/v1/admin/assessments/:assessment_id/marking-schemes/:id/clone
  def clone
    authorize @assessment, :manage_marking?

    original = @marking_scheme
    duplicate = original.dup
    duplicate.name = (params[:name].presence || "Copy of #{original.name}")
    duplicate.is_active = false

    ActiveRecord::Base.transaction do
      duplicate.save!
      original.assessment_question_marking_rules.find_each do |rule|
        new_rule = rule.dup
        new_rule.assessment_marking_scheme = duplicate
        new_rule.save!
      end
    end

    @data = { marking_scheme: duplicate }
    note!("Marking scheme cloned successfully")
    render :clone, status: :ok
  rescue => e
    raise ApiException::ValidationError.new("Marking scheme clone failed", details: { errors: [e.message] })
  end

  private

  def set_assessment
    @assessment = Assessment.find(params[:assessment_id])
  rescue ActiveRecord::RecordNotFound
    raise ApiException::NotFoundError.new("Assessment not found")
  end

  def set_marking_scheme
    @marking_scheme = @assessment.assessment_marking_schemes.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    raise ApiException::NotFoundError.new("Marking scheme not found")
  end

  def marking_scheme_params
    params.require(:marking_scheme).permit(
      :name,
      :description,
      :is_active,
      :total_possible_score,
      settings: [
        :passing_score,
        { grade_boundaries: {} },
        { feedback_templates: {} },
      ],
    )
  end
end
