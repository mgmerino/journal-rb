# Journal 🍹

A minimal static site generator that converts Markdown posts to HTML. Built with Ruby, it features a clean interface with tag filtering, theme switching, and a random post navigator.

## How It Works

This publishing system follows a simple pipeline:

```
Markdown files (content/) → Ruby build script → Static HTML (public/)
```

### Build Process

The build script (`build.rb`) orchestrates the entire publishing workflow:

1. **Load and Parse Posts**
   - Scans `content/posts/*.md` for Markdown files
   - Extracts YAML front matter (title, date, tags, slug)
   - Converts Markdown to HTML using Kramdown
   - Calculates word counts and sorts posts by date

2. **Generate Tag System**
   - Collects all unique tags from posts
   - Assigns consistent colors to each tag
   - Creates filterable tag lists for the "All Posts" page

3. **Build Pages**
   - **Individual posts** (`/posts/{slug}/`): Full article with tags and metadata
   - **Recent** (`/` and `/recent/`): Homepage showing the 10 most recent posts
   - **All posts** (`/all/`): Sortable, filterable list with word counts
   - **About** (`/about/`): Static page from `content/about.md`

4. **Copy Assets**
   - Copies CSS from templates to public directory
   - Copies images from `content/img/` to `public/img/`

5. **Generate Feeds**
   - Creates `posts.json` for random post navigation
   - Generates `feed.xml` (Atom feed) for RSS readers with the 20 most recent posts

### Template System

Templates use simple placeholder substitution:

- `layout.html`: Main wrapper with navigation, header, footer
- `entry.html`: Single post layout
- `recent-entry.html`: Post format for homepage
- `all-item.html`: List item for "All Posts" page
- Placeholders like `{{content}}`, `{{title}}`, `{{body}}` are replaced with actual content

### File Structure

```
journal/
├── build.rb              # Main build script
├── dev.rb                # Development mode (CSS file watcher)
├── new_post.rb           # Create new post from template
├── Gemfile               # Ruby dependencies (kramdown)
├── content/              # Source content
│   ├── posts/            # Markdown posts with YAML front matter
│   ├── img/              # Images referenced in posts
│   └── about.md          # About page content
├── templates/            # HTML templates and CSS
│   ├── layout.html       # Main page wrapper
│   ├── entry.html        # Single post template
│   ├── recent-entry.html # Recent posts template
│   ├── all.html          # All posts page template
│   ├── all-item.html     # All posts list item template
│   └── style.css         # Site styles
└── public/               # Generated static site (output)
    ├── index.html
    ├── style.css
    ├── posts.json
    ├── feed.xml          # Atom feed for RSS readers
    ├── posts/{slug}/
    ├── recent/
    ├── all/
    ├── about/
    └── img/
```

## Usage

### Prerequisites

Install Ruby and dependencies:

```bash
bundle install
```

### Create a New Post

```bash
ruby new_post.rb "Your Post Title"
```

This creates a new file in `content/posts/` with:
- Auto-generated filename: `YYYY-MM-DD-slugified-title.md`
- YAML front matter template
- Current date

Edit the generated file to add your content.

### Post Format

Posts use YAML front matter followed by Markdown:

```markdown
---
title: "My Post Title"
date: 2025-11-18
tags: [ruby, markdown, static-site]
slug: "my-post-title"
---

Write your content here using **Markdown** syntax.

## Headings work

- Lists too
- Second item

[Links](https://example.com) and images are supported.
```

### Build the Site

Generate the static site:

```bash
ruby build.rb
```

This processes all content and outputs to the `public/` directory.

### Development Mode

Watch CSS files for changes and auto-copy to public:

```bash
ruby dev.rb
```

Useful when styling the site. Watches `templates/style.css` and copies changes to `public/style.css` automatically.

### Serve the Site

Use any static file server to preview:

```bash
# Python
python -m http.server --directory public 8000

# Ruby
ruby -run -ehttpd public -p8000

# Node.js (if you have http-server installed)
npx http-server public -p 8000
```

Then visit `http://localhost:8000`

## Features

- **RSS/Atom feed**: Subscribe to updates via `/feed.xml` (Atom 1.0 format)
- **Tag filtering**: Click tags to filter posts on the "All Posts" page
- **Theme switcher**: Light/dark mode toggle with localStorage persistence
- **Random post**: Navigate to a random post from the nav
- **Responsive design**: Works on mobile and desktop
- **Word counts**: See reading time estimates
- **Time ago**: Human-readable relative dates ("3 days ago")
- **Feed autodiscovery**: RSS readers automatically detect the feed from any page

## Technical Details

- **Markdown parser**: Kramdown
- **No JavaScript framework**: Vanilla JS for theme toggle and filtering
- **No build complexity**: Single Ruby script, no webpack/npm required
- **Clean URLs**: Posts at `/posts/{slug}/` with `index.html` files
- **Static assets**: All images and CSS copied to public directory

## Deployment

Deploy the `public/` directory to any static hosting service:

- GitHub Pages
- Netlify
- Vercel
- Cloudflare Pages
- Any web server serving static files

The entire site is pre-rendered HTML/CSS with minimal JavaScript.

