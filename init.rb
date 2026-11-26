unless Rails.try(:autoloaders).try(:zeitwerk_enabled?)
  require 'redmine_knowledgebase'
end

ActiveRecord::Base.send :include, RedmineKnowledgebase::Acts::Rated
ActiveRecord::Base.send :include, RedmineKnowledgebase::Acts::Versioned
ActiveRecord::Base.send :include, RedmineKnowledgebase::Acts::Viewed
ActiveRecord::Base.send :include, RedmineKnowledgebase::Acts::Taggable

Redmine::Plugin.register :redmine_knowledgebase do
  name        'Knowledgebase (Modernized Edition)'
  author      'Alex Bevilacqua, Southbridge; Upgraded & Modernized by Arean Narrayan'
  author_url  'https://github.com/Arean82'
  description 'Professional knowledgebase functionality for Redmine with categories, versioning, rating, tagging, attachments, and full Redmine 5.1+, 6.x, and 7.0+ compatibility.'
  url         'https://github.com/Arean82/redmine_knowledgebase'
  version     '5.2.0'

  requires_redmine :version_or_higher => '5.1.0'

  # Do not set any default boolean settings to true or will override user false setting!
  settings :default => {
    :summary_limit => 25,
    :articles_per_list_page => 100,
    :disable_article_summaries => false
  }, :partial => 'redmine_knowledgebase/knowledgebase_settings'

  project_module :knowledgebase do
    permission :view_kb_articles, {
      :articles      => [:index, :show, :tagged, :authored],
      :categories    => [:index, :show]
    }
    permission :comment_and_rate_articles, {
      :articles      => [:index, :show, :tagged, :rate, :comment, :add_comment],
      :categories    => [:index, :show]
    }
    permission :create_articles, {
      :articles      => [:index, :show, :tagged, :new, :create, :add_attachment, :preview],
      :categories    => [:index, :show]
    }
    permission :edit_articles, {
      :articles      => [:index, :show, :tagged, :edit, :update, :add_attachment, :preview],
      :categories    => [:index, :show]
    }
    permission :manage_articles, {
      :articles      => [:index, :show, :new, :create, :edit, :update, :destroy, :add_attachment,
                         :preview, :comment, :add_comment, :destroy_comment, :tagged],
      :categories    => [:index, :show]
    }
    permission :manage_own_articles, {
      :articles      => [:index, :show, :edit, :update, :destroy, :add_attachment, :preview, :tagged],
      :categories    => [:index, :show]
    }
    permission :manage_articles_comments, {
      :articles      => [:index, :show, :comment, :add_comment, :destroy_comment],
      :categories    => [:index, :show]
    }
    permission :create_article_categories, {
      :articles      => :index,
      :categories    => [:index, :show, :new, :create]
    }
    permission :manage_article_categories, {
      :articles      => :index,
      :categories    => [:index, :show, :new, :create, :edit, :update, :destroy]
    }
    permission :watch_articles, {
      :watchers		=> [:new, :destroy]
    }
    permission :watch_categories, {
      :watchers => [:new, :destroy]
    }
    permission :view_recent_articles, {
      :articles => :index
    }
    permission :view_most_popular_articles, {
      :articles => :index
    }
    permission :view_top_rated_articles, {
      :articles => :index
    }
    permission :view_article_history, {
      :articles => [:diff, :version]
    }
    permission :manage_article_history, {
      :articles => [:diff, :version, :revert]
    }
  end

  menu :project_menu, :articles, { :controller => 'articles', :action => 'index' }, :caption => :knowledgebase_title, :after => :activity, :param => :project_id

  menu :top_menu, :knowledgebase, { :controller => 'knowledgebase_overview', :action => 'index' },
       :caption => :knowledgebase_title,
       :after => :projects,
       :if => Proc.new {
         settings = Setting.plugin_redmine_knowledgebase
         enabled = settings.is_a?(Hash) ? (settings[:show_in_top_menu].to_s != '0' && settings['show_in_top_menu'].to_s != '0') : true
         enabled && User.current.logged? && Project.allowed_to(User.current, :view_kb_articles).any?
       }

end
