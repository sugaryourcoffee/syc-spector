#!/usr/bin/env ruby

require 'optparse'
require 'io/wait'

require_relative 'pattern.rb'

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
            "Append values to output file") do
        options[:mode] = 'a'
    end
    
    # Create a flag

    options[:pattern] = /\A.*\Z/
    options[:scan_pattern] = /\A.*\Z/

    opts.on("-m", "--match PATTERN",
            "Values that match the pattern are",
            "considered as valid values",
            "Default matches all.",
            "'fixmail.rb' -m email matches emails") do |pattern|

      if pattern == 'email'
        options[:pattern] = EMAIL_PATTERN
        options[:scan_pattern] = ANY_EMAIL_PATTERN
      else
        options[:pattern] = Regexp.new(pattern)
      end
    end

    opts.on("-p", "--part PATTERN",
            "The part pattern is especially used in",
            "the fix (-f) mode. This is usefull in",
            "case the match (-m)pattern matches only",
            "whole lines (example: \A\w.*\d\Z) and the",
            "input file contains lines that has in one",
            "line two or more valid values. Than in fix",
            "mode these values can be scanned") do |pattern|
        if pattern == 'email'
            options[:pattern] = EMAIL_PATTERN
            options[:scan_pattern] = ANY_EMAIL_PATTERN
        else
            options[:scan_pattern] = Regexp.new(pattern)
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
        puts "--> no files saved yet - exiting"
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
          File.open(".fixmail.files", 'r') do |file|
            files = create_output_files file.gets.chomp            
            ARGV << file.gets.chomp
            options[:pattern] = Regexp.new(file.gets.chomp)
            options[:scan_pattern] = Regexp.new(file.gets.chomp)
          end

          unless files.empty?
            options[:valid_file] = files[:valid_file]
            options[:invalid_file] = files[:invalid_file]
          end
          
        end

        options[:infile] = ARGV.shift
        
        if options[:infile].nil? and options[:show].nil? 
          STDERR.puts "missing input file \n", opts
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
    puts "   emails read from:          #{opts[:infile]}"
    puts "   valid emails written to:   #{opts[:valid_file]}"
    puts "   invalid emails written to: #{opts[:invalid_file]}"
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

def fix(email, pattern) 
    choice = email
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
            result[:value] = email
            break
        when 's'
            result[:value] = email
            break
        end
    end
    
    return result
end

def add_value_if_not_present(valid_values, value)
    valid_values << value unless valid_values.find_index value
end

def fix_values(opts, value)
    if (opts[:fix])
    end
end

def fix_emails(infile, delimiter, valid_file_name, invalid_file_name)
    valid_file = File.open(valid_file_name, 'a')
    valid_counter = 0

    invalid_file = File.open(invalid_file_name, 'w')
    invalid_counter = 0

    skip_counter = 0

    File.open(infile, 'r') do |file|
        while line = file.gets do
            line.chomp.split("#{delimiter}").each do |email|
                if EMAIL_PATTERN.match(email)
                    valid_file.puts email
                    valid_counter += 1
                else
                    result = fix email
                    case result[:answer]
                    when 'v'
                       valid_counter += 1
                       valid_file.puts result[:value]
                    when 'i'
                       invalid_counter += 1
                       invalid_file.puts result[:value]
                    when 's'
                       skip_counter += 1
                       break 
                    end
                end
            end
        end
    end
    valid_file.close
    invalid_file.close
    print_statistics valid_counter, 
                     invalid_counter,
                     infile,
                     valid_file_name,
                     invalid_file_name
end
                
def separate_emails(opts) 
    valid_file = File.open(opts[:valid_file], opts[:mode])
    valid_values = []

    invalid_file = File.open(opts[:invalid_file], 'w')
    invalid_values = []
    
    skip_counter = 0

    File.open(opts[:infile], 'r') do |file|
        while line = file.gets
            line.chomp.split(opts[:delimiter]).each do |email|
                
                match = email.match(opts[:pattern])
                if match.nil? 
                  if opts[:fix]
                    result = fix email, opts[:pattern] 
                    case result[:answer]
                    when 'v'
                       valid_values << result[:value]
                    when 'i'
                       invalid_values << result[:value]
                    when 'd'
                       skip_counter += 1
                    when 's'
                      email.scan(opts[:scan_pattern]).each do |value|
                        valid_values << value
                      end
                    end
                  else
                    invalid_values << email
                  end
                else
                  valid_values << email
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
  separate_emails options 
  print_statistics options
  save_result_files options
end

if options[:show]
  show options
end
