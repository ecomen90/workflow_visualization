class WorkflowVisualizationsController < ApplicationController
  before_action :require_login
  before_action :require_admin, only: [:index]

  layout 'admin'

  # ---------------------------------------------------------
  # GET /workflow_visualization
  # 기본값 → tracker=all / role=all
  # ---------------------------------------------------------
  def index
    @trackers = Tracker.sorted
    @roles    = Role.givable.sorted

    # ✅ 기본값 처리
    @selected_tracker_id = params[:tracker_id].presence || 'all'
    @selected_role_id    = params[:role_id].presence || 'all'

    tracker_ids =
      if @selected_tracker_id == 'all'
        @trackers.pluck(:id)
      else
        [@selected_tracker_id.to_i]
      end

    role_ids =
      if @selected_role_id == 'all'
        @roles.pluck(:id)
      else
        [@selected_role_id.to_i]
      end

    @graph_data = build_graph_data(tracker_ids, role_ids)
  end


  # ---------------------------------------------------------
  # AJAX JSON
  # ---------------------------------------------------------
  def graph_data
    tracker_ids = parse_ids(params[:tracker_id], Tracker)
    role_ids    = parse_ids(params[:role_id], Role)

    render json: build_graph_data(tracker_ids, role_ids)
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  end


  private

  # ---------------------------------------------------------
  # id or all 처리 유틸
  # ---------------------------------------------------------
  def parse_ids(param, model)
    return model.pluck(:id) if param.blank? || param == 'all'
    [param.to_i]
  end


  # ---------------------------------------------------------
  # ⭐ 전체/단일 모두 지원하는 그래프 빌더
  # ---------------------------------------------------------
  def build_graph_data(tracker_ids, role_ids)
    transitions = WorkflowTransition
                    .where(tracker_id: tracker_ids, role_id: role_ids)
                    .includes(:old_status, :new_status)

    status_ids = (transitions.map(&:old_status_id) +
                  transitions.map(&:new_status_id)).uniq.compact

    statuses = IssueStatus.where(id: status_ids).index_by(&:id)

    nodes = statuses.values.map do |s|
      {
        id: s.id,
        name: s.name,
        is_closed: s.is_closed,
        color: s.is_closed ? '#e8f5e9' : '#e3f2fd'
      }
    end

    edges = transitions.map do |t|
      next if t.old_status_id == 0

      {
        from: t.old_status_id,
        to:   t.new_status_id,
        author_only: t.author,
        assignee_only: t.assignee,
        from_name: statuses[t.old_status_id]&.name || 'New',
        to_name:   statuses[t.new_status_id]&.name || 'Unknown'
      }
    end.compact

    {
      tracker_ids: tracker_ids,
      role_ids: role_ids,
      nodes: nodes,
      edges: edges
    }
  end
end
