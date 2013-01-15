require 'test/unit'
require 'shoulda'
require_relative '../lib/inspector/console'

# Tests the Console class
class TestConsole < Test::Unit::TestCase

  context "console" do
    should "return value from prompt string" do
      console = Inspector::Console.new
      result = console.prompt "(v)alid, (i)nvalid, (d)rop, (s)can, (f)ix: "
      choices = %w(v i d s f)
      assert choices.index(result) >= 0
    end

    should "exit with code 0" do
      console = Inspector::Console.new
      begin
        result = console.prompt "No choices are available. To end press Ctrl-c:"
      rescue SystemExit => e
        assert e.status == 0
      end
    end
  end

end
