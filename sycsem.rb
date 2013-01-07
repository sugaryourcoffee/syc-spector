#!/usr/bin/env ruby

require_relative 'pattern.rb'
#EMAIL_PATTERN = /\A[\w!#\$%&'*+\/=?`{|}~^-]+(?:\.[\w!#\$%&'*+\/=?`{|}~^-]+)*@(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,6}\Z/

inputfile = ARGV.shift
separator = ARGV.shift || ";"
outputfile = ARGV.shift || inputfile

timestamp = Time.now.strftime('%Y%m%d-%H%M%S_')

valid_file_name = timestamp + '_valid_' + outputfile.to_s

invalid_file_name = timestamp + '_invalid_' + outputfile.to_s

valid = []
invalid = []

valid_counter = 0
invalid_counter = 0

valid_file = File.open(valid_file_name, 'w')
invalid_file = File.open(invalid_file_name, 'w')

File.open(inputfile) do |file|
    while line = file.gets
        line.chomp.split("#{separator}").each do |email|
            if EMAIL_PATTERN.match(email.chomp)
                valid_file.puts email
                valid_counter += 1
                valid << email
            else
                invalid_file.puts email
                invalid_counter += 1
                invalid << email
            end
        end
    end
end

puts "# #{valid_counter + invalid_counter} entries found in #{inputfile}"
puts "# #{valid_counter} valid emails found and written to #{valid_file_name}"
puts "# #{invalid_counter} invalid emails found and written to #{invalid_file_name}"
puts "# You can review the invalid emails and append them to the #{valid_file_name} or another file using:"
puts "# ./sycfem.rb #{invalid_file_name} #{valid_file_name}"

valid_file.close
invalid_file.close

