class MarkingSchemesController < ApplicationController
  before_action :set_assessment
  before_action :set_marking_scheme, only: [:show, :edit, :update, :destroy, :activate, :deactivate]

  def index
    @marking_schemes = @assessment.assessment_marking_schemes.includes(:assessment_question_marking_rules)
    @active_scheme = @marking_schemes.find_by(is_active: true)
  end

  def show
    @marking_rules = @marking_scheme.assessment_question_marking_rules
      .includes(:assessment_question)
      .ordered
    @total_possible_score = @marking_rules.sum(:points)
  end

  def new
    @marking_scheme = @assessment.assessment_marking_schemes.build
    @marking_scheme.total_possible_score = calculate_default_total_score
    set_default_settings
  end

  def create
    @marking_scheme = @assessment.assessment_marking_schemes.build(marking_scheme_params)

    if @marking_scheme.save
      redirect_to assessment_marking_scheme_path(@assessment, @marking_scheme),
                  notice: "Marking scheme was successfully created."
    else
      set_default_settings
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @marking_scheme.update(marking_scheme_params)
      redirect_to assessment_marking_scheme_path(@assessment, @marking_scheme),
                  notice: "Marking scheme was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @marking_scheme.destroy
    redirect_to assessment_marking_schemes_path(@assessment),
                notice: "Marking scheme was successfully deleted."
  end

  def activate
    # Deactivate all other schemes for this assessment
    @assessment.assessment_marking_schemes.update_all(is_active: false)

    # Activate this scheme
    @marking_scheme.update!(is_active: true)

    redirect_to assessment_marking_schemes_path(@assessment),
                notice: "#{@marking_scheme.name} is now the active marking scheme."
  end

  def deactivate
    @marking_scheme.update!(is_active: false)
    redirect_to assessment_marking_schemes_path(@assessment),
                notice: "#{@marking_scheme.name} has been deactivated."
  end

  def duplicate
    original_scheme = @assessment.assessment_marking_schemes.find(params[:id])

    new_scheme = original_scheme.dup
    new_scheme.name = "Copy of #{original_scheme.name}"
    new_scheme.is_active = false

    if new_scheme.save
      # Duplicate all marking rules
      original_scheme.assessment_question_marking_rules.each do |rule|
        new_rule = rule.dup
        new_rule.assessment_marking_scheme = new_scheme
        new_rule.save!
      end

      redirect_to assessment_marking_scheme_path(@assessment, new_scheme),
                  notice: "Marking scheme was successfully duplicated."
    else
      redirect_to assessment_marking_schemes_path(@assessment),
                  alert: "Failed to duplicate marking scheme."
    end
  end

  private

  def set_assessment
    @assessment = Assessment.find(params[:assessment_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to assessments_path, alert: "Assessment not found."
  end

  def set_marking_scheme
    @marking_scheme = @assessment.assessment_marking_schemes.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to assessment_marking_schemes_path(@assessment),
                alert: "Marking scheme not found."
  end

  def marking_scheme_params
    params.require(:assessment_marking_scheme).permit(
      :name, :description, :total_possible_score, :is_active,
      settings: [
        :passing_score,
        grade_boundaries: {},
        feedback_templates: {},
      ],
    )
  end

  def calculate_default_total_score
    @assessment.assessment_questions.count * 10 # Default 10 points per question
  end

  def set_default_settings
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
  end
end
