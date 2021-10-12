# frozen_string_literal: true

require 'rb-inotify'

module Impression
  class FileWatcher
    def initialize(spec)
      @notifier = INotify::Notifier.new
      setup(spec)
      start_io_fiber
    end

    def start_io_fiber
      @io_fiber = spin do
        io = @notifier.to_io
        loop do
          io.wait_readable
          @notifier.process
        end
      end
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

        @receiver << [kind, event.absolute_name] if @receiver
        # path = event.absolute_name
        # if File.file?(path)
        #   notifier.watch(path, :modify, :delete_self) { |e| handle_changed_file(path) }
        # end
        # handle_changed_file(path)
      end
    end

    def each
      @receiver = Fiber.current
      while (entry = receive)
        yield(entry)
      end
    end
  end
end
