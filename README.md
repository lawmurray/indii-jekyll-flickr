# Flickr Plugin for Jekyll Blogs

Use this plugin to embed Flickr photos in your Jekyll blog. You can:

* embed whole Flickr photosets (albums) as photo galleries in your posts and pages, and
* generate a post for each photo uploaded to your Flickr photostream.

This plugin was developed by Lawrence Murray for use on [indii.org](http://www.indii.org). All photo posts (e.g. [here](http://www.indii.org/archives/wadi-dana-21908020426/index.html)), photoset posts (e.g. [here](http://www.indii.org/archives/paris-stole-my-passport/index.html)) and the [photography](http://www.indii.org/photography) section of the website use the plugin extensively.

Please follow on:

  - [Flickr](http://www.flickr.com/photos/lawmurray)
  - [Facebook](http://www.facebook.com/indii.org)
  - [Twitter](http://www.twitter.com/lawmurray)
  - [Instagram](http://www.instagram.com/lawmurray)

## Getting started

It is assumed that you already have a working Jekyll blog set up and that you wish to add this plugin.

### Step 1

Obtain a Flickr API key and secret:

1. Go to <https://www.flickr.com/services/api/keys/> and log in with your Flickr account.
2. Click *Get Another Key* and follow the instructions.
3. Make a record of the *Key* and *Secret* that you are issued, as well as your *Screen name*. You will need these in Step 4.

### Step 2

Install [FlickRaw](http://hanklords.github.io/flickraw/):

    gem install flickraw
    
### Step 3

Install this plugin by copying the `indii-jekyll-flickr.rb` file into the `_plugins` directory of your Jekyll website.

### Step 4

Add the following to the `_config.yml` file of your Jekyll website, replacing the values with your Flickr screen name, and the Flickr API key and Flickr API secret issued to you, respectively:

    flickr:
      screen_name: You
      api_key: 039eb467bcfe412309bd0e09c2aa8f61
      api_secret: fe34a61c35c84fea3950bcf6eac

There are other options, but these are the essentials.

### Step 5

Rebuild your website:

    jekyll build
    
This should run without errors. Be patient, as it will take some time to download all of the meta data of your Flickr photos. In future you will be able to use the cache to speed up this process.

### Step 6 (optional)

To pretty things up, it is recommended that you install [Lightbox 2](http://lokeshdhakar.com/projects/lightbox2/). The plugin outputs HTML compatible with Lightbox 2.

## Basic usage

### To embed a whole Flickr photoset (album) as a photo gallery in a post or page

Use the tag:

    {% flickr_photoset "Landscape Photography" %}
    
Replace `Landscape Photography` with the name of the photoset (album).

### To generate a post for each photo uploaded to your Flickr photostream

Add, to the `flickr` section of your `_config.yml` file, the following options:

      generate_posts: true
      generate_photosets:
        - "Landscape Photography"
        - "Street Photography"

replacing `Landscape Photography` and `Street Photography` with the names of the photosets (albums) containing the photos that you wish to post. You can, of course, list just one photoset (album) or more than two. Photosets (albums) thus allow you to select a subset of your Flickr photos to post on your blog. This does mean that you need at least one photoset (album), though. You can add this through the Flickr website if you need to.

To add extra options to the YAML frontmatter of the generated posts, list them with this option:

      generate_frontmatter:
        layout: photo
        author: You
        
### Example configuration

The additions to your `_config.yml` file may look something like this:

    flickr:
      screen_name: You
      api_key: 039eb467bcfe412309bd0e09c2aa8f61
      api_secret: fe34a61c35c84fea3950bcf6eac

      generate_posts: true
      generate_photosets:
        - "Landscape Photography"
        - "Street Photography"
      generate_frontmatter:
        - layout: photo
        - author: You

## Advanced usage

### Using the cache

Pulling down all of the meta data on your Flickr photos each time you run Jekyll can be time consuming. After doing this once, it is recommended that you add the following option to the `flickr` section of your `_config.yml` file:

      use_cache: true

When you make any changes on Flickr, set `use_cache` to `false`, or comment out the line, and run `jekyll build` again to update the cache.

The cache is stored in a local directory, named `_flickr` by default. You can change this with the option:

      cache_dir: _flickr

### Changing photo sizes

You can set the full and thumbnail image sizes with the following options:

      size_full: Large
      size_thumb: "Large Square"
      
The above values are also the defaults. Click the *Download* link on an image on the Flickr website to see the list of sizes available.

### Changing the look

Thumbnail images and full images may be styled with CSS:

* Thumbnail images are output with `class="photo thumbnail"`.
* Full images are output with `class="photo full"`.

To change this or anything else about the HTML output, modify the `indii-jekyll-flickr.rb` file itself. Search for the `gen_thumb_html` and `gen_full_html` functions.

### A more advanced example configuration

After some of these extra options, the additions to your `_config.yml` file may look something like this:

    flickr:
      screen_name: You
      api_key: 039eb467bcfe412309bd0e09c2aa8f61
      api_secret: fe34a61c35c84fea3950bcf6eac

      generate_posts: true
      generate_photosets:
        - "Landscape Photography"
        - "Street Photography"
      generate_frontmatter:
        - layout: photo
        - author: You

      use_cache: true
      cache_dir: _flickr

      size_full: Original
      size_thumb: "Large Square"

## Frequently Asked Questions

### How do I just include one photo in a post or page?

You don't need a plugin for this. Just click the *Download* link for the image that you want on Flickr, copy the URL for the size that you want, and use a HTML `img` tag to include this in a post or page.
