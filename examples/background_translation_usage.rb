# Background Translation System Usage Examples
# =============================================

# The system now uses TranslationService within background jobs for optimal performance

# 1. AUTOMATIC TRANSLATION (via callbacks)
# ========================================

# When you create a question, it automatically queues a translation job
question = AssessmentQuestions::MultipleChoice.create!(
  text: "What is your favorite programming language?",
  default_locale: "en",
  assessment: assessment,
  assessment_section: section
)

# This triggers:
# - after_save callback in AssessmentQuestion
# - queue_translation_job method
# - TranslationJob.perform_later("AssessmentQuestion", question.id, "en")

# 2. BACKGROUND JOB PROCESSING
# ============================

# The TranslationJob processes asynchronously:
class TranslationJob < ApplicationJob
  def perform(record_type, record_id, source_locale = 'en')
    record = record_type.constantize.find(record_id)
    translator = TranslationService.new

    # Get source text using Mobility
    Mobility.with_locale(source_locale.to_sym) do
      source_text = record.text
    end

    # Translate to each target locale
    target_locales.each do |target_locale|
      # Use TranslationService public API
      translated_text = translator.translate_text_between_locales(
        source_text, source_locale, target_locale
      )

      # Set translation using Mobility
      Mobility.with_locale(target_locale) do
        record.text = translated_text
      end
    end

    record.save!
  end
end

# 3. ACCESSING TRANSLATIONS
# =========================

# After the job processes, access translations using Mobility:
question = AssessmentQuestion.find(1)

Mobility.with_locale(:en) { question.text }  # "What is your favorite programming language?"
Mobility.with_locale(:es) { question.text }  # "¿Cuál es tu lenguaje de programación favorito?"
Mobility.with_locale(:ja) { question.text }  # "好きなプログラミング言語は何ですか？"
Mobility.with_locale(:it) { question.text }  # "Qual è il tuo linguaggio di programmazione preferito?"
Mobility.with_locale(:fr) { question.text }  # "Quel est votre langage de programmation préféré ?"

# 4. MANUAL JOB EXECUTION (for testing)
# =====================================

# Execute job immediately
TranslationJob.perform_now("AssessmentQuestion", question.id, "en")

# Queue job for later processing
TranslationJob.perform_later("AssessmentQuestion", question.id, "en")

# 5. BOOLEAN QUESTIONS (auto-create localized options)
# ===================================================

boolean_question = AssessmentQuestions::BooleanType.create!(
  text: "Do you enjoy coding?",
  default_locale: "en",
  assessment: assessment,
  assessment_section: section
)

# This creates:
# 1. The question (queues translation job)
# 2. Two options: "True" and "False" (each queues translation job)

# After processing, options are available in all locales:
boolean_question.option.each do |option|
  puts "EN: #{Mobility.with_locale(:en) { option.text }}"
  puts "ES: #{Mobility.with_locale(:es) { option.text }}"
  puts "JA: #{Mobility.with_locale(:ja) { option.text }}"
end

# 6. MULTIPLE CHOICE WITH OPTIONS
# ===============================

mc_question = AssessmentQuestions::MultipleChoice.create!(
  text: "What is your experience level?",
  default_locale: "en",
  assessment: assessment,
  assessment_section: section,
  option_attributes: [
    { text: "Beginner", order: 1, assessment: assessment, default_locale: "en" },
    { text: "Intermediate", order: 2, assessment: assessment, default_locale: "en" },
    { text: "Advanced", order: 3, assessment: assessment, default_locale: "en" }
  ]
)

# This queues 4 translation jobs:
# - 1 for the question
# - 3 for the options

# 7. DIRECT SERVICE USAGE (legacy/manual)
# =======================================

# You can still use TranslationService directly if needed:
translator = TranslationService.new

# Translate a single record (old way, but still supported)
translator.translate_record(question, :en, [:es, :fr])

# Translate entire assessment
results = translator.translate_assessment(assessment)

# Translate specific text between locales (new public method)
translated = translator.translate_text_between_locales(
  "Hello world", :en, :es
)
# Returns: "Hola mundo"

# 8. MONITORING & DEBUGGING
# =========================

# Check translation status
task :check_translations, [:model, :id] => :environment do |t, args|
  record = args[:model].constantize.find(args[:id])

  Rails.application.config.i18n.available_locales.each do |locale|
    Mobility.with_locale(locale) do
      translation = record.text
      puts "#{locale.upcase}: #{translation || 'Not translated'}"
    end
  end
end

# Usage: rails test:check_translations[AssessmentQuestion,123]

# 9. ERROR HANDLING
# =================

# The system includes comprehensive error handling:
begin
  TranslationJob.perform_now("AssessmentQuestion", 999, "en")
rescue ActiveRecord::RecordNotFound => e
  puts "Record not found: #{e.message}"
rescue TranslationService::TranslationError => e
  puts "Translation failed: #{e.message}"
end

# 10. CONFIGURATION EXAMPLES
# ==========================

# Enable in development
# export ENABLE_AUTO_TRANSLATION=true
# export GOOGLE_API_KEY=your_api_key

# Check if auto-translation is enabled
puts "Auto-translation: #{Rails.application.config.auto_translation_enabled}"

# Check available locales
puts "Available locales: #{Rails.application.config.i18n.available_locales}"

# Check job queue adapter
puts "Job adapter: #{Rails.application.config.active_job.queue_adapter}"
