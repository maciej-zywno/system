require 'rails_helper'

describe Repository do
  let(:day1) { Date.current }
  let(:day2) { day1.tomorrow }
  let(:day3) { day2.tomorrow }
  let(:day4) { day3.tomorrow }
  let(:day5) { day4.tomorrow }
  let(:next_day_per_day) { {day1=>day2,day2=>day3,day3=>day4,day4=>day5}}
  let(:max_non_trading_day_for_symbol) {2}
  let(:repository) { Repository.new(max_non_trading_day_for_symbol, next_day_per_day) }
  let(:symbol) { 'kgh' }

  describe '.soonest_ohlcv' do
    before do
      allow(repository).to receive(:ohlcv).with(day1, anything()) { 'ohlcv_1' }
      allow(repository).to receive(:ohlcv).with(day2, anything()) { 'ohlcv_2' }
      allow(repository).to receive(:ohlcv).with(day3, anything()) { 'ohlcv_3' }
      allow(repository).to receive(:ohlcv).with(day4, anything()) { 'ohlcv_4' }
      allow(repository).to receive(:ohlcv).with(day5, anything()) { 'ohlcv_5' }
    end

    context 'for ohlvc present for the first day' do
      let(:day) { day2 }
      subject { repository.send(:soonest_ohlcv, symbol, day) }

      its([0]) { should == day2 }
      its([1]) { should == 'ohlcv_2' }
    end

    context 'for ohlvc missing for the first day' do
      let(:day) { day2 }
      before { allow(repository).to receive(:ohlcv).with(day2, anything()) { nil } }

      context 'but present for the following day' do
        subject { repository.send(:soonest_ohlcv, symbol, day) }

        its([0]) { should == day3 }
        its([1]) { should == 'ohlcv_3' }
      end

      context 'and missing for 2(max_non_trading_day_for_symbol) days' do
        before do
          allow(repository).to receive(:ohlcv).with(day3, anything()) { nil }
          allow(repository).to receive(:ohlcv).with(day4, anything()) { nil }
        end

        it 'raises exception' do
          expect { repository.send(:soonest_ohlcv, symbol, day) }.to raise_error /break_too_long for/
        end
      end

      context 'and missing for all days' do
        let(:day) { day4 }
        before do
          allow(repository).to receive(:ohlcv).with(day4, anything()) { nil }
          allow(repository).to receive(:ohlcv).with(day5, anything()) { nil }
        end

        it 'raises exception' do
          expect { repository.send(:soonest_ohlcv, symbol, day) }.to raise_error /no next day for/
        end
      end
    end
  end
end
