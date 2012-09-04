class ActiveModel::Errors
  def inspect
    "<#{self.class}:#{"%x" % object_id} #{full_messages.join(", ")}>"
  end
end
