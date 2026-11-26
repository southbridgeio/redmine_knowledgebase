require File.dirname(__FILE__) + '/../test_helper'

class ArticlesControllerTest < ActionController::TestCase
  fixtures :projects, :roles, :users
  plugin_fixtures :kb_articles, :enabled_modules

  def setup
    User.current = User.find(1)
    @request.session[:user_id] = 1
    @project = Project.find(1)
    Role.find(1).add_permission! :view_kb_articles
    Role.find(1).add_permission! :create_articles
    Role.find(1).add_permission! :edit_articles
    Role.find(1).add_permission! :manage_articles
  end

  def test_index_html
    get :index, params: { project_id: @project.id }
    assert_response :success
    assert_template 'index'
  end

  def test_index_json_api
    get :index, params: { project_id: @project.id, format: :json }
    assert_response :success
    assert_equal 'application/json', @response.media_type
    json = ActiveSupport::JSON.decode(@response.body)
    assert json.key?('articles')
    assert json['articles'].is_a?(Array)
  end

  def test_index_xml_api
    get :index, params: { project_id: @project.id, format: :xml }
    assert_response :success
    assert_equal 'application/xml', @response.media_type
  end

  def test_show_json_api
    article = KbArticle.first || KbArticle.create!(title: 'API Test Article', content: 'Testing JSON API', project_id: @project.id, category_id: 1, author_id: 1)
    get :show, params: { project_id: @project.id, id: article.id, format: :json }
    assert_response :success
    assert_equal 'application/json', @response.media_type
    json = ActiveSupport::JSON.decode(@response.body)
    assert json.key?('article')
    assert_equal article.id, json['article']['id']
  end

  def test_show_xml_api
    article = KbArticle.first || KbArticle.create!(title: 'API Test XML', content: 'Testing XML API', project_id: @project.id, category_id: 1, author_id: 1)
    get :show, params: { project_id: @project.id, id: article.id, format: :xml }
    assert_response :success
    assert_equal 'application/xml', @response.media_type
  end
end
