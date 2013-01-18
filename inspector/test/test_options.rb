require 'test/unit'
require 'shoulda'
require_relative '../lib/inspector/options'
require_relative '../lib/inspector/pattern'

# Test of the Options class
class TestOptions < Test::Unit::TestCase

  context "specifying an inputfile that does not exist" do
    should "exit with -1" do
      begin
        opts = Inspector::Options.new(["inputfile"])
      rescue SystemExit => e
        assert e.status == -1
      end
    end
  end

  context "specifying no input file" do
    should "exit with -1" do
      begin
        opts = Inspector::Options.new([])
      rescue SystemExit => e
        assert e.status == 0
      end
    end
  end

  context "specifying an inputfile that exists" do
    
    # Intializes the input, valid, invalid and history file
    def setup
      File.open('existing', 'w') do |file|
        file.puts "pierre@thesugars.de"
        file.puts "amanda@thesugars.de und pierre@thesugars.de"
      end
      File.open('.sycspector.data', 'w') do |file|
        file.puts "20130113-121212_valid_values"
        file.puts "20130113-121212_invalid_values"
        file.puts "(?-mix:\\A[\\w!#\\$%&'*+\/=?`{|}~^-]+" +
                  "(?:\\.[\\w!#\\$%&'*+\/=?`{|}~^-]+)*@(?:[a-zA-Z0-9-]+\\.)+" +
                  "[a-zA-Z]{2,6}\\Z)"
        file.puts "(?-mix:[\\w!#\\$%&'*+\/=?`{|}~^-]+" +
                  "(?:\\.[\\w!#\\$%&'*+\/=?`{|}~^-]+)*@(?:[a-zA-Z0-9-]+\\.)+" +
                  "[a-zA-Z]{2,6})"
      end
      File.open('20130113-121212_valid_values', 'w') do |file|
        file.puts "pierre@thesugars.de"
        file.puts "amanda@thesugars.de"
        file.puts "pierre@thesugars.de"
      end
      File.open('20130113-121212_invalid_values', 'w') do |file|
        file.puts "amanda@thesugars und pierre@thesugars"
      end 
    end

    # Cleans up the test directory by deleting the files created in setup
    def teardown
      `rm existing`
      `rm 20130113-*`
      `rm .sycspector.data`
    end
 
    should "return inputfile and default pattern" do
      opts = Inspector::Options.new(["existing"])
      assert_equal "existing", opts.options[:infile]
      assert_equal DEFAULT_PATTERN, opts.options[:pattern]
      assert_equal DEFAULT_PATTERN, opts.options[:scan_pattern]
    end

    should "return email pattern" do
      opts = Inspector::Options.new(["-p", "email", "existing"])
      assert_equal EMAIL_PATTERN, opts.options[:pattern]
      assert_equal ANY_EMAIL_PATTERN, opts.options[:scan_pattern]
    end
    
    should "return pattern and scan pattern" do
      opts = Inspector::Options.new(["-p", "\\A\\w+.*\\d\\Z", "existing"])
      assert_equal /\A\w+.*\d\Z/, opts.options[:pattern]
      assert_equal /\w+.*\d/, opts.options[:scan_pattern]
    end

    should "return sort switch" do
      opts = Inspector::Options.new(["-s", "existing"])
      assert_equal true, opts.options[:sort]
    end

    should "return individualize switch" do
      opts = Inspector::Options.new(["-i", "existing"])
      assert_equal true, opts.options[:individualize]
    end

    should "return show :valid and infile nil" do
      opts = Inspector::Options.new(["--show"])
      assert_equal :valid, opts.options[:show]
      assert_equal nil, opts.options[:infile]
      opts = Inspector::Options.new(["--show", "valid"])
      assert_equal nil, opts.options[:infile]
    end

    should "return show :invalid and infile nil" do
      opts = Inspector::Options.new(["--show", "invalid"])
      assert_equal :invalid, opts.options[:show]
      assert_equal nil, opts.options[:infile]
    end

    should "return fix and invalid file as input file and pattern "+ 
           "from last invokation" do
      opts = Inspector::Options.new(["-f"])
      assert_equal true, opts.options[:fix]
      assert_equal "20130113-121212_invalid_values", opts.options[:infile]

      pattern_match = 
        "a@b.c".match(EMAIL_PATTERN).to_s == 
        "a@b.c".match(opts.options[:pattern]).to_s
      scan_pattern_match = 
        "is a@b.c here?".match(ANY_EMAIL_PATTERN).to_s == 
        "is a@b.c here?".match(opts.options[:scan_pattern]).to_s

      assert_equal true, pattern_match
      assert_equal true, scan_pattern_match
    end

    should "return fix and provided pattern and scan_pattern" do
      opts = Inspector::Options.new(["-f", "-p", "\\A\\w+@\\w+\\.\\w+\\Z"])
      assert_equal true, opts.options[:fix]
      assert_equal /\A\w+@\w+\.\w+\Z/, opts.options[:pattern]
      assert_equal /\w+@\w+\.\w+/, opts.options[:scan_pattern]
    end
  end

end
