class AddIsPinnedToKbArticles < ActiveRecord::Migration[6.0]
  def change
    add_column :kb_articles, :is_pinned, :boolean, default: false, null: false unless column_exists?(:kb_articles, :is_pinned)
    add_index :kb_articles, :is_pinned unless index_exists?(:kb_articles, :is_pinned)
  end
end
