class Executor

  def initialize(repository)
    @repository = repository
  end

  def execute_buy_order(symbol, shares, day)
    return execute_order('buy', symbol, shares, day)
  end


    def execute_sell_order(symbol, shares, day)
    return execute_order('sell', symbol, shares, day)
  end

  private

    def execute_order(buy_or_sell, symbol, shares, day)
      raise unless buy_or_sell && symbol && shares && day
      transactions = []
      traded_shares = 0

      current_day = day
      while traded_shares < shares
        transaction = execute_next_transaction(buy_or_sell, symbol, current_day, shares - traded_shares)

        transactions << transaction

        traded_shares += transaction[:shares]
        current_day = @repository.next_day(transaction[:day])
      end

      return transactions
    end

    def execute_next_transaction(buy_or_sell, symbol, day, shares)
      transaction_day, ohvlc = @repository.soonest_ohlcv(symbol, day)
      transaction_average_price, transaction_shares = execute_transaction(shares, ohvlc, buy_or_sell)
      {day: transaction_day, shares: transaction_shares, average_price: transaction_average_price}
    end

    def execute_transaction(shares, ohlcv, buy_or_sell)
      # take max 10% of total volume at the worst price
      traded_shares = shares > ohlcv['v'] * 0.1 ? ohlcv['v'] * 0.1 : shares
      average_price = buy_or_sell == 'buy' ? ohlcv['h'] : ohlcv['l']

      return average_price, traded_shares
    end

    def shares(symbol, cash, day)
      day, indicators = @repository.soonest_ohlcv(symbol, day)
      (cash / indicators.ohlcv_per_symbol[symbol]['o']).round
    end

end