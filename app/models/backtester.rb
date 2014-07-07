#http://www.highcharts.com/stock/demo/candlestick-and-volume
class Backtester

  MAX_NON_TRADING_DAY_FOR_SYMBOL = 40
  MA_PERIOD = 130
  INITIAL_CASH = 100 * 1000
  FEE = 0.0019
  TRADE_PERIOD = 15
  EQUITY_COUNT = 30
  SKIP_CHEAP_SHARE = false
  SKIPPED_DAYS = [Date.new(2001,4,13),Date.new(2002,5,30),Date.new(2003,04,21),Date.new(2003,06,19),Date.new(2004,2,12),
                  Date.new(2005,3,28),Date.new(2006,4,14), Date.new(2008,5,22),
                  Date.new(2014,1,6),Date.new(1999,12,29),Date.new(1999,12,30),Date.new(1999,12,31)]
  EXPECTED_VOLUME = 10 * 1000

  # TRADE_PERIOD = 20
  # 87 - 1994-03-07
  # 139 - 1998-04-02, balance:2.700.774
  # 164 - 2000-03-09, balance:2.469.111
  # 259 - 2007-07-23, balance:60.000
  # 270 - 2008-05-29, balance:85.334
  # 274 - 2008-09-18, balance:108850
  # 307 - 2011-04-13, balance:81317

  def run
    all_trading_days, system_trigger_days = get_system_trigger_days
    next_day_per_day = next_day_per_day(all_trading_days)
    @repository = Repository.new(MAX_NON_TRADING_DAY_FOR_SYMBOL, next_day_per_day)
    @executor = Executor.new(@repository)
    @helper = Helper.new(FEE)

    cash = INITIAL_CASH
    executed_orders = []
    current_positions = {}

    system_trigger_days.each do |day|
      my_puts "DAY:#{day}", log=true
      raise "no next_day found for #{day}" unless next_day_per_day[day]

      symbols_with_highest_rs = symbols_with_highest_rs(day, EXPECTED_VOLUME)

      common_symbols = symbols_with_highest_rs & current_positions.keys
      out_symbols = current_positions.keys - common_symbols
      in_symbols = symbols_with_highest_rs - common_symbols

      out_symbols.each do |symbol|
        shares = current_positions[symbol][:shares]
        puts "current_positions[symbol]=#{current_positions[symbol]}"
        transactions = @executor.execute_sell_order(symbol, shares, next_day_per_day[day])
        order = @helper.wrap_in_order(transactions)
        cash = cash - order[:total_cost]

        executed_orders << order
        current_positions.delete(symbol)
      end

      cash_per_security = cash / in_symbols.length
      in_symbols.each do |symbol|
        shares = shares_sought(symbol, cash_per_security, day)
        transactions = @executor.execute_buy_order(symbol, shares, next_day_per_day[day])
        order = @helper.wrap_in_order(transactions).merge(buy_signal_day: day)
        cash = cash - order[:total_cost]
        executed_orders << order
        current_positions[symbol] = order
      end
    end
  end

  def get_system_trigger_days
    peak_days = [Date.new(1994, 3, 7), Date.new(1998, 4, 2), Date.new(2000, 3, 9), Date.new(2007, 7, 23), Date.new(2008, 5, 29), Date.new(2008, 9, 18), Date.new(2011, 4, 13)]
    start_day = peak_days[1]
    end_day = Date.new(2014, 3, 3)
    all_trading_days = Indicator.order('indicators.day ASC').pluck(:day).reject { |day| skip_day?(day) }
    start_index = all_trading_days.index(start_day)
    end_index = all_trading_days.index(end_day)
    raise 'foo' unless end_index
    all_trading_days_from_peak_day = all_trading_days[start_index..end_index]
    system_trigger_days = all_trading_days_from_peak_day.each_slice(TRADE_PERIOD).map(&:last)
    return all_trading_days, system_trigger_days
  end

  def skip_day?(day)
    return true if SKIPPED_DAYS.include?(day)
    return true if (day.month == 5 && (day.day == 1 || day.day == 3))
    return true if (day.month == 11 && (day.day == 1 || day.day == 11))
    return true if (day.month == 8 && day.day == 15)
    return true if (day.month == 12 && day.day == 24)
  end

  def symbols_with_highest_rs(day, expected_volume)
    if SKIP_CHEAP_SHARE
      potential_symbols = indicator(day).symbols_with_highest_rs[MA_PERIOD.to_s]
      index = indicator(day).ohlcv_per_symbol
      symbols_with_highest_rs = []
      potential_symbols.each do |symbol|
        market_volume = index[symbol]['v']*index[symbol]['o']
        if index[symbol]['o'] > 0.5 && market_volume > expected_volume
          symbols_with_highest_rs << symbol
        else
          # puts "skip #{symbol} as price=#{index[symbol]['sod']} and volume=#{index[symbol]['volume']}"
        end
        break if symbols_with_highest_rs.length >= EQUITY_COUNT
      end
      if symbols_with_highest_rs.length < EQUITY_COUNT
        puts day
        puts potential_symbols.inspect
        raise "not enough symbols_with_highest_rs #{symbols_with_highest_rs.length}"
      end
      symbols_with_highest_rs
    else
      indicator = @repository.indicator(day)
      unless indicator.symbols_with_highest_rs[MA_PERIOD.to_s]
        puts "day=#{day}"
      end
      indicator.symbols_with_highest_rs[MA_PERIOD.to_s].first(EQUITY_COUNT)
    end
  end

  def next_day_per_day(days)
    next_day_per_day = {}
    days.each_with_index { |day, index| next_day_per_day[day] = days[index+1] }
    next_day_per_day
  end

  def shares_sought(symbol, approximate_cash, day)
    _, indicators = @repository.soonest_ohlcv(symbol, day)
    (approximate_cash / indicators['o']).round
  end

  def my_puts(text, log=false)
    puts(text) if log
  end
end