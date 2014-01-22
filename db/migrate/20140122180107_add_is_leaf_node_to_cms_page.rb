class AddIsLeafNodeToCmsPage < ActiveRecord::Migration

  def change
    change_table :cms_pages do |t|
      t.boolean :is_leaf_node, :default => false
    end
  end

end
