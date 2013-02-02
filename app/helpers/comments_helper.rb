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
    return unless comment.writable?

    link_to(content_tag(:i, nil, :class => " icon-trash") + I18n.t('opinio.actions.delete'),
      comment_path(comment), :method => :delete, :remote => true)
  end
  
  def reply_comment_button(comment, options={})
    return unless Opinio.accept_replies && !options[:reply]
      
    link_to(content_tag(:i, nil, :class => " icon-share-alt") + I18n.t('opinio.actions.reply'),
      reply_comment_path(comment), :remote => true)
  end

  def add_comment_button
    return unless current_user

    link_to content_tag(:i, nil, :class => "icon-comment"),
      "#new_comment",
      :title => t("button.comment"), :rel => "nofollow"
  end
  
  def comments_box(commentable)
    expect! commentable => [Quest, Offer]
    
    title = h2 :class => "title" do
      [
        div(I18n.t("comment.list.title", :count => commentable.comments.count), :class => "pull-left"),
        div((comments_list_box_buttons), :class => "pull-right")
      ].compact.join.html_safe
    end
    
    content = div :class => "content" do
      partial "shared/comments", :commentable => commentable
    end

    div :class => "comments box row-fluid" do
      title + content
    end
  end
end