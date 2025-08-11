class CreateAssessmentResponseScores < ActiveRecord::Migration[8.0]
  def change
    create_table :assessment_response_scores do |t|
      t.decimal :score_earned, precision: 10, scale: 2, default: 0
      t.decimal :max_possible_score, precision: 10, scale: 2, default: 0
      t.jsonb :scoring_details, default: {}
      t.text :feedback
      t.references :assessment_question_response, null: false, foreign_key: true
      t.references :assessment_marking_scheme, null: false, foreign_key: true
      t.references :assessment_question_marking_rule, null: false, foreign_key: true
      t.timestamps
    end

    add_index :assessment_response_scores, :score_earned
    add_index :assessment_response_scores, :max_possible_score
  end
end
