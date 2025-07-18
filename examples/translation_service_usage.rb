# Translation Service Usage Examples
# ===================================

# 1. Basic Setup
# Make sure you have your Google API key set:
# export GOOGLE_API_KEY=your_api_key_here

# 2. Initialize the service
translator = TranslationService.new

# 3. Translate a single question
question = AssessmentQuestion.find(1)
translator.translate_record(question)
# This will translate from English to all available locales (es, ja, it, fr)

# 4. Translate from a specific source locale to specific target locales
translator.translate_record(question, :en, [:es, :fr])
# This will translate from English to Spanish and French only

# 5. Translate a question with its options
question = AssessmentQuestions::MultipleChoice.find(1)
results = translator.translate_question_with_options(question)
puts "Question translated: #{results[:question]}"
puts "Options results: #{results[:options]}"

# 6. Translate an entire assessment
assessment = Assessment.find(1)
results = translator.translate_assessment(assessment)
puts "Questions: #{results[:questions][:success]} success, #{results[:questions][:failed]} failed"
puts "Options: #{results[:options][:success]} success, #{results[:options][:failed]} failed"

# 7. Batch translate multiple questions
questions = AssessmentQuestion.where(assessment_id: 1)
results = translator.translate_batch(questions)
puts "Batch results: #{results[:success]} success, #{results[:failed]} failed"

# 8. Handle errors
begin
  translator.translate_record(question)
rescue TranslationService::TranslationError => e
  puts "Translation failed: #{e.message}"
end

# 9. Check translations
question = AssessmentQuestion.find(1)
puts "English: #{question.text(locale: :en)}"
puts "Spanish: #{question.text(locale: :es)}"
puts "Japanese: #{question.text(locale: :ja)}"
puts "Italian: #{question.text(locale: :it)}"
puts "French: #{question.text(locale: :fr)}"

# 10. In a controller context
class QuestionsController < ApplicationController
  def translate
    @question = AssessmentQuestion.find(params[:id])
    translator = TranslationService.new

    if translator.translate_record(@question)
      redirect_to @question, notice: 'Question translated successfully!'
    else
      redirect_to @question, alert: 'Translation failed.'
    end
  end

  def translate_assessment
    @assessment = Assessment.find(params[:id])
    translator = TranslationService.new

    results = translator.translate_assessment(@assessment)

    flash[:notice] = "Translation completed! Questions: #{results[:questions][:success]} success, Options: #{results[:options][:success]} success"
    redirect_to @assessment
  end
end

# 11. In a background job
class TranslationJob < ApplicationJob
  queue_as :default

  def perform(assessment_id)
    assessment = Assessment.find(assessment_id)
    translator = TranslationService.new

    results = translator.translate_assessment(assessment)

    # Log results or send notification
    Rails.logger.info "Translation completed for Assessment ##{assessment_id}: #{results}"
  end
end

# 12. Bulk translate all assessments
Assessment.find_each do |assessment|
  translator = TranslationService.new
  results = translator.translate_assessment(assessment)
  puts "Translated Assessment ##{assessment.id}: #{results}"
end
