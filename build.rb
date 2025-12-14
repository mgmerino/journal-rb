#!/usr/bin/env ruby
# build.rb

require "fileutils"
require "yaml"
require "date"
require "json"
require "kramdown"

ROOT = File.dirname(__FILE__)
CONTENT_DIR = File.join(ROOT, "content")
POSTS_DIR   = File.join(CONTENT_DIR, "posts")
TEMPLATES_DIR = File.join(ROOT, "templates")
PUBLIC_DIR  = File.join(ROOT, "public")

FileUtils.mkdir_p(PUBLIC_DIR)

def read_markdown_with_front_matter(path)
  raw = File.read(path)

  if raw.start_with?("---\n")
    _sep, rest = raw.split("---\n", 2)
    front_matter_text, body = rest.split("\n---\n", 2)
    meta = YAML.safe_load(front_matter_text, permitted_classes: [Date], aliases: true) || {}
    [meta, body || ""]
  else
    [{}, raw]
  end
end

def render_markdown(markdown)
  Kramdown::Document.new(markdown).to_html
end

def render_layout(content_html, title: nil, path_from_root: "")
  layout = File.read(File.join(TEMPLATES_DIR, "layout.html"))

  css_path = path_from_root + "style.css"
  layout = layout.sub("{{css_path}}", "#{css_path}")

  if title
    layout = layout.sub("<title>Journal</title>", "<title>#{title} – Journal</title>")
  end

  layout.sub("{{content}}", content_html)
end

def count_words(text)
  text.gsub(/[^\w\s]/, " ").split.size
end

def time_ago(date)
  now = Date.today
  days_diff = (now - date).to_i
  
  return "today" if days_diff == 0
  return "yesterday" if days_diff == 1
  return "#{days_diff} days ago" if days_diff < 30
  
  months_diff = (days_diff / 30.0).round
  return "#{months_diff} month ago" if months_diff == 1
  return "#{months_diff} months ago" if months_diff < 12
  
  years_diff = (days_diff / 365.0).round
  return "#{years_diff} year ago" if years_diff == 1
  "#{years_diff} years ago"
end

def load_posts
  posts = []

  Dir[File.join(POSTS_DIR, "*.md")].each do |path|
    meta, body_md = read_markdown_with_front_matter(path)

    status = meta["status"] || "draft"
    next unless status == "published"

    date = meta["date"].is_a?(Date) ? meta["date"] : Date.parse(meta["date"].to_s)
    slug = meta["slug"] || File.basename(path, ".md")
    title = meta["title"] || slug
    tags = meta["tags"] || []

    body_html = render_markdown(body_md)
    word_count = count_words(body_md)

    posts << {
      "title" => title,
      "date" => date,
      "tags" => tags,
      "slug" => slug,
      "body_html" => body_html,
      "word_count" => word_count
    }
  end

  posts.sort_by { |p| p["date"] }.reverse
end

def collect_all_tags(posts)
  posts.flat_map { |p| p["tags"] }.uniq.sort
end

def generate_tag_colors(tags)
  colors = [
    "#ea00ff", # magenta
    "#ff0808", # red
    "#009e00", # green
    "#094fff", # blue
    "#ffdb0c", # yellow
    "#ff6b00", # orange
    "#00d4ff", # cyan
    "#9d00ff", # purple
    "#ff0066", # pink
    "#00ff88", # teal
    "#76ff57", # lime
    "#ff57ff", # fuchsia
    "#57ffff", # aqua
    "#ff5757", # coral
    "#5757ff", # indigo
  ]
  
  tag_colors = {}
  tags.each_with_index do |tag, index|
    tag_colors[tag] = colors[index % colors.length]
  end
  tag_colors
end

def render_tags(tags, tag_colors = {})
  return "" if tags.empty?

  tags_html = tags.map do |t|
    color = tag_colors[t] || "#666"
    "<span class=\"tag\" style=\"background-color: #{color}\">#{t}</span>"
  end.join(" ")
  "<span class=\"tags\">#{tags_html}</span>"
end

