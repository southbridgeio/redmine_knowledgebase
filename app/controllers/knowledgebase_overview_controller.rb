class KnowledgebaseOverviewController < ApplicationController
  def index
    accessible_projects = Project.allowed_to(User.current, :view_kb_articles)
    
    if accessible_projects.empty?
      render_403
      return false
    end

    # If only 1 project has knowledgebase, directly open it
    if accessible_projects.count == 1
      redirect_to project_articles_path(accessible_projects.first)
      return
    end

    @projects = accessible_projects
    @total_articles = KbArticle.where(project_id: accessible_projects.map(&:id)).count
    @total_categories = KbCategory.where(project_id: accessible_projects.map(&:id)).count
    @recent_articles = KbArticle.where(project_id: accessible_projects.map(&:id))
                                .order('created_at DESC')
                                .limit(10)
  end
end
