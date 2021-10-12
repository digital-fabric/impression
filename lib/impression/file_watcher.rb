# frozen_string_literal: true

require 'rb-inotify'

module Impression
  class FileWatcher
    def initialize(spec)
      @notifier = INotify::Notifier.new
      @buffer = []
      setup(spec)
    end

    def setup(spec)
      if File.file?(spec)
        setup_single_file(spec)
      elsif File.directory?(spec)
        setup_directory(spec)
      else
        dir = File.dir_name(spec)
        filename = File.basename(spec)
        if dir =~ /\/\*\*$/
          dir = File.dir_name(dir)
          filename = "**/#{filename}"
        end
        setup_directory(dir, filename)
      end
    end

    def setup_directory(dir)
      @notifier.watch(dir, :moved_to, :create, :move, :attrib, :modify, :delete) do |event|
        p [event.flags, event.name, event.absolute_name]
        kind = event.flags.first

        @buffer << [kind, event.absolute_name]
      end
    end

    def each(&block)
      @receiver = Fiber.current
      io = @notifier.to_io
      loop do
        io.wait_readable
        @notifier.process
        next if @buffer.empty?

        @buffer.each(&block)
        @buffer.clear
      end
    end
  end
end
