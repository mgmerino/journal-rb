#!/usr/bin/env ruby
# dev.rb - Development mode with file watching

require "fileutils"

ROOT = File.dirname(__FILE__)
TEMPLATES_DIR = File.join(ROOT, "templates")
PUBLIC_DIR = File.join(ROOT, "public")
CSS_SRC = File.join(TEMPLATES_DIR, "style.css")
CSS_DST = File.join(PUBLIC_DIR, "style.css")

def copy_css
  FileUtils.cp(CSS_SRC, CSS_DST)
  puts "[#{Time.now.strftime("%H:%M:%S")}] ✓ CSS updated: #{CSS_DST}"
end

def watch_css
  puts "🔍 Watching for CSS changes..."
  puts "   Source: #{CSS_SRC}"
  puts "   Destination: #{CSS_DST}"
  puts ""
  puts ""

  last_mtime = nil

  loop do
    if File.exist?(CSS_SRC)
      mtime = File.mtime(CSS_SRC)
      
      if last_mtime.nil?
        # First run
        copy_css
        last_mtime = mtime
      elsif mtime > last_mtime
        # File changed
        copy_css
        last_mtime = mtime
      end
    else
      puts "Warning: CSS file not found at #{CSS_SRC}"
    end

    sleep 0.5
  end
end

# --- Main ---

puts "🚀 Dev mode started"
puts ""

begin
  watch_css
rescue Interrupt
  puts ""
  puts ""
  puts "👋 Dev mode stopped"
  exit 0
end

