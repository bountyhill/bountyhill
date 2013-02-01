module CommentsHelper

  def comments_list_box_buttons
    box_buttons [
      add_comment_button
    ]
  end
  
  def comment_buttons(comment, options={})
    ul :class => "interactions" do
      [
        reply_comment_button(comment),
        delete_comment_button(comment, options)
      ].compact.map{|button| li(button)}.join.html_safe
    end
  end
  
  def reply_comment_button(comment)
    link_to(t('opinio.actions.delete'), comment_path(comment), :method => :delete, :remote => true) if comment.writable?
  end
  
  def delete_comment_button(comment, options={})
    link_to(t('opinio.actions.reply'), reply_comment_path(comment), :remote => true) if Opinio.accept_replies && !options[:reply]
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