require 'csv'

class Filler
  PERIODS = [50, 100, 130, 150, 200]
  # PERIODS = [130]
  ROUND = 3

  def fill_symbols_with_highest_rs
    Indicator.all.each.each do |indicator|
      puts indicator.day
      symbols_with_highest_rs_per_period = {}
      PERIODS.each do |period|
        symbols_with_highest_rs_per_period[period] = symbols_with_highest_rs(indicator.day, period, limit=200)
      end
      indicator.update_attributes!(symbols_with_highest_rs: symbols_with_highest_rs_per_period)
    end
  end


  def run
    symbols = Dir.entries('lib/eod').select{|file_name| file_name.ends_with?('.txt')}.map{|file_name| file_name.split('.')[0]}
    data_per_day = {}

    symbols.each do |symbol|
      puts "#{symbol}"
      file_data = read_data_per_day(open("lib/eod/#{symbol}.txt"))
      PERIODS.each do |period|
        ma = MovingAverager.new(period)
        file_data.each do |day, data|
          ma << data[:eod]
          if ma.average
            rs = (data[:eod] - ma.average) / ma.average * 100
            if rs.to_s != 'NaN'
              data_per_day[day] = {} if data_per_day[day].nil?
              data_per_day[day][period] = [] if data_per_day[day][period].nil?
              data_per_day[day][period] << data.merge(symbol: symbol, rs: rs.round(ROUND).to_f, ma: ma.average.round(ROUND).to_f)
            end
          end
        end
      end
    end

    indicators = []
    data_per_day.each do |day, data_per_symbol|
      indicators << Indicator.create!(day: day, indicators: data_per_symbol)
    end
  end

  private

    def symbols_with_highest_rs(day, period, limit)
      sql = File.read('app/models/sql/symbol_by_highest_rs.sql')
      result = SQL.select_all(sql, period: period, day: day, eod: 0, volume: 0, limit: limit)
      result.rows.flatten
    end

    def read_data_per_day(file)
      data_per_day = {}
      CSV.parse(file, headers: true).each do |row|
        day = row[0].to_i
        sod = row[1].to_f.round(ROUND)
        eod = row[4].to_f.round(ROUND)
        volume = row[5].to_i
        if sod == 0.0
          puts row.inspect
          raise "day=#{day},sod=#{sod},eod=#{eod}"
        end
        data_per_day[day] = {sod: sod, eod: eod, volume: volume }
      end
      data_per_day
    end

end