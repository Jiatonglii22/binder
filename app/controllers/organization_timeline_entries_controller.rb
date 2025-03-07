# frozen_string_literal: true

class OrganizationTimelineEntriesController < ApplicationController
  authorize_resource
  before_action :set_organization_timeline_entry, only: %i[update destroy end show]

  def index
    @organization = Organization.find(params[:organization_id]) if params[:organization_id].present?
    @entries = OrganizationTimelineEntry.downtime
    @entries = @entries.where({ organization: @organization }) if @organization.present?
  end

  def show
    @organization_timeline_entry = OrganizationTimelineEntry.find(params[:id])
  end

  def edit
    @organization_timeline_entry = OrganizationTimelineEntry.find(params[:id])
  end

  # POST /organizations_timeline_entries
  # POST /organizations_timeline_entries.json
  def create
    @organization_timeline_entry = OrganizationTimelineEntry.new(organization_timeline_entry_params)
    @organization_timeline_entry.started_at = DateTime.now
    @organization_timeline_entry.entry_type = case params[:commit]
                                              when 'Structural' then 'structural'
                                              when 'Electrical' then 'electrical'
                                              else 'downtime'
                                              end

    authorize! :create, @organization_timeline_entry

    if @organization_timeline_entry.already_in_queue?
      redirect_to :back, alert: "You're already on the queue!"
      return
    end

    if @organization_timeline_entry.valid?
      @organization_timeline_entry.save
      respond_with(@organization_timeline_entry, location: params[:url])
    else
      redirect_to :back, alert: 'Missing Organization Name!'
    end
  end

  # PUT /organizations_timeline_entry/1
  # PUT /organizations_timeline_entry/1.json
  def update
    @organization_timeline_entry.update(organization_timeline_entry_params)
    redirect_to organization_downtime_index_path(@organization_timeline_entry.organization)
  end

  # PUT /organizations_timeline_entry/1/end
  # PUT /organizations_timeline_entry/1/end.json
  def end
    authorize! :end, @organization_timeline_entry

    @organization_timeline_entry.ended_at = DateTime.now
    @organization_timeline_entry.save
    respond_with(@organization_timeline_entry, location: params[:url])
  end

  # DELETE /organizations_timeline_entry/1
  # DELETE /organizations_timeline_entry/1.json
  def destroy
    @organization_timeline_entry = OrganizationTimelineEntry.find(params[:id])
    @organization_timeline_entry.destroy
    flash[:notice] = 'Successfully removed entry from downtime tracker'
    redirect_to organization_downtime_index_path(@organization_timeline_entry.organization)
  end

  def electrical
    @organization_timeline_entries = OrganizationTimelineEntry.electrical.current
  end

  def structural
    @organization_timeline_entries = OrganizationTimelineEntry.structural.current
  end

  private

  def set_organization_timeline_entry
    @organization_timeline_entry = OrganizationTimelineEntry.find(params[:id])
  end

  def organization_timeline_entry_params
    params.require(:organization_timeline_entry).permit(:organization_id, :ended_at, :started_at,
                                                        :organization_timeline_entry_type_id, :description)
  end
end
