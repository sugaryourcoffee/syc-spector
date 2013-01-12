#!/usr/bin/env ruby

require 'optparse'
require 'io/wait'

require_relative 'pattern.rb'

def get_file_from_history(type)
  pattern = Regexp.new('_'+type.to_s)
  File.open(".fixmail.files", 'r') do |file|
    while name = file.gets.chop
      return name unless name.scan(pattern).empty?
    end
  end
end

def create_output_files(filename)
  timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
  if filename =~ /\d{8}-\d{6}/
    `cp #{filename} #{filename.sub(/\d{8}-\d{6}/, timestamp)}`
    filename.slice!(/\d{8}-\d{6}_(valid|invalid)_/)
  end
  files = {valid_file: "#{timestamp}_valid_#{filename}",
           invalid_file: "#{timestamp}_invalid_#{filename}"}
end

options = {}
option_parser = OptionParser.new do |opts|
    opts.banner = "Usage: fixmail.rb input_file [ options ]"

    # create a switch

    options[:individualize] = false
    opts.on("-i", "--individualize",
            "Remove duplicate values") do
        options[:individualize] = true
    end

    options[:sort] = false
    opts.on("-s", "--sort",
            "Sort values") do
        options[:sort] = true
    end

    options[:fix] = false
    opts.on("-f", "--fix", 
            "prompt invalid values for fixing") do
        options[:fix] = true
    end

    options[:mode] = 'w'
    opts.on("-a", "--append",
            "Append values to output file OUTFILE") do
        options[:mode] = 'a'
    end
    
    # Create a flag

    options[:pattern] = /\A.*\Z/
    options[:scan_pattern] = /\A.*\Z/

    opts.on("-p", "--pattern PATTERN",
            "Values that match the pattern are",
            "considered as valid values.",
            "Default matches all.",
            "'fixmail.rb' -p email matches emails") do |pattern|
      if pattern == 'email'
        options[:pattern] = EMAIL_PATTERN
        options[:scan_pattern] = ANY_EMAIL_PATTERN
      else
        options[:pattern] = Regexp.new(pattern)
        options[:scan_pattern] = 
                          Regexp.new(pattern.match(FULL_LINE).to_s || pattern)
      end
    end
    
    options[:delimiter] = ";"
    opts.on("-d", "--delimiter DELIMITER", String, 
            "Delimiter between values.",
            "Default delimiter is ';'") do |delimiter|
        options[:delimiter] = delimiter || ";"
    end

    opts.on("-o", "--output OUTFILE", String,
            "File name as basis for creation of valid",
            "and invalid file name.",
            "default '<timestamp>_valid_values,",
            "<timestamp>_invalid_values'",
            "where <timestamp> = 'YYmmDD-HHMMSS'") do |outfile|

        files = create_output_files outfile
        options[:valid_file] = files[:valid_file]
        options[:invalid_file] = files[:invalid_file]
    end

    opts.on("--show [valid|invalid]", [:valid, :invalid],
            "Show the last valid or invalid file",
            "Default is valid") do |show|
      options[:show] = show || :valid
      
      unless File.exists?(".fixmail.files")
        STDERR.puts "--> no files saved yet"
        exit(0)
      end
      
    end
    
    opts.on("-h", "--help", "Show this message") do
        puts opts
        exit
    end

    begin
        ARGV << "-h" if ARGV.empty?
        opts.parse!(ARGV)
        
        if options[:fix] and ARGV.empty?

          files = {}
          if File.exist?(".fixmail.files")
            File.open(".fixmail.files", 'r') do |file|
              files = create_output_files file.gets.chomp            
              ARGV << file.gets.chomp
              options[:pattern] = Regexp.new(file.gets.chomp)
              options[:scan_pattern] = Regexp.new(file.gets.chomp)
            end
          else
            STDERR.puts "--> no fixmail history.\n" +
                        "    You first have to run fixmail.rb FILENAME"
            exit(-1)
          end

          unless files.empty?
            options[:valid_file] = files[:valid_file]
            options[:invalid_file] = files[:invalid_file]
          end
          
        end
        
       if options[:show] and ARGV.empty?
          unless File.exist?(".fixmail.files")
            STDERR.puts "--> no fixmail history." +
                        "    You first have to run 'fixmail.rb FILENAME'"
            exit(-1)
          end
          ARGV << (get_file_from_history options[:show])
        end

        options[:infile] = ARGV.shift
        
        if options[:infile].nil?
          STDERR.puts "--> missing input file"
          exit(-1)
        end

        unless File.exist?(options[:infile])
          STDERR.puts "--> infile '#{options[:infile]}' does not exist"
          exit(-1)
        end
        
        if options[:valid_file].nil? or options[:invalid_file].nil?
          files = create_output_files "values"
          options[:valid_file] = files[:valid_file]
          options[:invalid_file] = files[:invalid_file]
        end

    rescue OptionParser::ParseError => e
        STDERR.puts e.message, "\n", opts
        exit(-1)
    end
end

puts options.inspect

def save_result_files(opts)
  File.open(".fixmail.files", 'w') do |file|
    file.puts opts[:valid_file]
    file.puts opts[:invalid_file]
    file.puts opts[:pattern].to_s
    file.puts opts[:scan_pattern].to_s
  end
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

Signal.trap("INT") do
    puts "-> program terminated by user"
    exit
end

def char_if_pressed
    begin
        system("stty raw -echo")
        c = nil
        if $stdin.ready?
            c = $stdin.getc
        end
        c.chr if c
    ensure
        system "stty -raw echo"
    end
end

def prompt(choice_line)
    pattern = /(?<=\()./
    choices = choice_line.scan(pattern)

    choice = nil

    while choices.find_index(choice).nil?
        print choice_line 
        choice = nil
        choice = char_if_pressed while choice == nil
        puts
    end

    choice
end

def fix(value, pattern) 
    choice = value
    result = {}

    while not pattern.match(choice)
        puts "-> #{choice}?"
        result[:answer] = prompt "-> (v)alid (i)nvalid (d)rop (s)can (f)ix: "
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

def separate_values(opts) 
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
                  valid_values << value
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
                      "to valid with: $ fixmail.rb -fa"
    end

end

def show(options)
  pattern = Regexp.new('_'+options[:show].to_s)
      File.open(".fixmail.files", 'r') do |file|
        while name = file.gets
          unless name.scan(pattern).empty?
            system "less #{name}"
          end
        end
      end
end

if options[:infile]
  separate_values options 
  print_statistics options
  save_result_files options
end

if options[:show]
#  show options
  system "less #{get_file_from_history options[:show]}"
end
