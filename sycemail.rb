#!/usr/bin/env ruby

require 'optparse'
require_relative 'pattern.rb'

timestamp = Time.now.strftime("%Y%m%d-%H%M%S")

options = {}
option_parser = OptionParser.new do |opts|
    opts.banner = "Usage: fixmail [-f] input_file [ options ]"

    # create a switch

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
        puts "Note"
        puts "----"
        puts note
    end
end

def fix(email) 
    return email if EMAIL_PATTERN.match(email)
    puts "-> fix: #{email}"
    gets.chomp || email
end

def fix_emails(infile, delimiter, valid_file_name, invalid_file_name)
    valid_file = File.open(valid_file_name, 'a')
    valid_counter = 0

    invalid_file = File.open(invalid_file_name, 'w')
    invalid_counter = 0

    File.open(infile, 'r') do |file|
        while line = file.gets do
            line.chomp.split("#{delimiter}").each do |email|
                email = fix email
                if EMAIL_PATTERN.match(email)
                    valid_file.puts email
                    valid_counter += 1
                else
                    invalid_file.puts email
                    invalid_counter += 1
                    puts "-> invalid: #{email} - added to invalid emails"
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
                if EMAIL_PATTERN.match(email.chomp)
                    valid_file.puts email
                    valid_counter += 1
                else
                    invalid_file.puts email
                    invalid_counter += 1
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
                     "You can fix invalid emails and append to valid with:\n"+
                     "$ fixmail -f #{invalid_file_name} -o #{valid_file_name}" 
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
