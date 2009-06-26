require "#{File.dirname(__FILE__)}/captured/file_tracker"
require "#{File.dirname(__FILE__)}/captured/file_uploader"

class Captured
  def self.config_file
    "#{ENV['HOME']}/.captured.yml" 
  end

  def self.guess_watch_path
    if `sw_vers | awk '/ProductVersion:/ {print $2}'`.strip.start_with? "10.5"
      "Picture**.png"
    else
      "Screenshot**.png"
    end
  rescue => e
    puts e
    "Screenshot**.png"
  end

  def self.run_once!(options)
    watch_path = options[:watch_path] || "#{ENV['HOME']}/Desktop/"
    Dir["#{watch_path}#{options[:watch_pattern]}"].each do |file|
      if (File.mtime(file).to_i > (Time.now.to_i-10))
        puts "#{file} is new"
        FileUploader.upload(file, options)
      end
    end
  end

  def self.run_and_watch!(options)
    require 'captured/fs_events'
    watch_path = options[:watch_path] || "#{ENV['HOME']}/Desktop/"
    tracker = FileTracker.new(options)
    tracker.scan([desktop_dir], :existing)
    e = FSEvents.new(watch_path)
    e.run do |paths|
      tracker.scan paths, :pending
      tracker.each_pending do |file|
        FileUploader.upload(file, options)
        tracker.mark_processed(file)
      end
    end
  end
end
