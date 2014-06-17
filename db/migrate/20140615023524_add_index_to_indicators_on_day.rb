class AddIndexToIndicatorsOnDay < ActiveRecord::Migration
  def change
    add_index :indicators, :day, unique: true
  end
end
