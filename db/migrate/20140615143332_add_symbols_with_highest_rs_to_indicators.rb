class AddSymbolsWithHighestRsToIndicators < ActiveRecord::Migration
  def change
    add_column :indicators, :symbols_with_highest_rs, :json
  end
end
