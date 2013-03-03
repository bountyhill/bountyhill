class Filter
  attr_reader :type, :name, :count, :url

  def self.filters_for(klass, attribute, scope=nil, conditions={})
    expect! attribute => Symbol
    
    scope ||= klass
    
    category_url  = "/#{klass.name.downcase.pluralize}"
    category_url += "?owner_id=#{conditions[:owner_id]}" if conditions[:owner_id]
    all = Filter.new(
      :type         => attribute,
      :name         => "all",
      :count        => scope.count(:conditions => conditions),
      :url          => category_url)
    
    scope.count(:conditions => conditions, :group => attribute, :distinct => true).inject([all]) do |filters, group|
      category_url  = "/#{klass.name.downcase.pluralize}/#{attribute}/#{group.first}"
      category_url += "?owner_id=#{conditions[:owner_id]}" if conditions[:owner_id]
      
      filters << Filter.new(
        :type   => attribute,
        :name   => group.first,
        :count  => group.last,
        :url    => category_url)
      filters
    end
  end
  
  def initialize(options = {})
    @type, @name, @count, @url =
      options.values_at(:type, :name, :count, :url)
  end
  
  def active?(selected_name)
    name == selected_name ||
    (selected_name.nil? && self.all?)
  end
  
  def all?
    name == 'all'
  end
  
end