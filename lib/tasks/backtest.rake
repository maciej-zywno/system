require 'csv'
require_relative '../../app/models/indicator'
require_relative '../../app/models/moving_averager'
# http://finanse.wp.pl/do,,isin,,mq,,od,,page,12,sector,PL9999999995,sort,d1,gielda-dywidendy.html
# http://stooq.pl/db/h/
namespace :backtest do

  task :fill do
    MA_PERIOD = 130
    symbols = Dir.entries('lib/eod').select{|file_name| file_name.ends_with?('.txt')}.map{|file_name| file_name.split('.')[0]}

    data_per_symbol_per_day = {}
    symbols[0..5].each do |symbol|
      ma = MovingAverager.new(MA_PERIOD)
      puts symbol
      read_data_per_day(open("lib/eod/#{symbol}.txt")).each {|day, data|
        ma << data[:c]
        rs = (data[:c] - ma.average) / ma.average * 100
        if rs.to_s != 'NaN'
          data_per_symbol_per_day[day] = {} unless data_per_symbol_per_day[day]
          data_per_symbol_per_day[day][symbol] = data.merge(rs: rs.round(2).to_f, ma: ma.average.round(2).to_f)
        end
      }
    end

    data_per_symbol_per_day.each do |day, data_per_symbol|
      Indicator.create!(day: day, indicators: data_per_symbol)
    end


    days = price_per_symbol_per_day.keys
    next_day_per_day = {}
    days.each do |day|
      next_day = days[days.index(day) + 1]
      next_day_per_day[day] = next_day
    end
    CSV.open('next_day_per_day.csv', 'w') do |csv|
      next_day_per_day.each do |day, next_day|
        csv << [day, next_day]
      end
    end

    data_per_symbol_per_day.sort_by{|k,v| k}.each do |day, rs_per_symbol|
      if day > 20000000
        puts "Day: #{day}"
        rs_per_symbol = data_per_symbol_per_day[day].sort_by { |k, v| v }.reverse
        i = 0
        rs_per_symbol.each do |symbol, rs|
          break if i > 19
          if price_per_symbol_per_day[day][symbol] > 1
            i = i + 1
            next_day_price = next_day_price(symbol, day, next_day_per_day, price_per_symbol_per_day)
            puts "#{day},#{symbol},#{rs},#{price_per_symbol_per_day[day][symbol]},#{next_day_price}"
          end
        end
      end
    end
    puts "data_per_symbol_per_day=#{data_per_symbol_per_day.inspect}"
  end

  task :run do
    next_day_per_day = {}
    CSV.parse(open('next_day_per_day.csv')).each do |row|
      day, next_day = row.map(&:to_i)
      next_day_per_day[day] = next_day
    end

    data_per_day_per_symbol = {}
    Dir.entries('lib/eod').select{|file_name| file_name.ends_with?('.txt')}.each{|file_name|
      symbol = file_name.split('.')[0]
      data_per_day_per_symbol[symbol] = read_data_per_day(open("lib/eod/#{symbol}.txt"))
    }

    next_day_price_per_symbol_per_day = {}
    CSV.parse(open('foo.csv')).each do |row|
      day = row[0].to_i
      symbol = row[1].to_s
      next_day_price = row[4].to_f.round(2)

      next_day_price_per_symbol_per_day[day] = {} unless next_day_price_per_symbol_per_day[day]
      next_day_price_per_symbol_per_day[day][symbol] = next_day_price
    end
    profits = []
    sparse_next_day_price_per_symbol_per_day = {}
    i = 0
    next_day_price_per_symbol_per_day.each do |day, v|
      if i % 20 == 0
        sparse_next_day_price_per_symbol_per_day[day] = v
      end
      i = i + 1
    end
    entry_price_per_symbol = {}
    sparse_next_day_price_per_symbol_per_day.each do |day, next_day_price_per_symbol|
      # puts "DAY: #{day}"
      entry_price_per_symbol.each do |symbol, entry_price|
        if next_day_price_per_symbol.keys.include?(symbol)
          # the position stays open
          # puts "#{symbol} stays as open position"
        else
          # the position is closed
          # puts "#{symbol} position is closed"
          # puts entry_price_per_symbol
          entry_price = entry_price_per_symbol[symbol]
          if (entry_price.nil? or entry_price == 0)
            puts "entry_price_per_symbol=#{entry_price_per_symbol}"
            puts "symbol=#{symbol}"
            raise "bar"
          end
          exit_price = exit_price_1(symbol, day, next_day_per_day, data_per_day_per_symbol)
          # puts "exit_price=#{exit_price}"
          unless exit_price
            puts "next_day_per_day=#{next_day_per_day}"
            puts "price_per_day_per_symbol[symbol]=#{data_per_day_per_symbol[symbol]}"
            puts "symbol=#{symbol}"
            puts "day=#{day}"
            puts "next_day_per_day[day]=#{next_day_per_day[day]}"
            raise "foo"
          end
          profit = (exit_price - entry_price)*(1000 / entry_price)
          if profit > 10000
            puts ""
            exit
          end
          profits << profit
          puts "#{symbol.upcase}, shares #{(AMOUNT / entry_price).round(1)} B=#{entry_price}, S=#{exit_price}"
          entry_price_per_symbol.delete(symbol)
        end
      end
      next_day_price_per_symbol.each do |symbol, next_day_price|
        if entry_price_per_symbol.keys.include?(symbol)
          # nothing
        else
          # position is opened
          unless next_day_price.to_s == '0.0'
            # puts "#{symbol.upcase} position is opened at #{next_day_price} on #{day}"
            entry_price_per_symbol[symbol] = next_day_price
          end
        end
      end
    end

    # profits.sort.each{|p| puts p}
    puts "SUM=#{profits.sum}"
  end

  # @return hash: day -> data
  def read_data_per_day(csv_file)
    array = CSV.read csv_file
    array.shift
    array.inject({}){|result, a| result[a[0].to_i] =
        {
            o: a[1].to_i,
            h: a[1].to_i,
            l: a[2].to_i,
            c: a[3].to_i,
            v: a[4].to_i
        }; result}
  end
end

