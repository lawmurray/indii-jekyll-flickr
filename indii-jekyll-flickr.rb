##
## Embed Flickr photos in a Jekyll blog.
##
## Copyright (C) 2015 Lawrence Murray, www.indii.org.
##
## This program is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by the Free
## Software Foundation; either version 2 of the License, or (at your option)
## any later version.
##
require 'flickraw'
require 'shellwords'

module Jekyll
    
def self.flickr_setup(site)
    # defaults
    if !site.config['flickr']['cache_dir']
        site.config['flickr']['cache_dir'] = '_flickr'
    end
    if !site.config['flickr']['size_full']
        site.config['flickr']['size_full'] = 'Large'
    end
    if !site.config['flickr']['size_thumb']
        site.config['flickr']['size_thumb'] = 'Large Square'
    end

    if not site.config['flickr']['use_cache']
        # clear any existing cache
        cache_dir = site.config['flickr']['cache_dir']

        if Dir.exists?(cache_dir)
            FileUtils.rm_rf(cache_dir)
        end
        if !Dir.exists?(cache_dir)
            Dir.mkdir(cache_dir)
        end

        # populate cache from Flickr
        FlickRaw.api_key = site.config['flickr']['api_key']
        FlickRaw.shared_secret = site.config['flickr']['api_secret']

        nsid = flickr.people.findByUsername(:username => site.config['flickr']['screen_name']).id
        flickr_photosets = flickr.photosets.getList(:user_id => nsid)

        flickr_photosets.each do |flickr_photoset|
            photoset = Photoset.new(site, flickr_photoset)
        end
    end
end

class Photoset
    attr_accessor :id, :title, :slug, :cache_dir, :cache_file, :photos
    
    def initialize(site, photoset)
        self.photos = Array.new
        if photoset.is_a? String
            self.cache_load(site, photoset)
        else
            self.flickr_load(site, photoset)
        end
        self.photos.sort! {|left, right| left.position <=> right.position}
    end
    
    def flickr_load(site, flickr_photoset)
        self.id = flickr_photoset.id
        self.title = flickr_photoset.title
        self.slug = self.title.downcase.gsub(/ /, '-').gsub(/[^a-z\-]/, '')
        self.cache_dir = File.join(site.config['flickr']['cache_dir'], self.slug)
        self.cache_file = File.join(site.config['flickr']['cache_dir'], "#{self.slug}.yml")
        
        # write to cache
        self.cache_store
        
        # create cache directory
        if !Dir.exists?(self.cache_dir)
            Dir.mkdir(self.cache_dir)
        end
        
        # photos
        flickr_photos = flickr.photosets.getPhotos(:photoset_id => self.id).photo
        flickr_photos.each_with_index do |flickr_photo, pos|
            self.photos << Photo.new(site, self, flickr_photo, pos)
        end
    end
    
    def cache_load(site, file)
        cached = YAML::load(File.read(file))
        self.id = cached['id']
        self.title = cached['title']
        self.slug = cached['slug']
        self.cache_dir = cached['cache_dir']
        self.cache_file = cached['cache_file']
        
        file_photos = Dir.glob(File.join(self.cache_dir, '*.yml'))
        file_photos.each_with_index do |file_photo, pos|
            self.photos << Photo.new(site, self, file_photo, pos)
        end
    end
    
    def cache_store
        cached = Hash.new
        cached['id'] = self.id
        cached['title'] = self.title
        cached['slug'] = self.slug
        cached['cache_dir'] = self.cache_dir
        cached['cache_file'] = self.cache_file
        
        File.open(self.cache_file, 'w') {|f| f.print(YAML::dump(cached))}
    end
    
    def gen_html
        content = ''
        self.photos.each do |photo|
            content += photo.gen_thumb_html
        end
        return content
    end
end

