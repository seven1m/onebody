has\_one\_photo
===============

Uber simple Rails plugin giving a model a single attached photo per record.
When a photo is saved to the model, sized photo files are placed in the specified path,
based on the indicated sizes (see below).

*Note:* Only JPEG images are supported at this time.

Requirements
------------

* ImageMagick
* MiniMagick (*not* RMagick)

Install
-------

    script/plugin install git://github.com/seven1m/has_one_photo.git

Setup
-----

In the model:

    class Person < ActiveRecord::Base
      PHOTO_SIZES = {
        :tn => '32x32',
        :small => '75x75',
        :medium => '150x150',
        :large => '400x400'
      }
      has_one_photo :path => Rails.root + 'db/photos/people', :sizes => PHOTO_SIZES
    end

In your controller(s), you need an action that calls `send_photo(obj)`,
with "obj" being an instance of the record with the photo.

There are several ways to do this, the simplest of which may be:

    class PeopleController < ApplicationController
      # url looks like "/people/1/photo" and "/people/1/photo?size=small"
      def photo
        @person = Person.find params[:id]
        send_photo @person
      end
    end

You'll also need a member action in your routes.rb:

    map.resources :people, :member => {:photo => :get}
    
Prettier URLs
-------------

For an example of using a singular resource "Photo" for several
resources, check out the OneBody project:

* [routes.rb](http://github.com/seven1m/onebody/tree/master/config/routes.rb)
* [photos\_controller.rb](http://github.com/seven1m/onebody/tree/master/app/controllers/photos_controller.rb)

Usage
-----

    person.photo = file_like_object # form submission, File.open, etc.
    # or
    person.photo = 'http://example.com/tim.jpg'

    person.rotate_photo('-90') # degrees

    person.has_photo?
    # => true

    person.photo_path
    # => 'db/photos/123.jpg'

    person.photo = nil # deletes the photo file(s)