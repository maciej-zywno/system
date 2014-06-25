class Executor

  def initialize(repository)
    @repository = repository
  end

  def execute_buy_order(symbol, shares, day, next_day_per_day)
    return execute_order('buy', symbol, shares, day, next_day_per_day)
  end


  def execute_sell_order(symbol, shares, day, next_day_per_day)
    return execute_order('sell', symbol, shares, day, next_day_per_day)
  end

  private

    def execute_order(buy_or_sell, symbol, shares, day, next_day_per_day)
      raise unless buy_or_sell && symbol && shares && day && next_day_per_day
      transactions = []
      traded_shares = 0

      while traded_shares < shares
        day, ohvlc = @repository.soonest_ohlcv(symbol, day, next_day_per_day)
        average_price, transaction_shares = execute_transaction(shares - traded_shares, ohvlc, buy_or_sell)
        transaction = {day: day, shares: transaction_shares, average_price: average_price }

        transactions << transaction
        traded_shares += transaction[:shares]
      end

      return transactions
    end

    def execute_transaction(shares_sought, ohvlc, buy_or_sell)
      # take max 10% of total volume at the worst price
      traded_shares = shares_sought > ohvlc['v'] * 0.1 ? ohvlc['v'] * 0.1 : shares_sought
      average_price = buy_or_sell == 'buy' ? ohvlc['h'] : ohvlc['l']

      return average_price, traded_shares
    end

    def shares(symbol, cash, day, next_day_per_day)
      day, indicators = @repository.soonest_ohlcv(symbol, day, next_day_per_day)
      (cash / indicators.ohlcv_per_symbol[symbol]['o']).round
    end

end