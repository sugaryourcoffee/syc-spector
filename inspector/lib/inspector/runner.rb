require_relative 'options'
require_relative 'separator'

# Module Inspector contains functions related to running the application
module Inspector
  # Processes based on the provided command line arguments the scan of the
  # file or shows the last processed files.
  class Runner

    # Initializes runner and invokes Options with the command line arguments
    # provided
    def initialize(argv)
      @options = Options.new(argv)
    end

    # Runs the Separator or shows the requested valid or invalid file. To show
    # the file 'less' is used.
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
