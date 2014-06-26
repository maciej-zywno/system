class Repository

  def initialize(max_non_trading_day_for_symbol, next_day_per_day)
    @max_non_trading_day_for_symbol = max_non_trading_day_for_symbol
    @next_day_per_day = next_day_per_day
  end

  # return hash {"symbol"=>"alm", "rs"=>51.985, "ma"=>6.645} for a given symbol and a day
  # (or the following day if there's no indicators for a given day)
  def soonest_ohlcv(symbol, day)
    ohvlc = ohlcv(day, symbol)

    current_day = day
    i = 0
    while ohvlc.nil?
      current_day = @next_day_per_day[current_day]
      ohvlc = ohlcv(current_day, symbol)
      raise "break_too_long for #{symbol}" if (i += 1) > @max_non_trading_day_for_symbol
    end

    [current_day, ohvlc]
  end

  def next_day(day)
    raise "no next day for #{@next_day_per_day[day]}" if @next_day_per_day[day].nil?

    @next_day_per_day[day]
  end

  def indicator(day)
    Indicator.where(day: day).first!
  end

  private

    def ohlcv(day, symbol)
      indicator(day).ohlcv_per_symbol[symbol]
    end
end