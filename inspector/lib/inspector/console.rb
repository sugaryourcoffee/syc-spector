require 'io/wait'

module Inspector
  
  class Console
    
    Signal.trap("INT") do
      puts "-> program terminated by user"
      exit
    end

    def char_if_pressed
      begin
        system("stty raw -echo")
        c = nil
        if $stdin.ready?
            c = $stdin.getc
        end
        c.chr if c
      ensure
        system "stty -raw echo"
      end
    end

    def prompt(choice_line)
      pattern = /(?<=\()./
      choices = choice_line.scan(pattern)

      choice = nil

      while choices.find_index(choice).nil?
        print choice_line 
        choice = nil
        choice = char_if_pressed while choice == nil
        sleep 0.1
        puts
      end

      choice
    end

  end

end
