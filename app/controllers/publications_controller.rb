class PublicationsController < ApplicationController

  make_resourceful do
    build :index, :show, :new, :edit, :create, :update
    
    publish :yaml, :xml, :json, :attributes => [
      :id, :name, :url, :issn_isbn, :publisher_id, {
        :publisher => [:id, :name]
        }, {
        :authority_for => [:id, :name]
        }
      ]

    before :index do
      @a_to_z = Publication.letters.collect { |d| d.letter }
      
      if params[:q]
        query = params[:q]
        @current_objects = current_objects
      else
        @page = params[:page] || @a_to_z[0]
        @current_objects = Publication.find(
          :all,
          :conditions => ["publications.id = authority_id and name like ?", "#{@page}%"],
          :order => "name"
        )
      end
      
      @title = "Publications"
    end

    before :show do

      @authority_for = Publication.find(
        :all,
        :conditions => ["authority_id = ?", current_object.id],
        :order => "name"
      )
      
      @query = @current_object.solr_id
      @sort = params[:sort] || "year desc"
      @fetch = @query + ";" + @sort
      @filter = params[:fq] || ""
      @filter = @filter.split("+>+").each{|f| f.strip!}
      @q,@docs,@facets = Index.fetch(@fetch, @filter, @sort)

      @title = @current_object.name
    end

    before :new, :edit do
      @publishers = Publisher.find(:all, :conditions => ["id = authority_id"], :order => "name")
      @publications = Publication.find(:all, :conditions => ["id = authority_id"], :order => "name")
    end
  end

  def authorities
    @a_to_z = Publication.letters.collect { |d| d.letter }
    
    if params[:q]
      query = params[:q]
      @current_objects = current_objects
    else
      @page = params[:page] || @a_to_z[0]
      @current_objects = Publication.find(
        :all, 
        :conditions => ["id = authority_id and name like ?", "#{@page}%"], 
        :order => "name"
      )
    end    
  end
  
  def update_multiple
    pub_ids = params[:pub_ids]
    auth_id = params[:auth_id]
    page = params[:page]
    
    update = Publication.update_multiple(pub_ids, auth_id)

    respond_to do |wants|
      wants.html do
        redirect_to authorities_publications_path(:page => page)
      end
    end
  end

  private
  def current_objects
    #TODO: If params[:q], handle multiple request types:
    # * ISSN
    # * ISBN
    # * Name (abbreviations)
    # * Publisher
    @current_objects ||= current_model.find_all_by_issn_isbn(params[:q])
  end
end
