#!/usr/bin/env ruby

require_relative 'pattern.rb'

input_file_name = ARGV.shift
output_file_name = ARGV.shift

output_file = File.open(output_file_name, 'a')

total_counter = 0
append_counter = 0

File.open(input_file_name, 'r') do |file|
    while line = file.gets
        puts line
        email = gets.chomp

        next if email.empty? 
        
        if EMAIL_PATTERN.match(email)
            output_file.puts email
            puts "# Appending #{email} to valid emails"
        else
            puts "# #{email} is no valid email address - not appended to valid emails"
        end
    end
end

output_file.close
