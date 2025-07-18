class SetDefaultValueForTextColumn < ActiveRecord::Migration[8.0]
  def change
    change_column_default :assessment_questions, :text, {}
  end
end
