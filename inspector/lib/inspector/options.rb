require 'optparse'
require 'io/wait'

require_relative 'pattern.rb'

# Module Inspector contains the functions related to the command line parsing.
# Provides the parsed user input in the options hash.
module Inspector

  # Parses the provided command line flags, switches and arguments
  class Options
    # Options hold all the parameters used by the application
    attr_reader :options

    # Initializes Options and parses the provided user input from the command
    # line
    def initialize(argv)
      parse(argv)
    end

    # After running the application output files are saved in the history.
    # --get_file_from_history-- retrieves the valid or invalid file from the
    # last application invokation. Where type is eather +valid+ or +invalid+.
    #
    # :call-seq:
    #   get_file_from_history(type)
    def get_file_from_history(type)
      pattern = Regexp.new('_'+type.to_s)
      File.open(".sycspector.data", 'r') do |file|
        while name = file.gets.chop
          return name unless name.scan(pattern).empty?
        end
      end
    end

    # Save the results of the last run of the application to +.sycspector.data+.
    # It contains the valid and invalid file as well as the pattern.
    def save_result_files(opts)
      File.open(".sycspector.data", 'w') do |file|
        file.puts opts[:valid_file]
        file.puts opts[:invalid_file]
        file.puts opts[:pattern].to_s
        file.puts opts[:scan_pattern].to_s
      end
    end

  private

    # Creates the output files valid and invalid files based on the input file's
    # name. If the filename already exists it is copied with a new timestamp.
    # 
    # :call-seq:
    #   create_output_files(filename)
    def create_output_files(filename)
      timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
      if filename =~ /\d{8}-\d{6}/
        `cp #{filename} #{filename.sub(/\d{8}-\d{6}/, timestamp)}`
        filename.slice!(/\d{8}-\d{6}_(valid|invalid)_/)
      end
      files = {valid_file: "#{timestamp}_valid_#{filename}",
               invalid_file: "#{timestamp}_invalid_#{filename}"}
    end
 
    # Parses the provided arguments and stores the value in @options
    #
    # :call-seq:
    #   parse(argv)
    def parse(argv)
      @options = {}
      OptionParser.new do |opts|
        opts.banner = "Usage: sycspector input_file [ options ]"

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

        opts.on("-p", "--pattern PATTERN",
                "Values that match the pattern are",
                "considered as valid values.",
                "Default matches all.",
                "'sycspector' -p email matches emails") do |pattern|
          if pattern == 'email'
            @options[:pattern] = EMAIL_PATTERN
            @options[:scan_pattern] = ANY_EMAIL_PATTERN
          else
            @options[:pattern] = Regexp.new(pattern)
            scan_pattern = pattern.match(FULL_LINE).to_s
            puts "'#{scan_pattern}' '#{pattern}'"
            pattern = scan_pattern unless scan_pattern.empty?
            @options[:scan_pattern] = Regexp.new(pattern)
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
          if File.exist?(".sycspector.data")
            File.open(".sycspector.data", 'r') do |file|
              files = create_output_files file.gets.chomp            
              argv << file.gets.chomp
              unless @options[:pattern]
                @options[:pattern] = Regexp.new(file.gets.chomp)
                @options[:scan_pattern] = Regexp.new(file.gets.chomp)
              end
            end
          else
            STDERR.puts "--> no sycspector history.\n" +
                        "    You first have to run sycspector FILENAME"
            exit(-1)
          end

          unless files.empty?
            @options[:valid_file] = files[:valid_file]
            @options[:invalid_file] = files[:invalid_file]
          end
          
        end
        
        if @options[:show] and argv.empty?
          unless File.exist?(".sycspector.data")
            STDERR.puts "--> no sycspector history." +
                        "    You first have to run 'sycspector FILENAME'"
            exit(-1)
          end
        else
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

          unless @options[:pattern]
            @options[:pattern] = DEFAULT_PATTERN
            @options[:scan_pattern] = DEFAULT_PATTERN
          end
        end
      end
    end
  end
end
