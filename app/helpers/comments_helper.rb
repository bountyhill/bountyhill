module CommentsHelper

  def comments_list_box_buttons
    box_buttons [
      add_comment_button
    ]
  end
  
  def comment_buttons(comment, options={})
    ul :class => "interactions" do
      [
        delete_comment_button(comment),
        reply_comment_button(comment, options)
      ].compact.map{|button| li(button)}.join.html_safe
    end
  end
  
  def delete_comment_button(comment)
    return unless comment.writable? && comment.owner == current_user

    link_to(awesome_icon(:icon_trash) + I18n.t('button.delete'),
      comment_path(comment), :method => :delete, :remote => true)
  end
  
  def reply_comment_button(comment, options={})
    return unless Opinio.accept_replies && !options[:reply]
      
    link_to(awesome_icon(:icon_share_alt) + I18n.t('button.reply'),
      reply_comment_path(comment), :remote => true)
  end

  def add_comment_button
    return unless current_user

    link_to awesome_icon(:icon_comment),
      "#new_comment",
      :title => t("button.comment"), :rel => "nofollow"
  end
  
  def comment_title(commentable)
    expect! commentable => [Quest, Offer]
    h3 :class => "title" do
      [
        div(I18n.t("comment.list.title", :count => commentable.comments.count), :class => "pull-left"),
        div((comments_list_box_buttons), :class => "pull-right")
      ].compact.join.html_safe
    end
  end
  
  def comments_box(commentable)
    expect! commentable => [Quest, Offer]
    
    content = div :class => "content" do
      partial "shared/comments", :commentable => commentable
    end

    div :class => "comments box row-fluid" do
      comment_title(commentable) + content
    end
  end
end