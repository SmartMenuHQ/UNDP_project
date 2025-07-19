class AssessmentsController < ApplicationController
  before_action :set_assessment, only: [:show, :edit, :update, :destroy, :preview]

  def index
    @assessments = Assessment.all.order(created_at: :desc)
  end

  def show
    @sections = @assessment.assessment_sections.ordered.includes(:assessment_questions)
  end

  def new
    @assessment = Assessment.new
    @assessment.assessment_sections.build # Start with one section
  end

  def create
    @assessment = Assessment.new(assessment_params)

    if @assessment.save
      redirect_to edit_assessment_path(@assessment), notice: "Assessment was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @sections = @assessment.assessment_sections.ordered.includes(:assessment_questions)
    @question_types = question_types_for_select
  end

  def update
    if @assessment.update(assessment_params)
      redirect_to edit_assessment_path(@assessment), notice: "Assessment was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @assessment.destroy
    redirect_to assessments_path, notice: "Assessment was successfully deleted."
  end

  def preview
    @sections = @assessment.assessment_sections.ordered.includes(:assessment_questions)

    # Handle section navigation
    if @sections.count > 0
      @current_section_index = params[:section].to_i.clamp(0, @sections.count - 1)
      @current_section = @sections[@current_section_index]
    else
      @current_section_index = 0
      @current_section = nil
    end

    # Navigation info
    @has_previous = @current_section_index > 0
    @has_next = @current_section_index < @sections.count - 1
    @next_section_index = @current_section_index + 1
    @previous_section_index = @current_section_index - 1

    render layout: "preview"
  end

  # AJAX endpoints for dynamic functionality
  def add_section
    @assessment = Assessment.find(params[:id])
    @section = @assessment.assessment_sections.build

    if @section.save
      render json: {
        success: true,
        section: {
          id: @section.id,
          name: @section.name,
          order: @section.order,
        },
      }
    else
      render json: {
        success: false,
        errors: @section.errors.full_messages,
      }
    end
  end

  def remove_section
    @assessment = Assessment.find(params[:id])
    @section = @assessment.assessment_sections.find(params[:section_id])
    @section.destroy

    render json: { success: true }
  end

  def add_question
    @assessment = Assessment.find(params[:id])
    @section = @assessment.assessment_sections.find(params[:section_id])

    question_type = params[:question_type]
    question_class = "AssessmentQuestions::#{question_type}".constantize

    @question = question_class.new(
      assessment: @assessment,
      assessment_section: @section,
      text: "New #{question_type.humanize} Question",
      order: @section.assessment_questions.count + 1,
    )

    if @question.save
      # Add default options for MultipleChoice and Radio questions after saving
      if question_type == "MultipleChoice" || question_type == "Radio"
        @question.option.create!(
          assessment: @assessment,
          text: "Option 1",
          order: 1,
        )
        @question.option.create!(
          assessment: @assessment,
          text: "Option 2",
          order: 2,
        )
      end

      render json: {
        success: true,
        question: {
          id: @question.id,
          text: @question.text,
          type: @question.type,
          order: @question.order,
        },
      }
    else
      render json: { success: false, errors: @question.errors.full_messages }
    end
  end

  def remove_question
    @question = AssessmentQuestion.find(params[:question_id])
    @question.destroy

    render json: { success: true }
  end

  def update_question
    @question = AssessmentQuestion.find(params[:question_id])

    if @question.update(question_params)
      render json: { success: true }
    else
      render json: { success: false, errors: @question.errors.full_messages }
    end
  end

  def add_option
    @question = AssessmentQuestion.find(params[:question_id])
    @assessment = @question.assessment

    @option = @question.option.create!(
      assessment: @assessment,
      text: params[:option_text] || "New Option",
      order: @question.option.count + 1,
    )

    render json: {
      success: true,
      option: {
        id: @option.id,
        text: @option.text,
        order: @option.order,
      },
    }
  rescue => e
    render json: { success: false, error: e.message }
  end

  def remove_option
    @option = AssessmentQuestionOption.find(params[:option_id])
    @option.destroy
    render json: { success: true }
  rescue => e
    render json: { success: false, error: e.message }
  end

  def update_option
    @option = AssessmentQuestionOption.find(params[:option_id])

    if @option.update(option_params)
      render json: { success: true }
    else
      render json: { success: false, errors: @option.errors.full_messages }
    end
  end

  private

  def set_assessment
    @assessment = Assessment.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to assessments_path, alert: "Assessment not found. It may have been deleted."
  end

  def assessment_params
    params.require(:assessment).permit(:title, :description, :active,
                                       assessment_sections_attributes: [:id, :name, :order, :_destroy,
                                                                        assessment_questions_attributes: [:id, :text, :type, :is_required, :order, :_destroy]])
  end

  def question_params
    params.require(:question).permit(:text, :sub_type, :is_required, :order, :meta_data, :allowed_data_types, :max_file_size, :upload_mode, allowed_data_types: [])
  end

  def option_params
    params.require(:option).permit(:text, :order)
  end

  def question_types_for_select
    [
      ["Multiple Choice", "MultipleChoice"],
      ["Radio Button", "Radio"],
      ["Boolean (Yes/No)", "BooleanType"],
      ["Date", "DateType"],
      ["Range/Scale", "RangeType"],
      ["Rich Text", "RichText"],
      ["File Upload", "FileUpload"],
    ]
  end
end
