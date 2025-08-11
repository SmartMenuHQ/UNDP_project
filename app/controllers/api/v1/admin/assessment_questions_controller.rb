class Api::V1::Admin::AssessmentQuestionsController < Api::V1::Admin::BaseController
  before_action :set_assessment
  before_action :set_section
  before_action :set_question, only: [:show, :update, :destroy]

  # GET /api/v1/admin/assessments/:assessment_id/sections/:section_id/questions
  def index
    authorize @assessment, :manage_questions?

    @questions = @section.assessment_questions.includes(:assessment_question_options)

    # Apply filtering
    @questions = @questions.where(active: params[:active]) if params[:active].present?
    @questions = @questions.where(is_required: params[:is_required]) if params[:is_required].present?
    @questions = @questions.where(type: params[:question_type]) if params[:question_type].present?

    # Apply search
    if params[:search].present?
      @questions = @questions.where("text ->> 'en' ILIKE ?", "%#{params[:search]}%")
    end

    # Apply sorting
    sort_by = params[:sort_by].presence || "order"
    sort_order = params[:sort_order].presence || "asc"
    # Quote the column name to handle reserved keywords like 'order'
    @questions = @questions.order("\"#{sort_by}\" #{sort_order}")

    # Apply pagination
    page = params[:page].presence || 1
    per_page = [params[:per_page].to_i, 100].min
    per_page = 25 if per_page <= 0

    @questions = @questions.page(page).per(per_page) if defined?(Kaminari)

    @data = {
      questions: @questions,
      total_count: @section.assessment_questions.count,
      section: {
        id: @section.id,
        name: @section.name,
      },
      assessment: {
        id: @assessment.id,
        title: @assessment.title,
      },
      pagination: {
        current_page: page.to_i,
        per_page: per_page,
        total_pages: (@section.assessment_questions.count.to_f / per_page).ceil,
      },
      available_question_types: available_question_types,
    }

    note!("Assessment questions retrieved successfully")
  end

  # GET /api/v1/admin/assessments/:assessment_id/sections/:section_id/questions/:id
  def show
    authorize @assessment, :manage_questions?

    @data = {
      question: @question,
      options_count: @question.assessment_question_options.count,
      section: {
        id: @section.id,
        name: @section.name,
      },
      assessment: {
        id: @assessment.id,
        title: @assessment.title,
      },
      statistics: {
        total_options: @question.assessment_question_options.count,
        correct_options: @question.assessment_question_options.where(is_correct_answer: true).count,
        responses_count: @question.assessment_question_responses.count,
      },
    }

    note!("Assessment question retrieved successfully")
  end

  # POST /api/v1/admin/assessments/:assessment_id/sections/:section_id/questions
  def create
    authorize @assessment, :manage_questions?
    # Determine question class based on type
    question_type = question_params[:type] || "AssessmentQuestions::TextType"

    begin
      question_class = question_type.constantize
    rescue NameError
      raise ApiException::ValidationError.new("Invalid question type: #{question_type}")
    end

    # Create question using STI class with proper associations
    question_attributes = question_params.except(:type, :text)
    question_attributes[:assessment_id] = @assessment.id
    question_attributes[:assessment_section_id] = @section.id

    # Use the specific STI class to create the question
    @question = question_class.new(question_attributes)

    # Explicitly set the associations to ensure they're properly loaded
    @question.assessment = @assessment
    @question.assessment_section = @section

    # Handle text field specially for Mobility gem
    if question_params[:text].present?
      if question_params[:text].is_a?(Hash)
        @question.text = question_params[:text]
      else
        @question.text = question_params[:text]
      end
    end

    # Set order if not provided
    if @question.order.blank?
      @question.order = @section.assessment_questions.maximum(:order).to_i + 1
    end

    if @question.save
      # Create default options for multiple choice questions
      if @question.type.in?(["AssessmentQuestions::MultipleChoice", "AssessmentQuestions::Radio"])
        create_default_options(@question)
      end

      @data = { question: @question }
      note!("Assessment question created successfully")
    else
      raise ApiException::ValidationError.new("Question creation failed",
                                              details: { errors: @question.errors.full_messages })
    end
  end

  # PATCH/PUT /api/v1/admin/assessments/:assessment_id/sections/:section_id/questions/:id
  def update
    authorize @assessment, :manage_questions?

    # Handle text field specially for Mobility gem
    if question_params[:text].present?
      if question_params[:text].is_a?(Hash)
        @question.text = question_params[:text]
      else
        @question.text = question_params[:text]
      end
    end

    if @question.update(question_params.except(:type, :text))
      @data = { question: @question }
      note!("Assessment question updated successfully")
    else
      raise ApiException::ValidationError.new("Question update failed",
                                              details: { errors: @question.errors.full_messages })
    end
  end

  # DELETE /api/v1/admin/assessments/:assessment_id/sections/:section_id/questions/:id
  def destroy
    authorize @assessment, :manage_questions?

    # Check if question has responses
    if @question.assessment_question_responses.exists?
      raise ApiException::ValidationError.new("Cannot delete question with existing responses",
                                              details: {
                                                responses_count: @question.assessment_question_responses.count,
                                                suggestion: "Archive the question instead of deleting it",
                                              })
    end

    question_text = if @question.text.is_a?(Hash)
        @question.text["en"] || @question.text.values.first || "Question"
      else
        @question.text || "Question"
      end
    if @question.destroy
      @data = { deleted_id: @question.id }
      note!("Assessment question '#{question_text}' deleted successfully")
    else
      raise ApiException::ValidationError.new("Question deletion failed",
                                              details: { errors: @question.errors.full_messages })
    end
  end

  private

  def set_assessment
    @assessment = Assessment.find(params[:assessment_id])
  rescue ActiveRecord::RecordNotFound
    raise ApiException::NotFoundError.new("Assessment not found")
  end

  def set_section
    @section = @assessment.assessment_sections.find(params[:section_id])
  rescue ActiveRecord::RecordNotFound
    raise ApiException::NotFoundError.new("Assessment section not found")
  end

  def set_question
    @question = @section.assessment_questions.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    raise ApiException::NotFoundError.new("Assessment question not found")
  end

  def question_params
    params.require(:question).permit(
      :type, :order, :is_required, :active, :sub_type,
      :is_conditional, :has_country_restrictions,
      :trigger_question_id, :trigger_response_type, :operator,
      text: {}, meta_data: {}, trigger_values: [], restricted_countries: [],
    )
  end

  def available_question_types
    [
      {
        type: "AssessmentQuestions::TextType",
        name: "Text Input",
        description: "Single line text input",
      },
      {
        type: "AssessmentQuestions::TextareaType",
        name: "Textarea",
        description: "Multi-line text input",
      },
      {
        type: "AssessmentQuestions::MultipleChoice",
        name: "Multiple Choice",
        description: "Multiple options, multiple selections allowed",
      },
      {
        type: "AssessmentQuestions::Radio",
        name: "Radio Button",
        description: "Multiple options, single selection",
      },
      {
        type: "AssessmentQuestions::BooleanType",
        name: "Yes/No",
        description: "Boolean true/false question",
      },
      {
        type: "AssessmentQuestions::DateType",
        name: "Date",
        description: "Date picker input",
      },
      {
        type: "AssessmentQuestions::FileUpload",
        name: "File Upload",
        description: "File attachment upload",
      },
    ]
  end

  def create_default_options(question)
    question.assessment_question_options.create!([
      {
        text: { "en" => "Option 1" },
        order: 1,
        is_correct_answer: false,
        points: 0,
        assessment_id: question.assessment_id,
      },
      {
        text: { "en" => "Option 2" },
        order: 2,
        is_correct_answer: false,
        points: 0,
        assessment_id: question.assessment_id,
      },
    ])
  end
end
