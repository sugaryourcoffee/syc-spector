require 'optparse'
require 'io/wait'

require_relative 'pattern.rb'

module Inspector

  class Options
    attr_reader :options

    def initialize(argv)
      parse(argv)
    end

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

  private

    def parse(argv)
      @options = {}
      OptionParser.new do |opts|
        opts.banner = "Usage: fixmail.rb input_file [ @options ]"

        # create a switch

        @options[:individualize] = false
        opts.on("-i", "--individualize",
                "Remove duplicate values") do
            @options[:individualize] = true
        end

        @options[:sort] = false
        opts.on("-s", "--sort",
                "Sort values") do
            @options[:sort] = true
        end

        @options[:fix] = false
        opts.on("-f", "--fix", 
                "prompt invalid values for fixing") do
            @options[:fix] = true
        end

        @options[:mode] = 'w'
        opts.on("-a", "--append",
                "Append values to output file OUTFILE") do
            @options[:mode] = 'a'
        end
        
        # Create a flag

        @options[:pattern] = /\A.*\Z/
        @options[:scan_pattern] = /\A.*\Z/

        opts.on("-p", "--pattern PATTERN",
                "Values that match the pattern are",
                "considered as valid values.",
                "Default matches all.",
                "'fixmail.rb' -p email matches emails") do |pattern|
          if pattern == 'email'
            @options[:pattern] = EMAIL_PATTERN
            @options[:scan_pattern] = ANY_EMAIL_PATTERN
          else
            @options[:pattern] = Regexp.new(pattern)
            @options[:scan_pattern] = 
              Regexp.new(pattern.match(FULL_LINE).to_s || pattern)
          end
        end
        
        @options[:delimiter] = ";"
        opts.on("-d", "--delimiter DELIMITER", String, 
                "Delimiter between values.",
                "Default delimiter is ';'") do |delimiter|
            @options[:delimiter] = delimiter || ";"
        end

        opts.on("-o", "--output OUTFILE", String,
                "File name as basis for creation of valid",
                "and invalid file name.",
                "default '<timestamp>_valid_values,",
                "<timestamp>_invalid_values'",
                "where <timestamp> = 'YYmmDD-HHMMSS'") do |outfile|

            files = create_output_files outfile
            @options[:valid_file] = files[:valid_file]
            @options[:invalid_file] = files[:invalid_file]
        end

        opts.on("--show [valid|invalid]", [:valid, :invalid],
                "Show the last valid or invalid file",
                "Default is valid") do |show|
          @options[:show] = show || :valid
          
          unless File.exists?(".fixmail.files")
            STDERR.puts "--> no files saved yet"
            exit(0)
          end
          
        end
        
        opts.on("-h", "--help", "Show this message") do
            puts opts
            exit(0)
        end

        begin
            argv << "-h" if argv.empty?
            opts.parse!(argv)
            
        rescue OptionParser::ParseError => e
            STDERR.puts e.message, "\n", opts
            exit(-1)
        end
        
        if @options[:fix] and argv.empty?

          files = {}
          if File.exist?(".fixmail.files")
            File.open(".fixmail.files", 'r') do |file|
              files = create_output_files file.gets.chomp            
              argv << file.gets.chomp
              @options[:pattern] = Regexp.new(file.gets.chomp)
              @options[:scan_pattern] = Regexp.new(file.gets.chomp)
            end
          else
            STDERR.puts "--> no fixmail history.\n" +
                        "    You first have to run fixmail.rb FILENAME"
            exit(-1)
          end

          unless files.empty?
            @options[:valid_file] = files[:valid_file]
            @options[:invalid_file] = files[:invalid_file]
          end
          
        end
        
        if @options[:show] and argv.empty?
          unless File.exist?(".fixmail.files")
            STDERR.puts "--> no fixmail history." +
                        "    You first have to run 'fixmail.rb FILENAME'"
            exit(-1)
          end
          argv << (get_file_from_history @options[:show])
        end

        @options[:infile] = argv.shift
        
        if @options[:infile].nil?
          STDERR.puts "--> missing input file"
          exit(-1)
        end

        unless File.exist?(@options[:infile])
          STDERR.puts "--> infile '#{@options[:infile]}' does not exist"
          exit(-1)
        end
        
        if @options[:valid_file].nil? or @options[:invalid_file].nil?
          files = create_output_files "values"
          @options[:valid_file] = files[:valid_file]
          @options[:invalid_file] = files[:invalid_file]
        end

      end
    end
  end
end