class Photo
    attr_accessor :id, :title, :slug, :date, :description, :tags, :url_full, :url_thumb, :cache_file, :position
    
    def initialize(site, photoset, photo, pos)
        if photo.is_a? String
            self.cache_load(photo)
        else
            self.flickr_load(site, photoset, photo, pos)
        end
    end
    
    def flickr_load(site, photoset, flickr_photo, pos)
        # init
        self.id = flickr_photo.id
        self.title = flickr_photo.title
        self.slug = self.title.downcase.gsub(/ /, '-').gsub(/[^a-z\-]/, '') + '-' + self.id
        self.date = ''
        self.description = ''
        self.tags = Array.new
        self.url_full = ''
        self.url_thumb = ''
        self.cache_file = File.join(photoset.cache_dir, "#{self.id}.yml")
        self.position = pos
        
        # sizes request
        flickr_sizes = flickr.photos.getSizes(:photo_id => self.id)
        if flickr_sizes
            size_full = flickr_sizes.find {|s| s.label == site.config['flickr']['size_full']}
            if size_full
                self.url_full = size_full.source
            end
            
            size_thumb = flickr_sizes.find {|s| s.label == site.config['flickr']['size_thumb']}
            if size_thumb
                self.url_thumb = size_thumb.source
            end
        end
        
        # other info request
        flickr_info = flickr.photos.getInfo(:photo_id => self.id)
        if flickr_info
            self.date = DateTime.strptime(flickr_info.dates.posted, '%s').to_s
            self.description = flickr_info.description
            flickr_info.tags.each do |tag|
                self.tags << tag.raw
            end
        end
        
        cache_store
    end
    
    def cache_load(file)
        cached = YAML::load(File.read(file))
        self.id = cached['id']
        self.title = cached['title']
        self.slug = cached['slug']
        self.date = cached['date']
        self.description = cached['description']
        self.tags = cached['tags']
        self.url_full = cached['url_full']
        self.url_thumb = cached['url_thumb']
        self.cache_file = cached['cache_file']
        self.position = cached['position']
    end
    
    def cache_store
        cached = Hash.new
        cached['id'] = self.id
        cached['title'] = self.title
        cached['slug'] = self.slug
        cached['date'] = self.date
        cached['description'] = self.description
        cached['tags'] = self.tags
        cached['url_full'] = self.url_full
        cached['url_thumb'] = self.url_thumb
        cached['cache_file'] = self.cache_file
        cached['position'] = self.position
        
        File.open(self.cache_file, 'w') {|f| f.print(YAML::dump(cached))}
    end
    
    def gen_thumb_html
        content = ''
        if self.url_full and self.url_thumb
            content = "<a href=\"#{self.url_full}\" data-lightbox=\"photoset\"><img src=\"#{self.url_thumb}\" alt=\"#{self.title}\" title=\"#{self.title}\" class=\"photo thumbnail\" width=\"75\" height=\"75\" /></a>\n"
        end
        return content
    end
    
    def gen_full_html
        content = ''
        if self.url_full and self.url_thumb
            content = "<p><a href=\"#{self.url_full}\" data-lightbox=\"photoset\"><img src=\"#{self.url_full}\" alt=\"#{self.title}\" title=\"#{self.title}\" class=\"photo full\" /></a></p>\n<p>#{self.description}</p>\n"
            if self.tags
                content += "<p>Tagged <i>" + self.tags.join(", ") + ".</i></p>\n"
            end
        end
        return content
    end
end

class PhotoPost < Post
    def initialize(site, base, dir, photo)
        name = photo.date[0..9] + '-photo-' + photo.slug + '.md'

        data = Hash.new
        data['title'] = photo.title
        data['shorttitle'] = photo.title
        data['description'] = photo.description
        data['date'] = photo.date
        data['slug'] = photo.slug
        data['permalink'] = File.join('/archives', photo.slug, 'index.html')
        data['flickr'] = Hash.new
        data['flickr']['id'] = photo.id
        data['flickr']['url_full'] = photo.url_full
        data['flickr']['url_thumb'] = photo.url_thumb
        
        if site.config['flickr']['generate_frontmatter']
            site.config['flickr']['generate_frontmatter'].each do |key, value|
                data[key] = value
            end
        end
        
        File.open(File.join('_posts', name), 'w') {|f|
            f.print(YAML::dump(data))
            f.print("---\n\n")
            f.print(photo.gen_full_html)
        }

        super(site, base, dir, name)
    end
end

class FlickrPageGenerator < Generator
    safe true
    
    def generate(site)
        Jekyll::flickr_setup(site)
        cache_dir = site.config['flickr']['cache_dir']
        
        file_photosets = Dir.glob(File.join(cache_dir, '*.yml'))
        file_photosets.each_with_index do |file_photoset, pos|
            photoset = Photoset.new(site, file_photoset)
            if site.config['flickr']['generate_photosets'].include? photoset.title
                # generate photo pages if requested
                if site.config['flickr']['generate_posts']
                    file_photos = Dir.glob(File.join(photoset.cache_dir, '*.yml'))
                    file_photos.each do |file_photo, pos|
                        photo = Photo.new(site, photoset, file_photo, pos)
                        page_photo = PhotoPost.new(site, site.source, '', photo)

                        # posts need to be in a _posts directory, but this means Jekyll has already
                        # read in photo posts from any previous run... so for each photo, update
                        # its associated post if it already exists, otherwise create a new post
                        site.posts.each_with_index do |post, pos|
                            if post.data['slug'] == photo.slug
                                site.posts.delete_at(pos)
                            end
                        end
                        site.posts << page_photo
                    end
                end
            end
        end
        
        # re-sort posts by date
        site.posts.sort! {|left, right| left.date <=> right.date}
    end
end

class FlickrPhotosetTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
        super
        params = Shellwords.shellwords markup
        title = params[0]
        @slug = title.downcase.gsub(/ /, '-').gsub(/[^a-z\-]/, '')
    end
    
    def render(context)
        site = context.registers[:site]
        Jekyll::flickr_setup(site)
        file_photoset = File.join(site.config['flickr']['cache_dir'], "#{@slug}.yml")
        photoset = Photoset.new(site, file_photoset)
        return photoset.gen_html
    end
end

end

Liquid::Template.register_tag('flickr_photoset', Jekyll::FlickrPhotosetTag)

