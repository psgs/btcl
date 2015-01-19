#!/usr/bin/env ruby
require 'json'
require 'net/http'
require 'open-uri'
require 'optparse'
require 'tty'

table = TTY::Table.new

# btcl pre-determines the top btc exchanges
$top = {
    'BTC CHINA' => 'btcnCNY',
    'Mt. Gox USA' => 'mtgoxUSD',
    'BitStamp' => 'bitstampUSD',
    'btc-e' => 'btceUSD',
    'Mt.Gox EUROPE' => 'mtgoxEUR',
    'Mt.Gox JAPAN' => 'mtgoxJPY',
    'bitcoin.de' => 'btcdeEUR',
    'Bitcurex' => 'bitcurexPLN',
    'Canadian Virtual Exchange' => 'virtexCAD',
    'Mt.Gox UK' => 'mtgoxGBP'
}

def get_top(url)
  exchanges = []
  names = []
  begin
    open(url) do |d|
      json = JSON.parse(d.read)
      $top.each do |k, v|
        json.each do |a|
          if a.has_value?(v)
            exchanges << a
            names << k
          end
        end
      end
      return true, exchanges, names
    end
  rescue SocketError => e
    return false, 'bity Error: Could not connect to BitCoin Charts API.'
  end
end

def get_ex(url, symbol)
  begin
    open(url) do |d|
      json = JSON.parse(d.read)
      json.each do |a|
        a.each do |k, v|
          if k == 'symbol' and v == symbol
            return true, a
          end
        end
      end
      return false, 'bity Error: Symbol not found in BitCoin API.'
    end
  rescue SocketError => e
    return false, 'bity Error: Could not connect to BitCoin Charts API.'
  end
end


options = {}

OptionParser.new do |opt|
  opt.banner = 'Usage: btcl <SYMBOL> [options]'
  opt.separator ''
  opt.separator 'Exchange Symbols:'
  opt.separator '\tView all symbols at http://bitcoincharts.com/markets/'
  opt.separator '\t*Popular markets below*'
  opt.separator ''
  opt.separator '\tmtgoxUSD - Mt.Gox USA'
  opt.separator '\tbtcnCHY - BTC CHINA'
  opt.separator '\tbitstampUSD - BitStamp USA'
  opt.separator '\tbtceUSD - btc-e USA'
  opt.separator '\tmtgoxEUR - Mt.Gox EUROPE'
  opt.separator '\tmtgoxJPY - Mt.Gox JAPAN'
  opt.separator '\tbtcdeEUR - bitcoin.de'
  opt.separator '\tbitcurexPLN - Bitcurex'
  opt.separator '\tvirtexCAD - Canadian Virtual Exchange'
  opt.separator '\tmtgoxGBP - Mt.Gox UK'
  opt.separator ''
  opt.separator 'Options'
  opt.separator '    -h, --help: See this screen'

  opt.on('-v', '--[no-]verbose', 'Get information verbosely.') do |v|
    options[:verbose] = v
  end

end.parse!

case ARGV[0]
  when nil
    info = get_top('http://api.bitcoincharts.com/v1/markets.json')
    if options[:verbose]
      puts 'bity Error: There\'s no verbose option for the top exchanges.'
      Process.exit(0)
    end

    if info[0]
      array = []
      info[1].each_with_index do |quote, i|
        message = '%s' % quote['ask']
        verbose_message = "high :: %s\t\tlow :: %s\nask :: %s\t\tbid :: %s\nclose :: %s\t\t\tavg :: %s" % [quote['high'], quote['low'], quote['ask'], quote['bid'], quote['close'], quote['avg']]
        if info[2][i].include? 'BitStamp'
          pastel = Pastel.new
          text = pastel.greeen(info[2][i])
          value = pastel.green(message)
          array << [text, value]
        else
          array << [info[2][i], message]
        end
      end
      table = TTY::Table.new %w[Exchange price], array
      puts table.render :ascii, multiline: true
    else
      puts info[1]
    end
  else
    info = get_ex('http://api.bitcoincharts.com/v1/markets.json', ARGV[0])
    if info[0]
      quote = info[1]
      message = '%s' % quote['ask']
      table = TTY::Table.new %w[Exchange price], [['high', quote['high'].to_s], ['low', quote['low']], ['ask', quote['ask']], ['bid', quote['bid']], ['close', quote['close']], ['avg', quote['avg']]]
      if options[:verbose]
        puts table.render :ascii, multiline: true
      else
        puts message
      end
    else
      puts info[1]
    end
end
