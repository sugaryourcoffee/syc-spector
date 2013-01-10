#!/usr/bin/env ruby

require 'optparse'
require 'io/wait'

require_relative 'pattern.rb'

timestamp = Time.now.strftime("%Y%m%d-%H%M%S")

options = {}
option_parser = OptionParser.new do |opts|
    opts.banner = "Usage: fixmail.rb input_file [ options ]"

    # create a switch

    options[:individualize] = false
    opts.on("-i", "--individualize",
            "Removes duplicate entries") do
        options[:individualize] = true
    end

    options[:sort] = false
    opts.on("-s", "--sort",
            "Sort the values") do
        options[:sort] = true
    end

    options[:fix] = false
    opts.on("-f", "--fix", 
            "prompt invalid values for fixing") do
        options[:fix] = true
    end

    options[:mode] = 'w'
    opts.on("-a", "--append",
            "Appends the values to the output file") do
        options[:mode] = 'a'
    end
    
    # Create a flag

    options[:pattern] = /.*/
    opts.on("-p", "--pattern PATTERN", 
            "Values that match the patterns are considered ",
            "as valid values. Default pattern matches all values",
            "Predifined pattern 'email' matches emails") do |pattern|
        if pattern == 'email'
            options[:pattern] = ANY_EMAIL_PATTERN
        else
            options[:pattern] = Regexp.new(pattern)
        end
    end
    
    options[:delimiter] = ";"
    opts.on("-d", "--delimiter DELIMITER", String, 
            "Delimiter between email addresses, default ';'") do |delimiter|
        options[:delimiter] = delimiter || ";"
    end

    options[:valid_file] = timestamp + "_valid_values"
    options[:invalid_file] = timestamp + "_invalid_values"
    opts.on("-o", "--output OUTFILE", String,
            "File name as basis for creation of valid and invalid file name,",
            "default '<timestamp>_valid_values, <timestamp>_invalid_values'",
            "where <timestamp> = 'YYmmDD-HHMMSS'") do |outfile|
        if outfile =~ /\d{8}-\d{6}/
            copy = `cp #{outfile} #{outfile.sub(/\d{8}-\d{6}/, timestamp)}`
            outfile.slice!(/\d{8}-\d{6}_(valid|invalid)_/)
        end
        options[:valid_file] = timestamp + "_valid_" + outfile
        options[:invalid_file] = timestamp + "_invalid_" + outfile
    end
    
    opts.on("-h", "--help", "Show this message") do
        puts opts
        exit
    end

    begin
        ARGV << "-h" if ARGV.empty?
        opts.parse!(ARGV)
        
        if ARGV.empty?
            STDERR.puts "missing input file \n", opts
            exit(-1)
        end

        options[:infile] = ARGV.shift

    rescue OptionParser::ParseError => e
        STDERR.puts e.message, "\n", opts
        exit(-1)
    end
end

puts options.inspect

def print_statistics(opts) #valid_counter, invalid_counter, infile, valid_file_name, invalid_file_name, note = nil)
    puts "-> statistics"
    puts "   ----------"
    printf("%7s:   %4d\n%7s:   %4d\n%7s: %4d\n%7s:    %4d\n%7s:  %4d\n",
           "   total", opts[:valid_counter] + 
                       opts[:invalid_counter] +
                       opts[:skip_counter] +
                       opts[:double_counter],
           "   valid", opts[:valid_counter],
           "   invalid", opts[:invalid_counter],
           "   skip", opts[:skip_counter],
           "   double", opts[:double_counter])
    puts
    puts "-> pattern: #{opts[:pattern].inspect}"
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
        result[:answer] = prompt "-> (v)alid (i)nvalid (f)ix (s)kip: "
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
                emails = email.scan(opts[:pattern])
                if emails.empty? and opts[:fix]
                    result = fix email, opts[:pattern] 
                    case result[:answer]
                    when 'v'
                       valid_values << result[:value]
                    when 'i'
                       invalid_values << result[:value]
                    when 's'
                       skip_counter += 1
                    end
                elsif emails.empty?
                    invalid_values << email
                else
                    emails.each do |email|
                        valid_values << email
                    end
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
    if (not opts[:fix])
        opts[:note] = "   You can fix invalid values and append " + 
                      "to valid with:\n"+
                      "   $ fixmail -f #{opts[:invalid_file]} " +
                      "-o #{opts[:valid_file]}" 
    end

end

separate_emails options 
print_statistics options
