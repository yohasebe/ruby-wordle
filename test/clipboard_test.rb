require_relative "test_helper"
require "tmpdir"

class ClipboardTest < Minitest::Test
  include TestHelper

  # Runs the system clipboard copy with PATH limited to fake commands.
  def copy(commands)
    Dir.mktmpdir do |dir|
      commands.each do |name, script|
        path = File.join(dir, name)
        File.write(path, "#!/bin/sh\n#{script.gsub('OUT', File.join(dir, 'copied'))}\n")
        File.chmod(0o755, path)
      end
      cli = RubyWordle::CLI.new(input: StringIO.new, output: StringIO.new, dictionary: small_dictionary, env: {})
      cli.define_singleton_method(:interactive_terminal?) { true }
      path = ENV["PATH"]
      begin
        ENV["PATH"] = dir
        result = cli.send(:copy_to_system_clipboard, "text\n")
      ensure
        ENV["PATH"] = path
      end
      copied = File.join(dir, "copied")
      [result, File.exist?(copied) ? File.read(copied) : nil]
    end
  end

  def test_first_available_command_is_used
    assert_equal [true, "text\n"], copy("pbcopy" => "/bin/cat > OUT", "xclip" => "exit 1")
  end

  def test_failing_command_falls_back_to_the_next
    assert_equal [true, "text\n"], copy("pbcopy" => "exit 1", "xsel" => "/bin/cat > OUT")
  end

  def test_no_command_available
    assert_equal [false, nil], copy({})
  end
end
