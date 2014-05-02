xml.instruct! :xml, :version => '1.0', :encoding => 'UTF-8'

xml.urlset  :xmlns => 'http://www.sitemaps.org/schemas/sitemap/0.9',
            'xmlns:xhtml' => "http://www.w3.org/1999/xhtml" do
  @cms_site.pages.published.each do |site_page|
    ([site_page] + site_page.mirrors).each do |page|
      next unless page.is_published?
      xml.url do
        xml.loc ['http://', page.site.hostname, page_path(page)].join
        tree_priority = [1 - (0.1 * ( ( [page.full_path.split("/").count, 1].max - 1 ) ) ), 0.1].max
        revs = page.revisions.size
        priority_modifier = case page.revisions.size
                          when 0
                            -0.2
                          when 1,2,3
                            -0.1
                          when 3,4,5,6,7,8
                            0
                          else
                            0.1
                        end
        priority = (tree_priority + priority_modifier).round(1)
        priority = 1.0 if priority > 1.0
        xml.priority priority
        xml.lastmod page.updated_at.strftime('%Y-%m-%d')

        # render xhtml alternate links to mirror pages
        page.mirrors.each do |mirror_page|
          next unless mirror_page.is_published?
          xml.tag!('xhtml:link', {
              :rel => 'alternate',
              :hreflang => mirror_page.site.locale.to_s,
              :href => ['http://', mirror_page.site.hostname, page_path(mirror_page)].join
          })
        end
      end
    end
  end
end
