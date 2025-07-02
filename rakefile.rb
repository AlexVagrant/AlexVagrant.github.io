require 'rake'
require 'yaml'

def ask(question, valid_options)
  print question + " "
  answer = STDIN.gets.chomp.downcase
  return answer if valid_options.include?(answer)
  abort("rake aborted!")
end

SOURCE = "."
CONFIG = {
  'posts' => File.join(SOURCE, "_posts"),
  'drafts' => File.join(SOURCE, "_drafts"),
  'post_ext' => "md",
}

# Usage: rake post title="A Title"
desc "Begin a new post in #{CONFIG['posts']}"
task :post do
  abort("rake aborted: '#{CONFIG['posts']}' directory not found.") unless FileTest.directory?(CONFIG['posts'])
  title = ENV["title"] || "new-post"
  slug = title.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
  filename = File.join(CONFIG['posts'], "#{Time.now.strftime('%Y-%m-%d')}-#{slug}.#{CONFIG['post_ext']}")
  if File.exist?(filename)
    abort("rake aborted!") if ask("#{filename} already exists. Do you want to overwrite?", ['y', 'n']) == 'n'
  end

  puts "Creating new post: #{filename}"

  open(filename, 'w') do |post|
    post.puts "---"
    post.puts "layout: post"
    post.puts 'title: "' + title.gsub(/-/,' ') + '"'
    # post.puts "subtitle: \"\""
    post.puts "date: #{Time.now.strftime('%Y-%m-%d')}"
    # post.puts "cover: "
    post.puts "category: "
    post.puts "tags: "
    post.puts "---"
  end
end # task :post

## 第二个命令
desc "Begin a new post in #{CONFIG['drafts']}"
task :draft do
  abort("rake aborted: '#{CONFIG['drafts']}' directory not found.") unless FileTest.directory?(CONFIG['drafts'])
  title = ENV["title"] || "new-post"
  slug = title.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
  filename = File.join(CONFIG['drafts'], "#{Time.now.strftime('%Y-%m-%d')}-#{slug}.#{CONFIG['post_ext']}")
  if File.exist?(filename)
    abort("rake aborted!") if ask("#{filename} already exists. Do you want to overwrite?", ['y', 'n']) == 'n'
  end

  puts "Creating new post: #{filename}"

  open(filename, 'w') do |post|
    post.puts "---"
    post.puts "layout: post"
    post.puts 'title: "' + title.gsub(/-/,' ') + '"'
    # post.puts "subtitle: \"\""
    post.puts "date: #{Time.now.strftime('%Y-%m-%d')}"
    # post.puts "cover: "
    post.puts "category: "
    post.puts "tags: "
    post.puts "---"
  end
end

#-- Tasks for starting the server and creating new posts

desc "Serve the site locally with livereload"
task :serve do
  puts "Starting Jekyll server..."
  system("bundle exec jekyll serve --livereload --port 4000")
end

task :start => :serve

desc "Create a new post with an interactive prompt"
task :new_post do
  print "Enter post title: "
  title = STDIN.gets.chomp
  
  if title.strip.empty?
    abort("rake aborted: title cannot be empty.")
  end

  slug = title.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
  filename = File.join(CONFIG['posts'], "#{Time.now.strftime('%Y-%m-%d')}-#{slug}.#{CONFIG['post_ext']}")

  if File.exist?(filename)
    print "#{filename} already exists. Overwrite? [y/n]: "
    overwrite = STDIN.gets.chomp.downcase
    abort("rake aborted!") unless overwrite == 'y'
  end

  puts "Creating new post: #{filename}"

  open(filename, 'w') do |post|
    post.puts "---"
    post.puts "layout: post"
    post.puts 'title: "' + title + '"'
    post.puts "date: #{Time.now.strftime('%Y-%m-%d %H:%M:%S %z')}"
    post.puts "category: "
    post.puts "tags: "
    post.puts "---"
  end
end
