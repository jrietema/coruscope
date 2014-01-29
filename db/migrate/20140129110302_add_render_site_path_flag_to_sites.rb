class AddRenderSitePathFlagToSites < ActiveRecord::Migration
  def change
    change_table :cms_sites do |t|
      t.boolean :render_site_path, :default => true
    end
  end
end
