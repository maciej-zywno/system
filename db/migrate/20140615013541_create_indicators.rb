class CreateIndicators < ActiveRecord::Migration
  def change
    create_table :indicators do |t|
      t.date :day
      t.json :indicators

      t.timestamps
    end
  end
end
