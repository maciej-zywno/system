class Backtester

  MA_PERIOD = 50
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
    peak_days = [Date.new(1994,3,7),Date.new(1998,4,2),Date.new(2000,3,9),Date.new(2007,7,23),Date.new(2008,5,29),Date.new(2008,9,18),Date.new(2011,4,13)]
    start_day = peak_days[1]
    end_day = Date.new(2014,3,3)
    all_trading_days = Indicator.order('indicators.day ASC').pluck(:day).reject{|day| skip_day?(day)}
    start_index = all_trading_days.index(start_day)
    end_index = all_trading_days.index(end_day)
    raise 'foo' unless end_index
    all_trading_days_from_peak_day = all_trading_days[start_index..end_index]
    system_trigger_days = all_trading_days_from_peak_day.each_slice(TRADE_PERIOD).map(&:last)

    next_day_per_day = next_day_per_day(all_trading_days)

    cash = INITIAL_CASH
    fees = 0
    trades = []
    current_positions = {}

    system_trigger_days.each do |day|
      my_puts "DAY:#{day}", log=true
      next_day = next_day_per_day[day]
      raise "no next_day found for #{day}" unless next_day
      next_day_indicator = indicator(next_day)
      next_day_indicators_by_symbol = index_indicators_by_symbol(next_day_indicator.indicators[MA_PERIOD.to_s])

      symbols_with_highest_rs = symbols_with_highest_rs(day, EXPECTED_VOLUME)
      common_symbols = symbols_with_highest_rs & current_positions.keys
      out_symbols = current_positions.keys - common_symbols
      in_symbols = symbols_with_highest_rs - common_symbols
      my_puts "CURRENT: #{current_positions.keys}"
      my_puts "OUT:#{out_symbols}"
      my_puts "IN:#{in_symbols}"

      my_puts "CASH before SELL=#{cash.round(2)}"
      # close positions
      out_symbols.each do |symbol|
        sell_price, sell_day = trade_day_and_price(symbol, day, next_day, next_day_indicators_by_symbol, next_day_per_day)
        buy_price, buy_signal_day, buy_day, shares = [:buy_price, :buy_signal_day, :buy_day, :shares].map{|key| current_positions[symbol][key]}
        my_puts "sell #{shares} #{symbol} for #{shares*sell_price} B #{buy_price} S #{sell_price} with profit #{(sell_price - buy_price) * shares}, buy_day #{buy_day}, sell_signal_day #{day}, sell_day #{sell_day}"
        fee = sell_price * shares * FEE
        fees = fees + fee
        cash = cash + sell_price * shares - fee

        trades << current_positions[symbol].merge({ sell_price: sell_price, sell_signal_day: day, sell_day: sell_day})
        current_positions.delete(symbol)
      end

      cash_per_security = cash / in_symbols.length
      my_puts "CASH before BUY=#{cash.round(2)}"
      my_puts "CURRENT: #{current_positions.keys}"
      my_puts "cash_per_security=#{cash_per_security}"
      my_puts "IN: #{in_symbols}"
      # open positions
      in_symbols.each do |symbol|
        buy_price, buy_day = trade_day_and_price(symbol, day, next_day, next_day_indicators_by_symbol, next_day_per_day)
        shares = (cash_per_security / buy_price).floor
        my_puts "buying #{shares} at #{buy_price} of #{symbol} for #{shares * buy_price}"
        fee = buy_price * shares * FEE
        fees = fees + fee
        cash = cash - shares * buy_price - fee
        current_positions[symbol] = { buy_price: buy_price, buy_signal_day: day, buy_day: buy_day, shares: shares }
      end
    end

    current_positions.each do |symbol, position|
      my_puts position[:buy_price] * position[:shares]
    end
    my_puts("balance=#{current_positions.map{|symbol, position| position[:buy_price] * position[:shares]}.sum}", log=true)
    my_puts("cash=#{cash}", log=true)
    my_puts("fees=#{fees}", log=true)
    my_puts("trade count=#{trades.length}", log=true)
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
      index = index_indicators_by_symbol(indicator(day).indicators[MA_PERIOD.to_s])
      symbols_with_highest_rs = []
      potential_symbols.each do |symbol|
        market_volume = index[symbol]['volume']*index[symbol]['sod']
        if index[symbol]['sod'] > 0.5 && market_volume > expected_volume
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
      indicator = indicator(day)
      unless indicator.symbols_with_highest_rs[MA_PERIOD.to_s]
        puts "day=#{day}"
      end
      indicator.symbols_with_highest_rs[MA_PERIOD.to_s].first(EQUITY_COUNT)
    end
  end

  def trade_day_and_price(symbol, day, next_day, next_day_indicators_by_symbol, next_day_per_day)
    next_day_indicators = next_day_indicators_by_symbol[symbol]
    trade_day = next_day
    if next_day_indicators.nil?
      next_day_indicators_hash = next_day_indicators(day, symbol, next_day_per_day)
      next_day_indicators = next_day_indicators_hash[:indicators]
      trade_day = next_day_indicators_hash[:day]
    end
    raise "#{symbol} #{next_day_indicators_by_symbol.keys}" unless next_day_indicators

    price = next_day_indicators['sod']
    raise 'null price' unless price
    raise 'null trade_day' unless trade_day
    return price, trade_day
  end

  def next_day_indicators(day, symbol, next_day_per_day)
    next_day_indicators = nil
    temp_day = day
    i = 0
    while next_day_indicators.nil?
      i = i + 1
      raise 'break_too_long' if i > 40
      my_puts "no sod px found for #{temp_day} and #{symbol}"
      temp_day = next_day_per_day[temp_day]
      next_day_indicators = index_indicators_by_symbol(indicator(temp_day).indicators[MA_PERIOD.to_s])[symbol]
    end
    raise "null temp_day" unless temp_day
    {indicators: next_day_indicators, day: temp_day}
  end

  def indicator(day)
    Indicator.where(day: day).first!
  end

  def next_day_per_day(days)
    next_day_per_day = {}
    days.each_with_index { |day, index| next_day_per_day[day] = days[index+1] }
    next_day_per_day
  end

  def index_indicators_by_symbol(indicators)
    indicators_by_symbol = {}

    indicators.each do |hash|
      indicators_by_symbol[hash['symbol']] = hash
    end

    indicators_by_symbol
  end

  def my_puts(text, log=false)
    puts(text) if log
  end
end