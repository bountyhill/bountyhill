# encoding: UTF-8

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
    
    def url_for_filter(attribute, group)
      url_params = params.dup
      url_params[attribute] = (group == "all") ? nil : group

      url_for url_params
    end

    def filters_for(scope, attribute)
      expect! attribute => Symbol

      filters = scope.count(:group => attribute, :distinct => true).map do |group, count|
        filter_item(attribute, group, count)
      end.sort_by do |filter|
        # this sorts by order in attribute's constant definition:
        "#{scope.klass.name}::#{attribute.to_s.pluralize.upcase}".constantize.index(filter.name).to_i
        
        # this sorts by alphabetic order in attribute's translation:
        # I18n.t(filter.name, :scope => "#{scope.klass.name.downcase}.#{attribute.to_s.pluralize}")
      end

      # filters.unshift filter_item(attribute, "all", filters.sum(&:count))

      # add 'all' filter unless there is nothing to filter
      unless filters.size.zero?
        filter_for_all = filter_item(attribute, "all", filters.sum(&:count))
        filters.unshift(filter_for_all)
      end

      filters
    end  
  end
end
