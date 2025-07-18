class AddDefaultValueToMetaData < ActiveRecord::Migration[8.0]
  def change
    change_column_default :assessment_questions, :meta_data, {}
  end
end
