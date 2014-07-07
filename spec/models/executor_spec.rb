require 'rails_helper'

describe Executor do

  let(:repository) { double }
  let(:executor) { Executor.new(repository) }

  describe '.execute_order' do
    before do
      allow(executor).to receive(:execute_next_transaction).with('buy_or_sell', 'symbol', 'day1', 111) {
        {day: 'day1', shares: 1, average_price: 'transaction_average_price_1'}
      }
      allow(executor).to receive(:execute_next_transaction).with('buy_or_sell', 'symbol', 'day2', 110) {
        {day: 'day2', shares: 2, average_price: 'transaction_average_price_2'}
      }
      allow(executor).to receive(:execute_next_transaction).with('buy_or_sell', 'symbol', 'day3', 108) {
        {day: 'day3', shares: 108, average_price: 'transaction_average_price_3'}
      }

      allow(repository).to receive(:next_day).with('day1') { 'day2'}
      allow(repository).to receive(:next_day).with('day2') { 'day3'}
      allow(repository).to receive(:next_day).with('day3') { 'whatever'}
    end

    subject(:transactions) { executor.send(:execute_order, 'buy_or_sell', 'symbol', 111, 'day1') }

    it 'creates correct transactions' do
      expect(subject.length).to eq(3)
      expect(subject[0]).to eq({day: 'day1', shares: 1, average_price: 'transaction_average_price_1'})
      expect(subject[1]).to eq({day: 'day2', shares: 2, average_price: 'transaction_average_price_2'})
      expect(subject[2]).to eq({day: 'day3', shares: 108, average_price: 'transaction_average_price_3'})
    end
  end

  describe '.execute_next_transaction' do
    before do
      allow(repository).to receive(:soonest_ohlcv).with('symbol', 'day') { ['transaction_day', 'ohvlc'] }
      allow(executor).to receive(:execute_transaction).with('shares', 'ohvlc', 'buy_or_sell') { ['transaction_average_price', 'transaction_shares'] }
    end

    subject(:transaction) { executor.send(:execute_next_transaction, 'buy_or_sell', 'symbol', 'day', 'shares') }

    it 'creates correct transaction' do
      expect(subject).to eq({day: 'transaction_day', shares: 'transaction_shares', average_price: 'transaction_average_price'})
    end
  end

  describe '.execute_transaction' do
    let(:ohlcv) { {'o'=> 2.2, 'h'=> 4.4, 'l'=> 1.1, 'c'=> 3.3, 'v'=> 100} }

    context 'for buy order' do
      let(:buy_or_sell) { 'buy' }

      subject { executor.send(:execute_transaction, shares, ohlcv, buy_or_sell) }

      context 'for large shares' do
        let(:shares) { 50 }

        its([0]) { should == 4.4 }
        its([1]) { should == 10 }
      end

      context 'for small shares' do
        let(:shares) { 5 }

        its([0]) { should == 4.4 }
        its([1]) { should == 5 }
      end
    end
    
    context 'for sell order' do
      let(:buy_or_sell) { 'sell' }

      subject { executor.send(:execute_transaction, shares, ohlcv, buy_or_sell) }

      context 'for large shares' do
        let(:shares) { 50 }

        its([0]) { should == 1.1 }
        its([1]) { should == 10 }
      end

      context 'for small shares' do
        let(:shares) { 5 }

        its([0]) { should == 1.1 }
        its([1]) { should == 5 }
      end
    end
  end
end
