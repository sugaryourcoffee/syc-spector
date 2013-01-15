require_relative 'console'

# This module encapsulates functionality related to scanning values for
# patterns. If a line contains the pattern that line is added to valid files.
# If the pattern is not found in the line the line is added to invalid files.
# Lines can if requested to be fixed. The line is presented to the user and the
# user can eather fix the value by typing the corrected value. Other
# possibilities are to drop the line, scan the line or just considering the
# line as valid so it is added to valid values.
module Inspector

  # The Separator scans the input file for a provided pattern and prints the
  # results of the scan to the console.
  class Separator
    # The prompt string is presented to the user when values are requested to
    # be fixed. (v)alid will add the value to the valid values without testing
    # against the pattern. (i)nvalid adds the value to the invalid values.
    # (d)rop discards the value, (s)can scans the line to look for the pattern.
    # (f)ix allows to type the corrected value.
    PROMPT_STRING =  "-> (v)alid (i)nvalid (d)rop (s)can (f)ix: " 

    # Initializes the Separator and creating a Console object
    def initialize
      @console = Console.new
    end

    # Prints the results of the invokation of Separator.process
    #
    # :call-seq:
    #   print_statistics(opts)
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

    # Prompts the PROMPT_STRING and tests the value against the pattern
    #
    # :call-seq:
    #   fix(value, pattern) -> hash
    #
    # Return a hash with :value and :answer where :value contains the fixed
    # value and the answer. To test whether the value is valid or invalid the
    # :answer has to checked first.
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

    # Processes the scan of the lines of the file and add the values eather to
    # the valid or invalid values. The result of the scan will be added to the
    # opts.
    #
    # :call-seq:
    #   process(opts)
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
