require 'test/unit'
require 'shoulda'
require_relative '../lib/inspector/separator'

# Tests the Separator class
class TestSeparator < Test::Unit::TestCase

  # Options used for invoking the Separator
  @options = {}

  context "Process" do
    
    # Initialize the @options
    def setup
      @options = {individualize: false, sort: false, fix: false, mode: 'w',
                 pattern: /\A\w+@\w+\.de\Z/, scan_pattern: /\w+@\w+\.de/, 
                 delimiter: ";", valid_file: "20130113_121212_valid_values", 
                 infile: "inputfile", 
                 invalid_file: "20130113_121212_invalid_values", show: :valid}
    end

    # Initilize the infile with provided values and separating the values with
    # the provided separator
    def initialize_infile(values = [], separator)
      File.open(@options[:infile], 'w') do |file|
        first = true
        values.each do |value|
          if first
            first = false
          else 
            file.puts separator
          end
          file.puts value
        end
      end
    end

    # Overrides some of the standard @optinons initialized in setup
    def initialize_options(opts={})
      opts.each do |key, value|
        @options[key] = value
      end
    end

    should "default processing" do
      initialize_infile ["pierre@thesugars.de", 
                         "amanda@thesugars.de and pierre@thesugars.de"], ";"
      sep = Inspector::Separator.new
      
      sep.process(@options)

      valid_result = ["pierre@thesugars.de"]

      File.open(@options[:valid_file]).each_line.with_index do |line, index|
        assert_equal valid_result[index], line.chomp
      end

      invalid_result = ["amanda@thesugars.de and pierre@thesugars.de"]

      File.open(@options[:invalid_file]).each_line.with_index do |line, index|
        assert_equal invalid_result[index], line.chomp
      end
    end

    should "individualize" do
      initialize_infile ["pierre@thesugars.de", "pierre@thesugars.de", 
                        "amanda@thesugars.de"], ";"
      initialize_options({individualize: true})

      sep = Inspector::Separator.new

      sep.process(@options)

      valid_result = ["pierre@thesugars.de", "amanda@thesugars.de"]

      File.open(@options[:valid_file]).each_line.with_index do |line, index|
        assert_equal valid_result[index], line.chomp
      end

      File.open(@options[:invalid_file]).each_line.with_index do |line, index|
        assert false
      end
    end

    should "sort" do
      content = ["pierre@thesugars.de", "david@thesugars.de",
                 "amanda@thesugars.de", "fabian@thesugars.de",
                 "rene@thesugars.de", "sarah@thesugars.de",
                 "jonah@thesugars.de"]
      initialize_infile content
      valid_result = content.sort

      sep = Inspector::Separator.new

      sep.process(@options)

      File.open(@options[:invalid_file]).each_line.with_index do |line, index|
        assert_equal valid_result[index], line.chomp
      end

    end

    should "show" do


    end

    should "fix" do

    end

    should "fix and append" do

    end

  end
end

