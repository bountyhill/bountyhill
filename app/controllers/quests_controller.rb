class Money
  def to_full_string
    "#{self} #{currency_as_string}"
  end
end

class QuestsController < ApplicationController
  include Transloadit::Rails::ParamsDecoder
  
  # GET /quests
  # GET /quests.json
  def index
    @quests = Quest.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @quests }
    end
  end

  # GET /quests/1
  # GET /quests/1.json
  def show
    @quest = Quest.find(params[:id])
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @quest }
    end
  end

  # GET /quests/new
  # GET /quests/new.json
  def new
    @quest = Quest.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @quest }
    end
  end

  # GET /quests/1/edit
  def edit
    @quest = Quest.find(params[:id])
  end


  #
  # returns a hash describing a remote image resource:
  #
  #  
  def image_param
    return unless transloadit = params["transloadit"]
    return unless results = transloadit["results"]
    
    results.inject({}) do |hash, (key, values)|
      value = values.first
      url, mime, size, meta = *value.values_at(:url, :mime, :size, :meta)
      width, height = meta.values_at(:width, :height)
      
      hash.update key.to_s.gsub(/^:/, "").to_sym => {
        url: url,
        mime: mime,
        size: size,
        width: width,
        height: height
      } 
    end
  end
  
  # POST /quests
  # POST /quests.json
  def create
    params[:quest][:image] = image_param
    @quest = Quest.new(params[:quest])

    respond_to do |format|
      if @quest.valid?
        @quest.save!
        
        format.html { redirect_to @quest, notice: 'Quest was successfully created.' }
        format.json { render json: @quest, status: :created, location: @quest }
      else
        format.html { render action: "new" }
        format.json { render json: @quest.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /quests/1
  # PUT /quests/1.json
  def update
    @quest = Quest.find(params[:id])

    respond_to do |format|
      if @quest.valid?
        @quest.update_attributes(params[:quest])
        
        format.html { redirect_to quests_path, notice: 'Quest was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @quest.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /quests/1
  # DELETE /quests/1.json
  def destroy
    @quest = Quest.find(params[:id])
    @quest.destroy

    respond_to do |format|
      format.html { redirect_to quests_url }
      format.json { head :no_content }
    end
  end
end
