module OffersHelper
  # Actions to show on top of /offers/show
  def offer_actions(offer)
    return [] unless @offer.quest.active?

    if current_user == @offer.quest.owner
      [:accept, :decline]
    elsif current_user == @offer.owner
      [:withdraw]
    end
  end
end
