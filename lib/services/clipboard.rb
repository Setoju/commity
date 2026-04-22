module Commity
  module Clipboard
    def self.copy(text)
      case platform
      when :mac
        IO.popen("pbcopy", "w") { |io| io.write(text) }
        true
      when :linux
        if command_exists?("xclip")
          IO.popen("xclip -selection clipboard", "w") { |io| io.write(text) }
          true
        elsif command_exists?("xsel")
          IO.popen("xsel --clipboard --input", "w") { |io| io.write(text) }
          true
        else
          false # no clipboard tool found
        end
      when :windows
        IO.popen("clip", "w") { |io| io.write(text) }
        true
      else
        false
      end
    end

    def self.platform
      if RUBY_PLATFORM.include?("darwin")
        :mac
      elsif RUBY_PLATFORM.include?("linux")
        :linux
      elsif RUBY_PLATFORM.include?("mingw") || RUBY_PLATFORM.include?("mswin")
        :windows
      else
        :unknown
      end
    end

    def self.command_exists?(cmd)
      system("which", cmd, out: File::NULL, err: File::NULL)
    end
  end
end