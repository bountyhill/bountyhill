# encoding: UTF-8

class CGI
  def self.build_url(base_url, params = {})
    params = params.without_blank_values
    return base_url if params.blank?

    base_url + 
      (base_url.index("?") ? "&" : "?") +
      params.map { |k,value| "#{k}=#{CGI.escape(value.to_s)}"}.join("&")
  end
end

class Hash
  def without_blank_values
    inject({}) do |hash, (k,v)|
      hash[k] = v unless v.blank?
      hash
    end
  end
end

