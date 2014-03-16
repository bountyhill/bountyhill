# encoding: UTF-8

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

    link_to("#{awesome_icon(icon_for('interaction.delete'))} #{I18n.t('button.delete')}".html_safe,
      comment_path(comment), :method => :delete, :remote => true, :class => "btn btn-link btn-small" )
  end
  
  def reply_comment_button(comment, options={})
    return unless Opinio.accept_replies && !options[:reply]
      
    link_to("#{awesome_icon(icon_for('interaction.reply'))} #{I18n.t('button.reply')}".html_safe,
      reply_comment_path(comment), :remote => true, :class => "btn btn-link btn-small" )
  end

  def add_comment_button
    return unless current_user

    awesome_button(icon_for('interaction.comment'), "#", :class => "new-comment") { I18n.t("button.comment") }
  end
  
  def comment_title(commentable)
    expect! commentable => [Quest, Offer]
    div :class => "header" do
      [
        div(I18n.t("comment.list.title", :count => commentable.comments.count), :class => "title"),
        div((comments_list_box_buttons), :class => "interactions")
      ].compact.join.html_safe
    end
  end
  
  def comments_box(commentable)
    expect! commentable => [Quest, Offer]
    
    content = div :class => "content" do
      comments_for commentable
    end

    div :class => "comments box row-fluid with-opener" do
      comment_title(commentable) + content
    end
  end
end