def build_post_pages(posts, tag_colors)
  entry_template = File.read(File.join(TEMPLATES_DIR, "entry.html"))
  
  posts.each do |post|
    out_dir = File.join(PUBLIC_DIR, "posts", post["slug"])
    FileUtils.mkdir_p(out_dir)

    article_html = entry_template
      .sub("{{title}}", post["title"])
      .sub("{{body}}", post["body_html"])
      .sub("{{date}}", post["date"].strftime("%B %d, %Y"))
      .sub("{{date_ago}}", time_ago(post["date"]))
      .sub("{{tags}}", render_tags(post["tags"], tag_colors))

    full_html = render_layout(article_html, title: post["title"], path_from_root: "../../")
    File.write(File.join(out_dir, "index.html"), full_html)
  end
end

def build_about_page
  about_path = File.join(CONTENT_DIR, "about.md")
  return unless File.exist?(about_path)

  meta, body_md = read_markdown_with_front_matter(about_path)
  body_html = render_markdown(body_md)
  title = meta["title"] || "About"

  out_dir = File.join(PUBLIC_DIR, "about")
  FileUtils.mkdir_p(out_dir)

  content_html = <<~HTML
    <section id="about">
      <h2>#{title}</h2>
      #{body_html}
    </section>
  HTML

  full_html = render_layout(content_html, title: title, path_from_root: "../")
  File.write(File.join(out_dir, "index.html"), full_html)
end

def build_all_page(posts, tag_colors)
  all_template = File.read(File.join(TEMPLATES_DIR, "all.html"))
  item_template = File.read(File.join(TEMPLATES_DIR, "all-item.html"))
  
  # Generate tag options for filter dropdown
  all_tags = collect_all_tags(posts)
  tag_options = all_tags.map do |tag|
    "<option value=\"#{tag}\">#{tag}</option>"
  end.join("\n        ")
  
  all_items_html = posts.map do |p|
    tags_plain = p["tags"].join(", ")
    item_template
      .gsub("{{slug}}", p["slug"])
      .gsub("{{title}}", p["title"])
      .gsub("{{date}}", p["date"].strftime("%Y-%m-%d"))
      .gsub("{{word_count}}", p["word_count"].to_s)
      .gsub("{{tags}}", render_tags(p["tags"], tag_colors))
      .gsub("{{tags_plain}}", tags_plain)
  end.join("\n")

  content_html = all_template
    .sub("{{items}}", all_items_html)
    .sub("{{tag_options}}", tag_options)

  out_dir = File.join(PUBLIC_DIR, "all")
  FileUtils.mkdir_p(out_dir)

  full_html = render_layout(content_html, title: "All posts", path_from_root: "../")
  File.write(File.join(out_dir, "index.html"), full_html)
end

def copy_css_file
  css_src = File.join(TEMPLATES_DIR, "style.css")
  css_dst = File.join(PUBLIC_DIR, "style.css")
  FileUtils.cp(css_src, css_dst) if File.exist?(css_src)
  
  puts "Copied CSS file to #{css_dst}"
end

def copy_fonts
  fonts_src_dir = File.join(ROOT, "assets", "fonts")
  fonts_dst_dir = File.join(PUBLIC_DIR, "fonts")
  
  return unless Dir.exist?(fonts_src_dir)
  
  FileUtils.mkdir_p(fonts_dst_dir)
  
  # Copy all font files from assets/fonts to public/fonts
  Dir[File.join(fonts_src_dir, "*")].each do |src_file|
    next unless File.file?(src_file)
    
    dst_file = File.join(fonts_dst_dir, File.basename(src_file))
    FileUtils.cp(src_file, dst_file)
  end
  
  file_count = Dir[File.join(fonts_src_dir, "*")].select { |f| File.file?(f) }.size
  puts "Copied #{file_count} font(s) to #{fonts_dst_dir}"
end

def copy_images
  img_src_dir = File.join(CONTENT_DIR, "img")
  img_dst_dir = File.join(PUBLIC_DIR, "img")
  
  return unless Dir.exist?(img_src_dir)
  
  FileUtils.mkdir_p(img_dst_dir)
  
  # Copy all files from content/img to public/img
  Dir[File.join(img_src_dir, "*")].each do |src_file|
    next unless File.file?(src_file)
    
    dst_file = File.join(img_dst_dir, File.basename(src_file))
    FileUtils.cp(src_file, dst_file)
  end
  
  file_count = Dir[File.join(img_src_dir, "*")].select { |f| File.file?(f) }.size
  puts "Copied #{file_count} image(s) to #{img_dst_dir}"
