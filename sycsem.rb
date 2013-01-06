#!/usr/bin/env ruby

EMAIL_PATTERN = /\A[\w!#\$%&'*+\/=?`{|}~^-]+(?:\.[\w!#\$%&'*+\/=?`{|}~^-]+)*@(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,6}\Z/

inputfile = ARGV.shift
separator = ARGV.shift

timestamp = Time.now.strftime('%Y%m%d-%H%M%S_')

valid_file_name = timestamp + inputfile.to_s

invalid_file_name = timestamp + inputfile.to_s

puts valid_file_name, invalid_file_name

valid = []
invalid = []

File.open(inputfile) do |file|
    while line = file.gets
        line.chomp.split("#{separator}").each do |email|
            puts "'#{email}'"
            if EMAIL_PATTERN.match(email.chomp)
                valid << email
            else
                invalid << email
            end
        end
        #addresses << line.chomp.split("#{separator}")
    end
end

puts valid
puts "----"
puts invalid

ls = `ls -l`

puts inputfile
puts separator

puts ls
