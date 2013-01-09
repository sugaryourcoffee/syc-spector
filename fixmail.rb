#!/usr/bin/env ruby

require 'optparse'
require 'io/wait'

require_relative 'pattern.rb'

timestamp = Time.now.strftime("%Y%m%d-%H%M%S")

options = {}
option_parser = OptionParser.new do |opts|
    opts.banner = "Usage: fixmail [ -fsi ] input_file [ options ]"

    # create a switch

    options[:individualize] = false
    opts.on("-i", "--individualize",
            "Removes duplicate entries") do
        options[:individualize] = true
    end

    options[:sort] = false
    opts.on("-s", "--sort",
            "Sort the entries") do
        options[:sort] = true
    end

    options[:fix] = false
    opts.on("-f", "--fix", 
            "Indicates that invalid emails to be prompted for fixing") do
        options[:fix] = true
    end
    
    # Create a flag
    options[:delimiter] = ";"
    opts.on("-d", "--delimiter DELIMITER [OPT]", String, 
            "Delimiter between email addresses, default ';'") do |delimiter|
        options[:delimiter] = delimiter || ";"
    end

    options[:valid_file] = timestamp + "_valid_emails"
    options[:invalid_file] = timestamp + "_invalid_emails"
    opts.on("-o", "--output OUTFILE", String,
            "File name as basis for creation of valid and invalid file name,",
            "default '<timestamp>_valid_emails, <timestamp>_invalid_emails'",
            "where <timestamp> = 'YYmmDD-HHMMSS'") do |outfile|
        if outfile =~ /\d{8}-\d{6}/
            puts "cp #{outfile} #{outfile.sub(/\d{8}-\d{6}/, timestamp)}"
            copy = `cp #{outfile} #{outfile.sub(/\d{8}-\d{6}/, timestamp)}`
            puts copy
            outfile.slice!(/\d{8}-\d{6}_(valid|invalid)_/)
            puts outfile
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

def print_statistics(valid_counter, invalid_counter, infile, valid_file_name, invalid_file_name, note = nil)
    puts "-> statistics"
    puts "   ----------"
    printf("%7s:   %4d\n%7s:   %4d\n%7s: %4d\n",
           "   total", valid_counter + invalid_counter,
           "   valid", valid_counter,
           "   invalid", invalid_counter)
    puts "-> files operated on"
    puts "   -----------------"
    puts "   emails read from:          #{infile}"
    puts "   valid emails written to:   #{valid_file_name}"
    puts "   invalid emails written to: #{invalid_file_name}"
    if note
        puts
        puts "-> Note"
        puts "   ----"
        puts note
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

def fix(email) 
    choice = email
    result = {}

    while not EMAIL_PATTERN.match(choice)
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
            break
        end
    end
    
    return result
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
                    when 'q'
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
                
def separate_emails(infile, delimiter, valid_file_name, invalid_file_name)
    valid_file = File.open(valid_file_name, 'w')
    valid_counter = 0

    invalid_file = File.open(invalid_file_name, 'w')
    invalid_counter = 0
    
    File.open(infile, 'r') do |file|
        while line = file.gets
            line.chomp.split("#{delimiter}").each do |email|
                emails = email.scan(ANY_EMAIL_PATTERN)
                if emails.empty?
                    invalid_file.puts email
                    invalid_counter += 1
                else
                    emails.each do |email|
                        valid_file.puts email
                        valid_counter += 1
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
                     invalid_file_name,
                     "   You can fix invalid emails and append to valid with:\n"+
                     "   $ fixmail -f #{invalid_file_name} -o #{valid_file_name}" 
end


if options[:fix]
    fix_emails options[:infile], 
               options[:delimiter], 
               options[:valid_file], 
               options[:invalid_file] 
else
    separate_emails options[:infile], 
                    options[:delimiter], 
                    options[:valid_file],
                    options[:invalid_file]
end
