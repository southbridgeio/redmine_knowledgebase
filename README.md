# Redmine Knowledgebase Plugin

[![Redmine 5.1 / 6.0 / 7.0+](https://img.shields.io/badge/Redmine-5.1%20%7C%206.0%20%7C%207.0%2B-blue.svg)](http://www.redmine.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Ruby 3.2 / 4.0+](https://img.shields.io/badge/Ruby-3.2%20%7C%204.0%2B-red.svg)](https://www.ruby-lang.org)

![](screenshots/tiled-articles-201801.jpg "Screenshot of tiled view option.")

## Overview

This plugin adds professional knowledgebase functionality to the [Redmine](http://www.redmine.org/) project management application.

## Recent Changes

* Tiled visual indexes are now supported using thumbnails.
* Articles are better formatted to work with more themes.
* Tag logic is improved and critical tags can be defined easily.
* Email notifications are better formatted.
* Bug fixes.

## Warnings

This version of the plugin is adapted for Redmine 5.1 (Rails 6.1.7.6), Redmine 6.x, and Redmine 7.0+ and won't work on earlier Redmine versions.

## Introduction

[![Join the chat at https://gitter.im/alexbevi/redmine_knowledgebase](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/alexbevi/redmine_knowledgebase?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

<a href="http://www.packtpub.com/redmine-plugin-extension-and-development/book" target ="_blank">
<img align="right" src="http://www.alexbevi.com/images/8748OS_mockupcover_normal_0.jpg" alt="Redmine Plugin Extension and Development">
</a>

[Redmine](http://www.redmine.org) is just plain awesome, and has proven to provide 90% of the functionality I need. The one feature that was missing was a usable knowledgebase component. I've looked at some of the open source solutions available, but couldn't find anything that fit my needs exactly. Seeing as Redmine is so easily extended, I figured why not create it for this platform instead of starting yet another project from scratch :P

**SHAMELESS PLUG** This plugin is discussed in [Redmine Plugin Extension and Development](http://www.packtpub.com/redmine-plugin-extension-and-development/book), which is now available from Packt Publishing.

## Features

* **Article Versioning & Audit Trail**: Full revision tracking with side-by-side visual diffs and 1-click version rollback.
* **Email Notifications & Atom Feeds**: Automatic notification emails to watchers upon article creation, modification, or comments.
* **Hierarchical Categorization**: Unlimited nested categories with ordering and jump-to navigation.
* **Article Ratings & Comments**: Community ratings and feedback discussions per article.
* **File & Image Attachments**: Inline previews and document downloads.
* **Article Tagging & Filtering**: Flexible tag clouds and tag-based filtering.
* **Visual Indexes with Thumbnails**: Grid or tiled visual overview for article indexes.
* **Project-Based Permissions**: Granular roles and permissions controlling read, write, comment, rate, and category management.
* **Redmine Core Quick Search Integration**: Articles are indexed and searchable via Redmine's global top-right search box.
* **REST API Endpoints**: Full programmatic access (`.json` and `.xml`) for articles and categories.
* **Global Top-Menu Overview**: Optional top-level navigation tab displaying knowledgebases across all projects.
* **PDF Export**: Generate article PDF documents with formatted tables, attachments, and dynamic naming.

## Installation

To install the knowledgebase, execute the following commands from the root of your redmine directory, assuming that your RAILS_ENV enviroment variable is set to "production":

    git clone git://github.com/southbridgeio/redmine_knowledgebase.git plugins/redmine_knowledgebase
    bundle install
    bundle exec rake redmine:plugins:migrate NAME=redmine_knowledgebase RAILS_ENV=production

More information on installing Redmine plugins can be found here: [http://www.redmine.org/wiki/redmine/Plugins](http://www.redmine.org/wiki/redmine/Plugins "Redmine Plugins")

After the plugin is installed and the db migration completed, you will
need to restart Redmine for the plugin to be available.

### Updating from v2.3.0 (Should work for all 2.x versions but has not been tested)

To update redmine from v2.3.0 to 3.0+ you will first want to delete ``redmine_knowledgebase`` from the the ``/plugins`` and ``/public/plugin_assets`` directories.

Once those two directories have been removed, run the following commands (as though you were performing a fresh installation):

    git clone git://github.com/southbridgeio/redmine_knowledgebase.git plugins/redmine_knowledgebase
    bundle install
    bundle exec rake redmine:plugins:migrate NAME=redmine_knowledgebase RAILS_ENV=production

Upon restarting Redmine, the Knowledgebase entry will no longer appear as a [:top_menu](http://www.redmine.org/projects/redmine/wiki/Plugin_Tutorial#Extending-menus) entry.

The knowledgebase is now project-specific, and therefore must be included in at least one project to work properly. If you wish to use it like v2.x, you can make a [public project](http://www.redmine.org/projects/redmine/wiki/RedmineProjectSettings#General-settings) that will only be used to store knowledgebase articles.

You will need to go into your database now and change the ``kb_articles`` and ``kb_categories`` ``project_id`` to the project id of the knowledgebase project you just created.

You can find the id in the projects table.

To generate the full project list from the command line, you can run the following from the root of your Redmine installation:

```ruby
rails runner "Project.all.map { |p| puts \"#{p.id}\t#{p.name}\" }"
```

This will produce a list similar to:

    3    Plugin Development
    4    KB 2.x
    5    Global

If you want to move all existing categories to the above "Global" project, you could do this via:

```ruby
rails runner "KbCategory.all.each { |c| c.project_id = 5; c.save }"
```

And to move all articles to this project:

```ruby
rails runner "KbArticle.all.each { |a| a.project_id = 5; a.save }"
```

### Upgrading an existing installation

1.  Open a command line to the root of your Redmine directory
2.  Update your Git copy:

    git pull

3.  Update the database:

    bundle exec rake redmine:plugins:migrate NAME=redmine_knowledgebase RAILS_ENV=production

4.  Restart Redmine

## Usage

### Permissions

Ensure that appropriate permissions have been established:

* **Administration** -> **Roles and permissions** -> **Permissions report**
* Under the **Knowledgebase** heading, assign permissions to roles

### Project Module

To enable the Knowledgebase for a project:

* Go to **Project** -> **Settings** -> **Modules**
* Check the box next to **Knowledgebase** and click **Save**

### Creating a Category

Categories can be created at the project or global level, depending on the permissions of the current user.

* Click on the **Knowledgebase** navigation tab.
* In the right hand sidebar, click on **New Category**
* Enter a title for the category, and a description.
* Click on **Create**

### Creating an Article

Articles are created at the category level.

* Open the Category that the article will belong to.
* Click on **New Article** in the right hand sidebar.

Fill in the following fields:

* **Title** - give the article a relevant title

* **Summary** - a short summary of what the article is about. This shows under
  the article on the category or sub-category main page.

* **Content** - the content of the article. The Content section uses the
  Redmine Wiki formatting syntax, so anything that is possible in the
  Redmine Wiki is possible here.

* **Tags** - add tags to the article Separate tags or tag groups with commas. Global tag search is currently not implemented, but is in development. Tag search is currently only available at the Article level.

* **Change Comments** - This field enables you to record the changes made to the article each time you edit it. This comment, along with the date, time, and author/updater, will show in the article history table at the top of each article.

* **Files** - attach any files or images to the article, along with an optional description. Note that the maximum size of the files or images that can be uploaded is 5MB.

Click on **Create** to add the article. Click on **Preview** to see how the article content will look and make any necessary changes before creating the article.

#### Managing Articles

Once you click on **Create** to add the article, the article is displayed. This page shows the title, summary and content of the article, the creator (Added by username), how long ago the article was created, and how many times it has been viewed.

You can also Edit or Delete the article, as well as rate the article. Clicking on any of the tags in the Tags section will search for any other articles with the same tags.

You can also comment on an article by clicking on Add a comment.

When editing the article, you will once again be able to enter a change comment as to what changed with this version of the article. This is useful to others who may be watching the article, and will allow them to get a brief idea of what change you made. They will also be able to see previous versions of the article if you allow them to, view highlighted differences between them, and revert to previous versions, if they have permission.

If you **Watch** the article, you will receive email notifications if the article is updated, deleted, or a comment is added. You can also watch an entire category, to be notified if any document in that category is created, edited, deleted, or commented on. You can also subscribe to atom feeds on article categories.

#### Using Wiki Macros

You can easily create links to articles and categories from issues or Wiki pages using the macros.

4 macros are available so far:

* `{{kb(<article_id>)}}` will render a link to the "kb#<article_id>" format. (It may change according to your locale).
* `{{article_id(<article_id>)}}`, identical to the kb macro, will render a link to the "kb#<article_id>" format.
* `{{article(<article_id>)}}` will render a link to the "kb#<article_id>: <article_title>" format.
* `{{category(<category_id>)}}` will render a link to the "<category_title>" format, only renders the title of the category.

### Knowledgebase Home Page

Now that categories and articles have been created, the home page of the Knowledgebase will show lists of *Recently Updated Articles*, *Most Popular Articles*, and *Top Rated Articles*. You can adjust permissions to enable users to view these lists, or change how many documents are displayed in these lists. You can use this page to help navigate the Knowledgebase, as well as using the *Jump to Category* drop down menu or the *Browse by Category* menu on the right of the screen. You can reach this page from anywhere inside the Knowledgebase by clicking on the Home link.

### About

* Released under the MIT license.  See LICENSE file.
* Copyright (c) 2010-2016 Alex Bevilacqua, original author.
* Modifications (c) 2016-2018 Rob Spearman.
* Redmine 5 adaptation (c) 2018 Southbridge
* Upgraded & modernized by Arean Narrayan (https://github.com/Arean82)

This plugin would not be possible without the many contributions from the community. See [AUTHORS](https://github.com/alexbevi/redmine_knowledgebase/blob/master/AUTHORS) for the full list.
