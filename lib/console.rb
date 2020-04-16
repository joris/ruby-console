class Console
  attr_accessor :logger
  attr_reader :last_time

  def initialize(logger = $stdout)
    @indentation_level = 0
    @line_count = 0
    @logger     = logger
    @counter    = 0
    @counters   = Hash.new(0)
    @first_on_line = true
    @last_time = nil
  end

  def print(text, level = :info)
    if @first_on_line
      if logger&.class&.to_s == "Logger"
        text = "#{ "\t" * (@indentation_level)}#{text}"
      else
        text = "\n#{ "\t" * (@indentation_level)}#{text}"
      end
      @first_on_line = false
    end
    if logger.kind_of?(IO)
      begin
        result = logger.send(:print, text&.to_s&.force_encoding("UTF-8"))
        $stdout.send(:print, text) unless logger == $stdout
        if logger.kind_of?(File)
          logger.send(:flush)
        end
        result
      rescue TypeError => exception
        logger.puts "CONSOLE exception: #{exception}"
        exception.backtrace.each do |line|
          logger.puts line
        end
      end
    else
      logger.send(level, text)
    end
  end

  def puts(text, level = :info)
    @line_count += 1
    print text.to_s
    # The next print statement should start with a new (indented) line:
    @first_on_line = true
  end

  # Whenever its body outputs 25 or more lines, then it will repeat what it said afterwards.
  def say(what, options = {}, &block)
    level = options[:level] || :info
    
    tags = options[:tags]
    
    puts what, level
    @indentation_level += 1
  
    started_at_line_count = @line_count
    result = nil
    
    time = Benchmark.realtime do
      begin
        result = yield if block_given?
        puts "", level if @counter > 0
      rescue Object => exception
        puts "", level
        if @counter > 0
          puts "EXCEPTION #{exception.class} at dot #{@counter}: #{exception}", level
        else
          puts "EXCEPTION #{exception.class}: #{exception}", level
        end
        raise exception
      end
    end
    
    if tags
      Array.wrap(tags).each do |tag|
        Appsignal.add_distribution_value("#{tag}/time", (time.to_f * 1_000).round)
        Appsignal.increment_counter("#{tag}/completion", 1)
      end
    end
    
    result
    
  ensure
    @indentation_level -= 1 unless @indentation_level == 0
    if @line_count - started_at_line_count.to_i >= 25
      print "<< #{what}", level
    end
    if options[:time] && time
      @last_time = time
      
      if options[:size] && options[:size].to_i > 0 && time.to_f > 0
        print " -> #{humanize(time)} at #{human_rate(options[:size], time)}", level
      else
        print " -> #{humanize(time)}", level
      end
    end
    @counter = 0
    @counters = Hash.new(0)
    @first_on_line = true
  end

  def dot(character = '.')
    @counter += 1
    @counters[character.to_sym] += 1
    print character
    if @counter > 1 && @counter % 100 == 0
      if @counters.size > 0
        puts " #{@counter} - #{@counters.sort.map{|name, count| "#{name}:#{count}" }.join(", ")}"
      else
        puts " #{@counter}"
      end
    end
  end

  def skip
    dot '>'
  end

  def failure
    dot 'x'
  end

  def error
    dot 'x'
  end

  ######
  # Convenience methods
    def say_with_time(what, options = {}, &block)
      if what =~ /^XXX\[/
        puts [:say_with_time, what, options].inspect
      end
      say what, options.merge(time: true), &block
    end
    # def say_with_result(what, *args)
    #   say what, :result => true, *args
    # end

private

  ######
  # Utilities

  def humanize(seconds)
    [[60, :seconds], [60, :minutes], [24, :hours], [1000, :days]].map do |count, name|
      if seconds > 0
        seconds, n = seconds.divmod(count)
        if name == :seconds
          "#{sprintf('%0.2f', n)} #{name}"
        else
          "#{n.to_i} #{name}"
        end
      end
    end.compact.reverse.join(' ')
  end
  
  def human_rate(size, seconds)
    rate = size.to_f / seconds
    case rate.abs
    when 0..1200
      unit = :B
    when 1200..(1200*1024)
      rate /= 1024
      unit = :KiB
    when 1200..(1200*1024**2)
      rate /= 1024**2
      unit = :MiB
    when 1200..(1200*1024**3)
      rate /= 1024**3
      unit = :GiB
    else
      rate /= 1024**4
      unit = :TiB
    end
    "#{sprintf("%0.1f", rate)} #{unit}/s"
  end
end

def console
  $console ||= Console.new
end

console.dot