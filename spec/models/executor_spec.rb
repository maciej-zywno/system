require 'rails_helper'

describe Executor do

  let(:executor) { Executor.new(nil) }

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
