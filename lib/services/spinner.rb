module Commity
  module Spinner
    FRAMES = ["|", "/", "-", "\\"].freeze
    INTERVAL_SECONDS = 0.1

    def self.run(message)
      unless $stdout.tty?
        puts "#{message}..."
        result = yield
        puts "[done] #{message}"
        return result
      end

      done = false
      error = nil
      result = nil

      spinner_thread = Thread.new do
        index = 0
        until done
          frame = FRAMES[index % FRAMES.length]
          print "\r#{frame} #{message}"
          $stdout.flush
          index += 1
          sleep INTERVAL_SECONDS
        end
      end

      begin
        result = yield
      rescue StandardError => e
        error = e
      ensure
        done = true
        spinner_thread.join

        status = error.nil? ? "[done]" : "[fail]"
        print "\r#{status} #{message}\n"
        $stdout.flush
      end

      raise error unless error.nil?

      result
    end
  end
end
