require 'nokogiri'
require 'open-uri'
require 'csv'

html_url = "http://www.theawl.com"
xml_url = "http://www.theawl.com/feed"
rss_url = "http://feeds2.feedburner.com/TheAwl"

class Page
  attr_reader :posts
  def initialize(url)
    @doc = Nokogiri::HTML(open(url))
    @posts = []
    self.make_posts
  end

  def make_posts
    @doc.search("div.reverse-chron__post").each do |post|
      if !post.css("div.post__body div p:first img:first").empty? && !post.css('h2 a').empty?
        this_post = Post.new(post)
        @posts << this_post
      end
    end
  end
end

class Post
  attr_reader :image_src, :image_alt, :post_url
  def initialize(post)
    post_image = post.css("div.post__body div p:first img:first")
    begin
    @image_src = post_image.attr("src")&.value
    @image_alt = post_image.attr("alt")&.value
    @post_url = post.css('h2 a').attr('href')&.value
    rescue
      @image_src = ""
      @image_alt = ""
      @post_url = ""
    end
  end
end

base_url = "http://www.theawl.com/page/"

all_posts = []

# 2707 is last page as of today
total_number_of_pages_to_scrape = 2705
time_to_sleep_between_page_scrapes = 2

20.times do |i|
  i = i + 1
  this_page_url = base_url + i.to_s
  
  this_page = Page.new(this_page_url)
  all_posts = all_posts + this_page.posts

  puts "Have scraped #{i} pages so far."
  sleep time_to_sleep_between_page_scrapes
end

with_src = 0
with_alt = 0
with_post_url = 0

all_posts.each do |post|
  with_src = with_src +1 if post.image_src
  with_alt = with_alt +1 if post.image_alt
  with_post_url = with_post_url +1 if post.post_url
end

puts "total number of post: #{all_posts.size}"
puts "total number of posts with src: #{with_src}"
puts "total number of posts with alt: #{with_alt}"
puts "total number of posts with post url: #{with_post_url}"

CSV.open("csv/archive1.csv", "w") do |csv|
  all_posts.each do |post|
    csv << [post.post_url, post.image_src, post.image_alt]
  end
end


CSV.open("csv/just_with_alt.csv", "w") do |csv|
  all_posts.each do |post|
    if post.image_alt && post.image_alt != "" && post.image_alt != '""'
      csv << [post.post_url, post.image_src, post.image_alt]
    end
  end
end
