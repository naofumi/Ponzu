# Ponzu

Ponzu is a information system for scientific conferences. Major features
are the incorporation of a "like" system, similar to Facebook, and
graphical representations of poster presentations.

Ponzu also incorporates the Kamishibai javascript libary. The Kamishibai
library is intended to allow websites to perform even during periods
of network instability.

You can find a more detailed (non-technical) description of features
at http://www.castle104.com/ponzu

Ponzu is implemented as a Rails Engine. This allows you to quickly
get the basic functionality of Ponzu and modify it to your specific
needs.

## How to use

Below is a brief description of the steps required to create a new
Ponzu-based Rails app.

An actual implmentation of a Ponzu-based Rails app is available
from the PonzuDemo repository https://bitbucket.org/castle104/ponzudemo .
The root commit of PonzuDemo is a freshly started Rails project 
(<code>rails new ponzu_demo</code>) so you can simply view the
diff to see what is needed to create your own.

The PonzuDemo repository is for the most part the same app as the
on running on http://ponzu-demo.castle104.com.

We suggest that you use the following steps only as a guideline and that you
examine the PonzuDemo repository for more detail.

1. Create a new Rails project.
   <code>rails new my_conference</code>
2. In the Gemfile, add the following line;
   <code>gem 'ponzu'</code>
3. Install gems via bundler
   <code>bundle install</code>
4. Prepare migrations
   <code>bundle exec rake ponzu_engine:install:migrations</code>
5. Run migrations
   <code>bundle exec rake db:migrate</code>
6. Run seed tasks to create the administrator account
   ----------
7. Customize the CSS
8. Add Javascript
   Ponzu transitions between pages using a scheme very similar to
   the turbolinks gem and the pjax gem. Any Javascript that doesn't
   work with these gems is highly unlikely to work out of the box.
9. Remove public/index.html
10. Remove app/views/layout/application.html.erb
11. Generate Indesign files.

## Configuration

1. Put the appropriate database connection parameters into database.yml
2. Add conference specific information into application.rb.
   We will stop doing this in the near future, and instead write
   a Conference object that will contain all the conference configuration 
   information.

## Adding models, controllers and views

1. All views files defined in the main applicaiton will take precedence
   over the files in the ponzu gem. To customize a view, we recommend that
   you copy a view file and modify the code. Ponzu uses HAML but you are
   free to use your own template engine.
2. All models, helpers, controllers can be modified by opening up and
   monkey patching them in the main application.
3. You can add to Ponzu routes by adding your routes to config/routes.rb

## Solr

1. sunspot-solr gem will automatically generate the Solr configuration files.
   We tweak the filters to allow NGram processing for CJK languages.
2. We currently use the sunspot-solr gem for production.

## Deployment guidelines

1. Git ignore auto generated pdfs and solr indexes