end

def build_recent_page(posts, tag_colors)
  recent_template = File.read(File.join(TEMPLATES_DIR, "recent.html"))
  entry_template = File.read(File.join(TEMPLATES_DIR, "recent-entry.html"))
  
  recent_posts = posts.first(10)

  recent_html = recent_posts.map do |p|
    entry_template
      .sub("{{slug}}", p["slug"])
      .sub("{{title}}", p["title"])
      .sub("{{body}}", p["body_html"])
      .sub("{{date}}", p["date"].strftime("%B %d, %Y"))
      .sub("{{tags}}", render_tags(p["tags"], tag_colors))
  end.join("\n")

  content_html = recent_template.sub("{{entries}}", recent_html)

  # home: /
  index_html = render_layout(content_html, title: "Home", path_from_root: "")
  File.write(File.join(PUBLIC_DIR, "index.html"), index_html)

  # /recent/
  recent_dir = File.join(PUBLIC_DIR, "recent")
  FileUtils.mkdir_p(recent_dir)
  recent_page_html = render_layout(content_html, title: "Recent", path_from_root: "../")
  File.write(File.join(recent_dir, "index.html"), recent_page_html)
end

def build_posts_json(posts)
  data = posts.map do |p|
    {
      "title" => p["title"],
      "url"   => "/posts/#{p["slug"]}/"
    }
  end

  File.write(File.join(PUBLIC_DIR, "posts.json"), JSON.pretty_generate(data))
end

def escape_xml(text)
  text.to_s
    .gsub("&", "&amp;")
    .gsub("<", "&lt;")
    .gsub(">", "&gt;")
    .gsub("\"", "&quot;")
    .gsub("'", "&apos;")
end

def build_atom_feed(posts)
  # Configuration
  site_url = "https://journal.hal9.xyz"
  site_title = "Journal"
  site_author = "Manuel González"
  
  # Get the most recent update date
  updated = posts.first ? posts.first["date"].iso8601 : Date.today.iso8601
  
  # Limit to 20 most recent posts
  feed_posts = posts.first(20)
  
  feed_xml = <<~XML
    <?xml version="1.0" encoding="utf-8"?>
    <feed xmlns="http://www.w3.org/2005/Atom">
      <title>#{escape_xml(site_title)}</title>
      <link href="#{site_url}/feed.xml" rel="self" />
      <link href="#{site_url}/" />
      <updated>#{updated}</updated>
      <id>#{site_url}/</id>
      <author>
        <name>#{escape_xml(site_author)}</name>
      </author>
  XML
  
  feed_posts.each do |post|
    post_url = "#{site_url}/posts/#{post["slug"]}/"
    post_date = post["date"].iso8601
    post_updated = post["updated"]&.iso8601 || post_date
    
    # Create a summary from the HTML content (first paragraph or truncate)
    summary = post["body_html"].gsub(/<[^>]*>/, " ").gsub(/\s+/, " ").strip[0..200]
    summary += "..." if summary.length >= 200
    
    feed_xml << <<~ENTRY
      
        <entry>
          <title>#{escape_xml(post["title"])}</title>
          <link href="#{post_url}" />
          <id>#{post_url}</id>
          <published>#{post_date}</published>
          <updated>#{post_updated}</updated>
          <summary>#{escape_xml(summary)}</summary>
          <content type="html">#{escape_xml(post["body_html"])}</content>
        </entry>
    ENTRY
  end
  
  feed_xml << "\n</feed>\n"
  
  File.write(File.join(PUBLIC_DIR, "feed.xml"), feed_xml)
  puts "Generated Atom feed with #{feed_posts.size} posts."
end

def publish
  posts = load_posts
  all_tags = collect_all_tags(posts)
  tag_colors = generate_tag_colors(all_tags)
  
  build_post_pages(posts, tag_colors)
  build_about_page
  build_all_page(posts, tag_colors)
  build_recent_page(posts, tag_colors)
  build_posts_json(posts)
  build_atom_feed(posts)
  copy_css_file
  copy_fonts
  copy_images

  puts "🍹Generated #{posts.size} posts with #{all_tags.size} unique tags."
end

publish