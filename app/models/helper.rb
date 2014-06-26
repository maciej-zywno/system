class Helper

  def initialize(fee)
    @fee = fee
  end

  def wrap_in_order(transactions)
    total_cost = 0
    shares = 0
    transactions.each do |transaction|
      shares += transaction[:shares]
      total_cost += total_cost(transaction)
    end

    { total_cost: total_cost, shares: shares }
  end

  private

    def total_cost(transaction)
      transaction[:average_price] * transaction[:shares] * (1 + @fee)
    end

end