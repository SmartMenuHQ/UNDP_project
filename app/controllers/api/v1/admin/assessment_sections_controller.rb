class Api::V1::Admin::AssessmentSectionsController < Api::V1::Admin::BaseController
  before_action :set_assessment
  before_action :set_section, only: [:show, :update, :destroy]

  # GET /api/v1/admin/assessments/:assessment_id/sections
  def index
    authorize @assessment, :manage_sections?

    @sections = @assessment.assessment_sections.includes(:assessment_questions)

    # Apply filtering
    @sections = @sections.where(active: params[:active]) if params[:active].present?

    # Apply search
    if params[:search].present?
      @sections = @sections.where("name ILIKE ?", "%#{params[:search]}%")
    end

    # Apply sorting
    sort_by = params[:sort_by].presence || "order"
    sort_order = params[:sort_order].presence || "asc"
    # Quote the column name to handle reserved keywords like 'order'
    @sections = @sections.order("\"#{sort_by}\" #{sort_order}")

    # Apply pagination
    page = params[:page].presence || 1
    per_page = [params[:per_page].to_i, 100].min
    per_page = 25 if per_page <= 0

    @sections = @sections.page(page).per(per_page) if defined?(Kaminari)

    @data = {
      sections: @sections,
      total_count: @assessment.assessment_sections.count,
      assessment: {
        id: @assessment.id,
        title: @assessment.title,
      },
      pagination: {
        current_page: page.to_i,
        per_page: per_page,
        total_pages: (@assessment.assessment_sections.count.to_f / per_page).ceil,
      },
    }

    note!("Assessment sections retrieved successfully")
  end

  # GET /api/v1/admin/assessments/:assessment_id/sections/:id
  def show
    authorize @assessment, :manage_sections?

    @data = {
      section: @section,
      questions_count: @section.assessment_questions.count,
      assessment: {
        id: @assessment.id,
        title: @assessment.title,
      },
      statistics: {
        total_questions: @section.assessment_questions.count,
        active_questions: @section.assessment_questions.where(active: true).count,
        required_questions: @section.assessment_questions.where(is_required: true).count,
      },
    }

    note!("Assessment section retrieved successfully")
  end

  # POST /api/v1/admin/assessments/:assessment_id/sections
  def create
    authorize @assessment, :manage_sections?

    @section = @assessment.assessment_sections.build(section_params)

    # Set order if not provided
    if @section.order.blank?
      @section.order = @assessment.assessment_sections.maximum(:order).to_i + 1
    end

    if @section.save
      @data = { section: @section }
      note!("Assessment section '#{@section.name}' created successfully")
    else
      raise ApiException::ValidationError.new("Section creation failed",
                                              details: { errors: @section.errors.full_messages })
    end
  end

  # PATCH/PUT /api/v1/admin/assessments/:assessment_id/sections/:id
  def update
    authorize @assessment, :manage_sections?

    if @section.update(section_params)
      @data = { section: @section }
      note!("Assessment section '#{@section.name}' updated successfully")
    else
      raise ApiException::ValidationError.new("Section update failed",
                                              details: { errors: @section.errors.full_messages })
    end
  end

  # DELETE /api/v1/admin/assessments/:assessment_id/sections/:id
  def destroy
    authorize @assessment, :manage_sections?

    # Check if section has questions
    if @section.assessment_questions.exists?
      raise ApiException::ValidationError.new("Cannot delete section with existing questions",
                                              details: {
                                                questions_count: @section.assessment_questions.count,
                                                suggestion: "Delete all questions first or move them to another section",
                                              })
    end

    section_name = @section.name
    if @section.destroy
      @data = { deleted_id: @section.id }
      note!("Assessment section '#{section_name}' deleted successfully")
    else
      raise ApiException::ValidationError.new("Section deletion failed",
                                              details: { errors: @section.errors.full_messages })
    end
  end

  private

  def set_assessment
    @assessment = Assessment.find(params[:assessment_id])
  rescue ActiveRecord::RecordNotFound
    raise ApiException::NotFoundError.new("Assessment not found")
  end

  def set_section
    @section = @assessment.assessment_sections.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    raise ApiException::NotFoundError.new("Assessment section not found")
  end

  def section_params
    params.require(:section).permit(
      :name, :order, :is_conditional, :has_country_restrictions,
      :metadata, visibility_conditions: {}, restricted_countries: [],
    )
  end
end
