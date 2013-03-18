module CommentsHelper

  def comments_list_box_buttons
    button_group [
      add_comment_button
    ]
  end
  
  def comment_buttons(comment, options={})
    button_group [
      delete_comment_button(comment),
      reply_comment_button(comment, options)
    ]
  end
  
  def delete_comment_button(comment)
    return unless comment.writable? && current_user.owns?(comment)

    link_to(awesome_icon(:trash) + I18n.t('button.delete'),
      comment_path(comment), :method => :delete, :remote => true)
  end
  
  def reply_comment_button(comment, options={})
    return unless Opinio.accept_replies && !options[:reply]
      
    link_to(awesome_icon(:share_alt) + I18n.t('button.reply'),
      reply_comment_path(comment), :remote => true)
  end

  def add_comment_button
    return unless current_user

    awesome_button(:comment, "#new_comment") { I18n.t("button.comment") }
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

    div :class => "comments box row-fluid with-opener" do
      comment_title(commentable) + content
    end
  end
end