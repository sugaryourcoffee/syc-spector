require 'test/unit'
require 'shoulda'
require_relative '../lib/inspector/options'
require_relative '../lib/inspector/pattern'

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
    
    def setup
      puts "in startup"
      File.open('existing', 'w') do |file|
        file.puts "pierre@thesugars.de"
        file.puts "amanda@thesugars.de und pierre@thesugars.de"
      end
      File.open('.fixmail.files', 'w') do |file|
        file.puts "20130113-121212_valid_values"
        file.puts "20130113-121212_invalid_values"
        file.puts "(?-mix:\A[\w!#\$%&'*+\/=?`{|}~^-]+" +
                  "(?:\.[\w!#\$%&'*+\/=?`{|}~^-]+)*@(?:[a-zA-Z0-9-]+\.)+" +
                  "[a-zA-Z]{2,6}\Z)"
        file.puts "(?-mix:[\w!#\$%&'*+\/=?`{|}~^-]+" +
                  "(?:\.[\w!#\$%&'*+\/=?`{|}~^-]+)*@(?:[a-zA-Z0-9-]+\.)+" +
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

    def teardown
      puts "in shutdown"
      `rm existing`
      `rm 20130113-*`
      `rm .fixmail.files`
    end
 
    should "return inputfile" do
      opts = Inspector::Options.new(["existing"])
      assert_equal "existing", opts.options[:infile]
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

    should "return show and valid file as input file from history" do
      opts = Inspector::Options.new(["--show"])
      assert_equal :valid, opts.options[:show]
      assert_equal "20130113-121212_valid_values", opts.options[:infile]
      opts = Inspector::Options.new(["--show", "valid"])
      assert_equal "20130113-121212_valid_values", opts.options[:infile]
    end

    should "return show and invalid file as input file from history" do
      opts = Inspector::Options.new(["--show", "invalid"])
      assert_equal :invalid, opts.options[:show]
      assert_equal "20130113-121212_invalid_values", opts.options[:infile]
    end

    should "return fix and valid file as input file from last invokation" do
      opts = Inspector::Options.new(["-f"])
      assert_equal true, opts.options[:fix]
      assert_equal "20130113-121212_invalid_values", opts.options[:infile]
    end

  end

end
