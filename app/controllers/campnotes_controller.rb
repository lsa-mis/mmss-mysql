# frozen_string_literal: true

class CampnotesController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_campnote, only: [:show, :edit, :update, :destroy]

  # GET /campnotes
  # GET /campnotes.json
  def index
    @campnotes = Campnote.all
  end

  # GET /campnotes/1
  # GET /campnotes/1.json
  def show
  end

  # GET /campnotes/new
  def new
    @campnote = Campnote.new
  end

  # GET /campnotes/1/edit
  def edit
  end

  # POST /campnotes
  # POST /campnotes.json
  def create
    @campnote = Campnote.new(campnote_params)

    respond_to do |format|
      if @campnote.save
        format.html { redirect_to @campnote, notice: 'Campnote was successfully created.' }
        format.json { render :show, status: :created, location: @campnote }
      else
        format.html { render :new }
        format.json { render json: @campnote.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /campnotes/1
  # PATCH/PUT /campnotes/1.json
  def update
    respond_to do |format|
      if @campnote.update(campnote_params)
        format.html { redirect_to @campnote, notice: 'Campnote was successfully updated.' }
        format.json { render :show, status: :ok, location: @campnote }
      else
        format.html { render :edit }
        format.json { render json: @campnote.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /campnotes/1
  # DELETE /campnotes/1.json
  def destroy
    @campnote.destroy
    respond_to do |format|
      format.html { redirect_to campnotes_url, notice: 'Campnote was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_campnote
      @campnote = Campnote.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def campnote_params
      params.require(:campnote).permit(:note, :opendate, :closedate, :notetype)
    end
end
