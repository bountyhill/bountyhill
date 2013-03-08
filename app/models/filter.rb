module Filter
  class Item < Struct.new(:type, :name, :count, :url)
    def active?(selected_name)
      name == selected_name ||
      (selected_name.nil? && self.all?)
    end

    def all?
      name == 'all'
    end
  end
  
  module Builder
    def filter_item(attribute, value, count)
      Filter::Item.new(
        attribute,                            # type  
        value,                                # name  
        count,                                # count 
        url_for_filter(attribute, value))     # url   
    end
    
    def filter_for_all(scope, attribute)
      filter_item(attribute, "all", scope.count)
    end                                                       

    def url_for_filter(attribute, group)
      url_params = params.dup
      url_params.delete attribute

      url_params[attribute] = group if group != "all"

      url_for url_params
    end

    def filters_for(scope, attribute)
      expect! attribute => Symbol

      filters = scope.count(:group => attribute, :distinct => true).map do |group, count|
        filter_item(attribute, group, count)
      end.sort_by do |filter| 
        I18n.t(filter.name, :scope => "#{scope.klass.name.downcase}.#{attribute.to_s.pluralize}") 
      end

      filters.unshift filter_for_all(scope, attribute)
      filters
    end  
  end
end
