require_relative 'console'

module Inspector
  class Separator
    PROMPT_STRING =  "-> (v)alid (i)nvalid (d)rop (s)can (f)ix: " 

    def initialize
      @console = Console.new
    end

    def print_statistics(opts)
      puts "-> statistics"
      puts "   ----------"
      printf("%7s:   %4d\n%7s:   %4d\n%7s: %4d\n%7s:    %4d\n%7s:  %4d\n",
             "   total", opts[:valid_counter] + 
                         opts[:invalid_counter] +
                         opts[:skip_counter] +
                         opts[:double_counter],
             "   valid", opts[:valid_counter],
             "   invalid", opts[:invalid_counter],
             "   drop", opts[:skip_counter],
             "   double", opts[:double_counter])
      puts
      puts "-> pattern:      #{opts[:pattern].inspect}"
      puts "-> scan pattern: #{opts[:scan_pattern].inspect}"
      puts
      puts "-> files operated on"
      puts "   -----------------"
      puts "   values read from:          #{opts[:infile]}"
      puts "   valid values written to:   #{opts[:valid_file]}"
      puts "   invalid values written to: #{opts[:invalid_file]}"
      if opts[:note]
        puts
        puts "-> Note"
        puts "   ----"
        puts opts[:note]
      end
    end

    def fix(value, pattern) 
      choice = value
      result = {}

      while not pattern.match(choice)
        puts "-> #{choice}?"
        result[:answer] = @console.prompt PROMPT_STRING
        case result[:answer]
        when 'v'
          result[:value] = choice
          break
        when 'i'
          result[:value] = choice
          break
        when 'f'
          print "-> fix: "
          choice = gets.chomp
          print "-> confirm "
          redo
        when 'd'
          result[:value] = value
          break
        when 's'
          result[:value] = value
          break
        end
      end
    
      return result
    end

    def process(opts) 
      valid_file = File.open(opts[:valid_file], opts[:mode])
      valid_values = []

      invalid_file = File.open(opts[:invalid_file], 'w')
      invalid_values = []
      
      skip_counter = 0

      File.open(opts[:infile], 'r') do |file|
        while line = file.gets
          line.chomp.split(opts[:delimiter]).each do |value|
              
            match = value.match(opts[:pattern])

            if match.nil? 
              if opts[:fix]
                result = fix value, opts[:pattern] 
                case result[:answer]
                when 'v'
                  valid_values << result[:value]
                when 'i'
                  invalid_values << result[:value]
                when 'd'
                  skip_counter += 1
                when 's'
                  value.scan(opts[:scan_pattern]).each do |value|
                    valid_values << value
                  end
                end
              else
                invalid_values << value
              end
            else
              valid_values << match
            end
          end
        end
      end

      valid_counter = valid_values.size

      valid_values.uniq! {|value| value.downcase } if opts[:individualize]
      valid_values.sort! if opts[:sort]

      valid_values.each do |value|
          valid_file.puts value
      end

      invalid_counter = invalid_values.size

      invalid_values.uniq! {|value| value.downcase} if opts[:individualize]
      invalid_values.sort! if opts[:sort]

      invalid_values.each do |value|
          invalid_file.puts value
      end

      valid_file.close
      invalid_file.close
      
      double_counter = valid_counter - valid_values.size +
                       invalid_counter - invalid_values.size

      opts[:valid_counter] = valid_values.size 
      opts[:invalid_counter] = invalid_values.size 
      opts[:skip_counter] = skip_counter
      opts[:double_counter] = double_counter
      if (invalid_values.size > 0 and not opts[:fix])
        opts[:note] = "   You can fix invalid values and append " + 
                      "to valid with: $ sycspector -fa"
      end

    end

  end

end
