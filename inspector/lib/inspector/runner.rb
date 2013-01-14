require_relative 'options'
require_relative 'separator'

module Inspector
  class Runner

    def initialize(argv)
      @options = Options.new(argv)
    end

    def run
      opts = @options.options
      if opts[:infile]
        separator = Separator.new
        separator.process(opts)
        separator.print_statistics(opts)
        @options.save_result_files opts
      end
      if show = opts[:show]
        system "less #{@options.get_file_from_history show}"
      end
    end
  end
end 
