require File.dirname(__FILE__) + '/../test_helper'

class CategoriesControllerTest < ActionController::TestCase
  fixtures :projects, :roles, :users
  plugin_fixtures :kb_categories, :enabled_modules

  def setup
    User.current = User.find(1)
    @request.session[:user_id] = 1
    @project = Project.find(1)
    Role.find(1).add_permission! :view_kb_articles
    Role.find(1).add_permission! :create_article_categories
    Role.find(1).add_permission! :manage_article_categories
  end

  def test_index_json_api
    get :index, params: { project_id: @project.id, format: :json }
    assert_response :success
    assert_equal 'application/json', @response.media_type
    json = ActiveSupport::JSON.decode(@response.body)
    assert json.key?('categories')
    assert json['categories'].is_a?(Array)
  end

  def test_show_json_api
    category = KbCategory.first || KbCategory.create!(title: 'API Test Category', description: 'Testing Category API', project_id: @project.id)
    get :show, params: { project_id: @project.id, id: category.id, format: :json }
    assert_response :success
    assert_equal 'application/json', @response.media_type
    json = ActiveSupport::JSON.decode(@response.body)
    assert json.key?('category')
    assert_equal category.id, json['category']['id']
  end
end
