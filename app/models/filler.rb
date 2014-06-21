require 'csv'

class Filler
  # MA_PERIODS = [50, 100, 130, 150, 200]
  MA_PERIODS = [130]
  VOLUME_DAY_RANGES = [1]
  ROUND = 3

  def fill_symbols_with_highest_rs
    Indicator.all.each.each do |indicator|
      puts indicator.day
      symbols_with_highest_rs_per_period = {}
      MA_PERIODS.each do |period|
        symbols_with_highest_rs_per_period[period] = symbols_with_highest_rs(indicator.day, period, limit=200)
      end
      indicator.update_attributes!(symbols_with_highest_rs: symbols_with_highest_rs_per_period)
    end
  end

  def fill_ohlcv_per_symbol
    symbols = Dir.entries('lib/eod').select{|file_name| file_name.ends_with?('.txt')}.map{|file_name| file_name.split('.')[0]}
    ohlcv_per_symbol_per_day = {}
    symbols.each do |symbol|
      puts "#{symbol}"
      ohlcv_per_day(open("lib/eod/#{symbol}.txt")).each do |day, ohlcv|
        ohlcv_per_symbol_per_day[day] ||= {}
        ohlcv_per_symbol_per_day[day][symbol] = ohlcv
      end
    end
    ohlcv_per_symbol_per_day.each do |day, ohlcv_per_symbol|
      Indicator.create!(day: day, ohlcv_per_symbol: ohlcv_per_symbol)
    end
  end

  def fill_indicators
    symbols = Dir.entries('lib/eod').select{|file_name| file_name.ends_with?('.txt')}.map{|file_name| file_name.split('.')[0]}
    indicators_with_symbol_per_period_per_day = {}

    symbols.each do |symbol|
      puts "#{symbol}"
      ovhlc_per_day = SQL.select_all("select day, ohlcv_per_symbol->'#{symbol}' as f from indicators where (ohlcv_per_symbol->'#{symbol}') is not null order by day asc").rows

      MA_PERIODS.each do |period|
        ma = MovingAverager.new(period)
        ovhlc_per_day.each do |day, ovhlc|
          ovhlc = JSON.parse(ovhlc)
          ma << ovhlc['c']
          if ma.average
            rs = (ovhlc['c'] - ma.average) / ma.average * 100
            if rs.to_s != 'NaN'
              indicators_with_symbol_per_period_per_day[day] ||= {}
              indicators_with_symbol_per_period_per_day[day][period] ||= []
              indicators_with_symbol_per_period_per_day[day][period] << {symbol: symbol, rs: rs.round(ROUND).to_f, ma: ma.average.round(ROUND).to_f}
            end
          end
        end
      end
    end

    indicators_with_symbol_per_period_per_day.each do |day, indicators_with_symbol_per_period|
      indicator(day).update_attributes(indicators: indicators_with_symbol_per_period)
    end
  end

  private

    def indicator(day)
      Indicator.where(day: day).first!
    end

    def symbols_with_highest_rs(day, period, limit)
      sql = File.read('app/models/sql/symbol_by_highest_rs.sql')
      result = SQL.select_all(sql, period: period, day: day, minimum_c: 0, minimum_v: 0, record_limit: limit)
      result.rows.flatten
    end

    def ohlcv_per_day(file)
      data_per_day = {}
      CSV.parse(file, headers: true).each do |row|
        day = row[0].to_i
        o = row[1].to_f.round(ROUND)
        h = row[2].to_f.round(ROUND)
        l = row[3].to_f.round(ROUND)
        c = row[4].to_f.round(ROUND)
        v = row[5].to_i
        if o == 0.0
          puts row.inspect
          raise "day=#{day},o=#{o},h=#{h},l=#{l},c=#{c},v=#{v}"
        end
        data_per_day[day] = { o: o, h: h, l: l, c: c, v: v }
      end
      data_per_day
    end

end