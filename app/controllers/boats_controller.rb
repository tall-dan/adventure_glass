class BoatsController < ApplicationController
  before_action :current_shopping_cart
  # TODO: git rid of this class
  def build
    @boat_options = %w[Paddleboat Canoe Gondola Riverboat Excursion\ Boat]
    @style_options = { canoe: %w[canoe_option1 canoe_option2],
                       paddleboat: ['Mark Twain', 'Handicapped Sea Venture', '4 peddler',
                                    'Pirate Ship', 'African Queen', 'Pontoon', 'Dixie'],
                       gondola: %w[gondola_option1 gondola_option2],
                       excursion_boat: %w[excursion_boat_option1 excursion_boat_option2],
                       riverboat: %w[riverboat_option1 riverboat_option2]
    }
    @extras = %w[option0 option1 option2 option3 option4 option5 option6 option7 option8 option9 option10]
  end

  def index
    @boats = Boat.where.not(type: %w[waterfowl paddleboats])
    @products_for_slider = Boat.where(type: 'paddleboat')
  end

  def paddleboat_index
    @products_for_slider = Boat.where(type: 'waterfowl')
    @paddleboats = Boat.where(type: 'paddleboat')
    render 'boats/paddleboats/index'
  end

  def barge_index
    @barges = Product.where(type: 'barge')
    render 'boats/barges/index'
  end
end
