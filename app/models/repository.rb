class Repository

  # return hash {"symbol"=>"alm", "rs"=>51.985, "ma"=>6.645} for a given symbol and a day
  # (or the following day if there's no indicators for a given day)
  def soonest_ohlcv(symbol, day, next_day_per_day)
    ohvlc = indicator(day).ohlcv_per_symbol[symbol]

    current_day = day
    i = 0
    while ohvlc.nil?
      current_day = next_day_per_day[current_day]
      ohvlc = indicator(current_day).ohlcv_per_symbol[symbol]
      raise "break_too_long for #{symbol}" if (i += 1) > 40
    end
    raise 'null temp_day' unless current_day

    [current_day, ohvlc]
  end

  def indicator(day)
    Indicator.where(day: day).first!
  end

end