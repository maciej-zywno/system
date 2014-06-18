class AddOhlcvPerSymbolToIndicators < ActiveRecord::Migration
  def change
    add_column :indicators, :ohlcv_per_symbol, :json
  end
end
