#!/usr/bin/env ruby
# new_post.rb - Create a new journal entry from a template

require "date"
require "fileutils"

ROOT = File.dirname(__FILE__)
POSTS_DIR = File.join(ROOT, "content", "posts")

def slugify(text)
  text.downcase
      .gsub(/[^\w\s-]/, '')
      .gsub(/[\s_]+/, '-')
      .gsub(/^-+|-+$/, '')
end

def create_post(title)
  date = Date.today
  slug = slugify(title)
  filename = "#{date}-#{slug}.md"
  filepath = File.join(POSTS_DIR, filename)

  if File.exist?(filepath)
    puts "Error: Post already exists at #{filepath}"
    exit 1
  end

  template = <<~MARKDOWN
    ---
    title: "#{title}"
    date: #{date}
    tags: []
    slug: "#{slug}"
    ---

    Write your content here...
  MARKDOWN

  FileUtils.mkdir_p(POSTS_DIR)
  File.write(filepath, template)

  puts "✓ Created new post: #{filename}"
  puts "  Path: #{filepath}"
  puts ""
  puts "Open it with: $EDITOR #{filepath}"
  
  filepath
end

# --- Main ---

if ARGV.empty?
  puts "Usage: ruby new_post.rb \"Your Post Title\""
  puts ""
  puts "Example:"
  puts "  ruby new_post.rb \"My First Journal Entry\""
  exit 1
end

title = ARGV.join(" ")
create_post(title)

